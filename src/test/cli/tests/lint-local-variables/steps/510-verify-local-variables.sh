#!/usr/bin/env bash
# @file: 510-verify-local-variables.sh
# @source-dir: src/test/cli/tests/lint-local-variables/steps
# @group: test
# @category: step
# @description: Verify local variables.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Lists lowercase variables that a function or bats test sets without declaring them local.
# @details:
#   A name counts as set when it is assigned at the start of a statement, is a for loop variable,
#   or is read with read. Uppercase names are globals and are left alone. Quoted text, here-documents,
#   comments and case labels such as source=*) are skipped. Declarations with local, declare, typeset
#   or readonly anywhere in the function count, also when they come after the assignment.
# @arg: $1 - the run folder.
# @stdout: NOTE with the counts, and a DETAIL line <file>:<line>: <function>: <name> for each finding.
# @exitcode: 0 if every name is declared, 2 otherwise (PodShift problem).
verify-local-variables() {
    local run_dir program files found count line
    run_dir="${1}"
    # shellcheck disable=SC2016
    program='
        function reset() { delete loc; n = 0 }
        function flush(   i, p) {
            for (i = 1; i <= n; i++) {
                split(A[i], p, SUBSEP)
                if (!(p[1] in loc)) print FILENAME ":" p[2] ": " fname ": " p[1]
            }
            reset()
        }
        function declnames(s,   k, arr, m, w) {
            sub(/^[ \t]*(local|declare|typeset|readonly)[ \t]+/, "", s)
            m = split(s, arr, /[ \t]+/)
            for (k = 1; k <= m; k++) {
                w = arr[k]
                if (w ~ /^-/) continue
                sub(/[=+].*/, "", w)
                if (w ~ /^[A-Za-z_][A-Za-z0-9_]*$/) loc[w] = 1; else break
            }
        }
        function add(name) { if (name ~ /^[a-z_][a-z0-9_]*$/) { n++; A[n] = name SUBSEP FNR } }
        FNR == 1 { if (infn) flush(); infn = 0; hd = "" }
        {
            line = $0
            if (hd != "") { t = line; sub(/^[ \t]+/, "", t); if (t == hd) hd = ""; next }
            if (match(line, /<<-?[ \t]*[\047"]?[A-Za-z_]+[\047"]?/)) {
                h = substr(line, RSTART, RLENGTH); gsub(/<<-?|[ \t\047"]/, "", h); hd = h
            }
            if (!infn && (line ~ /^[ \t]*(function[ \t]+)?[A-Za-z_][A-Za-z0-9_:.-]*[ \t]*\(\)[ \t]*\{?[ \t]*$/ || line ~ /^[ \t]*@test[ \t].*\{[ \t]*$/)) {
                infn = 1; match(line, /^[ \t]*/); ind = substr(line, 1, RLENGTH)
                fname = line; gsub(/^[ \t]+|[ \t]*\{?[ \t]*$/, "", fname); reset(); next
            }
            if (infn && line ~ ("^" ind "\\}[ \t]*$")) { flush(); infn = 0; next }
            if (!infn || line ~ /^[ \t]*#/) next
            if (line ~ /^[ \t]*(local|declare|typeset|readonly)[ \t]/) { declnames(line); next }
            s = line
            gsub(/\047[^\047]*\047/, "\047\047", s)
            gsub(/"([^"\\]|\\.)*"/, "\"\"", s)
            if (match(s, /^[ \t]*\(?[^ \t()]+\)/) && (s ~ /;;[ \t]*$/ || substr(s, RSTART, RLENGTH) ~ /[*|]/)) s = substr(s, RSTART + RLENGTH)
            while (match(s, /(^|[;&|][ \t]+|(then|do|else)[ \t]+|^[ \t]*)[A-Za-z_][A-Za-z0-9_]*(\[[^]]*\])?\+?=/)) {
                a = substr(s, RSTART, RLENGTH); s = substr(s, RSTART + RLENGTH)
                gsub(/^[;&| \t]*|^(then|do|else)[ \t]+|\[.*|\+?=$/, "", a); gsub(/^[ \t]+/, "", a)
                sub(/^(then|do|else)[ \t]+/, "", a)
                add(a)
            }
            if (match(s, /(^|[ \t;])for[ \t]+[A-Za-z_][A-Za-z0-9_]*[ \t]+in([ \t;]|$)/)) {
                a = substr(s, RSTART, RLENGTH); sub(/^[ \t;]*for[ \t]+/, "", a); sub(/[ \t]+in.*$/, "", a); add(a)
            }
            if (match(s, /(^|[ \t;&|(])read[ \t]+[^;&|<>]*/)) {
                r = substr(s, RSTART, RLENGTH); sub(/^.*read[ \t]+/, "", r)
                m = split(r, ww, /[ \t]+/)
                for (k = 1; k <= m; k++) {
                    if (ww[k] ~ /^-/) { if (ww[k] ~ /[dpatnuN]$/) k++; continue }
                    add(ww[k])
                }
            }
        }
        END { if (infn) flush() }
    '
    files="$(find src/server src/deployment src/test -type f \( -name '*.sh' -o -name '*.bats' -o -name '*.bash' \) ! -path '*/node_modules/*' | LC_ALL=C sort)"
    count="$(printf '%s\n' "${files}" | grep -c .)"
    found="$(printf '%s\n' "${files}" | tr '\n' '\0' | xargs -0 awk "${program}")"
    while IFS= read -r line; do
        [[ -n "${line}" ]] && echo "DETAIL: ${line}"
    done <<< "${found}"
    write-log "${run_dir}" lint-local-variables "Files: ${count} checked, $(printf '%s' "${found}" | grep -c .) unset local names"
    echo "NOTE: ${count} files, $(printf '%s' "${found}" | grep -c .) names not declared local"
    [[ -z "${found}" ]] || return 2
}
