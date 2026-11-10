#!/usr/bin/env bash
# @file: 510-verify-description-length.sh
# @source-dir: src/test/cli/tests/lint-bashdoc-description-length/steps
# @group: test
# @category: step
# @description: Verify descriptions.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks every @description tag and @details block in the source tree.
# @details:
#   Each finding is also written to <run_dir>/lint-bashdoc-description-length.log as one line
#   after the timestamp that write-log adds, with five tab-separated fields: severity, kind, file,
#   line and text. severity is problem or warning. kind is one of empty, no-period, too-long,
#   second-sentence, bad-details-indent, outside-details or no-description. text is the
#   description, or the source line for the indent kinds. line and text are empty for
#   no-description. In file and text a backslash is written as \\ and a tab as \t, so a field
#   never holds a tab.
# @arg: $1 - the run folder.
# @stdout: NOTE with the problem count, and a DETAIL line for each finding.
# @exitcode: 0 if all are fine, 2 otherwise (PodShift problem).
verify-description-length() {
    local run_dir file max bad line n
    run_dir="${1}"
    max="${TST_BASHDOC_DESC_MAX_CHARS}"
    bad=0
    write-log "${run_dir}" lint-bashdoc-description-length "Bashdoc: max ${max} chars, fields severity, kind, file, line, text, tab-separated"
    while IFS= read -r file; do
        [[ -n "${file}" ]] || continue
        while IFS= read -r line; do
            case "${line}" in
                LOG\ *) write-log "${run_dir}" lint-bashdoc-description-length "${line#LOG }" ;;
                SUMMARY\ *) n="${line#SUMMARY }"; bad=$((bad + n)) ;;
                *) printf '%s\n' "${line}" ;;
            esac
        done < <(awk -v file="${file}" -v max="${max}" '
            function esc(s,   i, c, out) {
                out = ""
                for (i = 1; i <= length(s); i++) {
                    c = substr(s, i, 1)
                    if (c == "\\") out = out "\\\\"
                    else if (c == "\t") out = out "\\t"
                    else out = out c
                }
                return out
            }
            function report(sev, kind, msg, text, ln) {
                print "DETAIL: " file (ln == "" ? "" : ":" ln) ": " msg
                print "LOG " sev "\t" kind "\t" esc(file) "\t" ln "\t" esc(text)
                if (sev == "problem") bad++
            }
            /^# @description:/ {
                desc = $0
                sub(/^# @description:[[:space:]]*/, "", desc)
                found_desc = 1
                in_details = 0
                if (desc == "") {
                    report("problem", "empty", "empty @description", desc, FNR)
                } else {
                    if (desc !~ /\.$/) report("problem", "no-period", "@description has no final period", desc, FNR)
                    if (length(desc) > max) report("problem", "too-long", "@description is " length(desc) " chars (max " max ")", desc, FNR)
                    if (desc ~ /\.[[:space:]]+[A-Z]/) report("warning", "second-sentence", "@description may have a second sentence", desc, FNR)
                }
                next
            }
            /^# @details:/ { in_details = 1; next }
            /^#  / || /^#\t/ {
                if (in_details) {
                    if ($0 ~ /^#   [^ ]/ || $0 == "#   ") next
                    report("problem", "bad-details-indent", "bad @details indent", $0, FNR)
                } else {
                    report("problem", "outside-details", "indented line outside @details", $0, FNR)
                }
                next
            }
            /^#/ { in_details = 0 }
            END {
                if (!found_desc) report("problem", "no-description", "no @description", "", "")
                printf "SUMMARY %d\n", bad
            }
        ' "${file}")
    done < <(find src -name '*.sh' | sort)
    write-log "${run_dir}" lint-bashdoc-description-length "Bashdoc: ${bad} problems"
    echo "NOTE: ${bad} problems"
    (( bad == 0 )) || return 2
}
