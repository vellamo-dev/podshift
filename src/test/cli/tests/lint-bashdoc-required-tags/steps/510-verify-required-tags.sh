#!/usr/bin/env bash
# @file: 510-verify-required-tags.sh
# @source-dir: src/test/cli/tests/lint-bashdoc-required-tags/steps
# @group: test
# @category: step
# @description: Verify required tags.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks always-required bashdoc tags on scanned files under the configured roots.
# @details:
#   Reads src/test/cli/tests/lint-bashdoc-tags/data/tags.conf for scan paths, required tags,
#   short-header files and exceptions. Each finding is also written to
#   <run_dir>/lint-bashdoc-required-tags.log as one line after the timestamp that write-log adds,
#   with five tab-separated fields: severity, kind, file, line and text. severity is problem.
#   kind is one of missing, duplicate, path-mismatch, short-header-extra, short-header-order,
#   exception-has-tags, exception-no-comment or exception-missing. In file and text a backslash
#   is written as \\ and a tab as \t, so a field never holds a tab.
# @arg: $1 - the run folder.
# @stdout: NOTE with the problem count, and a DETAIL line for each finding.
# @exitcode: 0 if all are fine, 2 otherwise (PodShift problem).
verify-required-tags() {
    local run_dir tags_conf section line file bad n mode
    local -a scan_paths required_tags short_header_tags short_header_files exception_files conf_files files
    run_dir="${1}"
    tags_conf="src/test/cli/tests/lint-bashdoc-tags/data/tags.conf"
    bad=0
    scan_paths=()
    required_tags=()
    short_header_tags=()
    short_header_files=()
    exception_files=()
    conf_files=()
    files=()

    if [[ ! -f "${tags_conf}" ]]; then
        echo "DETAIL: ${tags_conf}: missing tags.conf"
        echo "NOTE: 1 problems"
        return 2
    fi

    section=""
    while IFS= read -r line || [[ -n "${line}" ]]; do
        case "${line}" in
            \[*\])
                section="${line#\[}"
                section="${section%\]}"
                continue
                ;;
        esac
        [[ -n "${section}" ]] || continue
        [[ -n "${line}" ]] || continue
        [[ "${line}" != \#* ]] || continue
        case "${section}" in
            scan-paths) scan_paths+=("${line}") ;;
            required-tags) required_tags+=("${line}") ;;
            short-header-tags) short_header_tags+=("${line}") ;;
            short-header-files) short_header_files+=("${line}") ;;
            exception-files) exception_files+=("${line}") ;;
            conf-files) conf_files+=("${line}") ;;
        esac
    done < "${tags_conf}"

    write-log "${run_dir}" lint-bashdoc-required-tags \
        "Bashdoc: required tags, fields severity, kind, file, line, text, tab-separated"

    # Emit one finding: DETAIL on screen and one LOG line for write-log.
    # Uses the same portable awk esc() as lint-bashdoc-description-length.
    _bashdoc_required_emit() {
        local sev kind fpath ln text
        sev="${1}"
        kind="${2}"
        fpath="${3}"
        ln="${4}"
        text="${5}"
        if [[ -n "${ln}" ]]; then
            printf 'DETAIL: %s:%s: %s\n' "${fpath}" "${ln}" "${text}"
        else
            printf 'DETAIL: %s: %s\n' "${fpath}" "${text}"
        fi
        write-log "${run_dir}" lint-bashdoc-required-tags "$(awk -v sev="${sev}" -v kind="${kind}" -v f="${fpath}" -v ln="${ln}" -v text="${text}" '
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
            BEGIN { print sev "\t" kind "\t" esc(f) "\t" ln "\t" esc(text) }
        ')"
        bad=$((bad + 1))
    }

    # Exception files: must exist, start with a plain comment, and have no # @ tags.
    for file in ${exception_files[@]+"${exception_files[@]}"}; do
        if [[ ! -f "${file}" ]]; then
            _bashdoc_required_emit problem exception-missing "${file}" "" "exception file is missing"
            continue
        fi
        while IFS= read -r line; do
            case "${line}" in
                LOG\ *) write-log "${run_dir}" lint-bashdoc-required-tags "${line#LOG }" ;;
                SUMMARY\ *) n="${line#SUMMARY }"; bad=$((bad + n)) ;;
                *) printf '%s\n' "${line}" ;;
            esac
        done < <(awk -v file="${file}" '
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
            function report(kind, msg, text, ln) {
                print "DETAIL: " file (ln == "" ? "" : ":" ln) ": " msg
                print "LOG problem\t" kind "\t" esc(file) "\t" ln "\t" esc(text)
                bad++
            }
            NR == 1 {
                if ($0 ~ /^# @/ || $0 !~ /^#/) {
                    report("exception-no-comment", "exception file must start with a plain comment", $0, FNR)
                }
            }
            /^# @/ {
                report("exception-has-tags", "exception file must not have # @ tags", $0, FNR)
            }
            END { printf "SUMMARY %d\n", bad }
        ' "${file}")
    done

    # Build the file list: .sh under scan paths, plus listed conf files.
    for file in ${scan_paths[@]+"${scan_paths[@]}"}; do
        [[ -d "${file}" ]] || continue
        while IFS= read -r line; do
            [[ -n "${line}" ]] || continue
            files+=("${line}")
        done < <(find "${file}" -type f -name '*.sh' | sort)
    done
    for file in ${conf_files[@]+"${conf_files[@]}"}; do
        if [[ ! -f "${file}" ]]; then
            _bashdoc_required_emit problem missing "${file}" "" "listed conf file is missing"
            continue
        fi
        files+=("${file}")
    done

    local short_set exception_set is_short is_exc req_list short_list
    short_set=$'\n'
    for file in ${short_header_files[@]+"${short_header_files[@]}"}; do
        short_set="${short_set}${file}"$'\n'
    done
    exception_set=$'\n'
    for file in ${exception_files[@]+"${exception_files[@]}"}; do
        exception_set="${exception_set}${file}"$'\n'
    done
    req_list="$(printf '%s\n' ${required_tags[@]+"${required_tags[@]}"})"
    short_list="$(printf '%s\n' ${short_header_tags[@]+"${short_header_tags[@]}"})"

    for file in ${files[@]+"${files[@]}"}; do
        is_exc=0
        is_short=0
        [[ "${exception_set}" == *$'\n'"${file}"$'\n'* ]] && is_exc=1
        [[ "${short_set}" == *$'\n'"${file}"$'\n'* ]] && is_short=1
        (( is_exc == 0 )) || continue
        if [[ "${is_short}" -eq 1 ]]; then
            mode="short"
        else
            mode="normal"
        fi

        while IFS= read -r line; do
            case "${line}" in
                LOG\ *) write-log "${run_dir}" lint-bashdoc-required-tags "${line#LOG }" ;;
                SUMMARY\ *) n="${line#SUMMARY }"; bad=$((bad + n)) ;;
                *) printf '%s\n' "${line}" ;;
            esac
        done < <(REQ_LIST="${req_list}" SHORT_LIST="${short_list}" awk -v file="${file}" -v mode="${mode}" '
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
            function report(kind, msg, text, ln) {
                print "DETAIL: " file (ln == "" ? "" : ":" ln) ": " msg
                print "LOG problem\t" kind "\t" esc(file) "\t" ln "\t" esc(text)
                bad++
            }
            BEGIN {
                nreq = split(ENVIRON["REQ_LIST"], reqs, "\n")
                while (nreq > 0 && reqs[nreq] == "") nreq--
                nshort = split(ENVIRON["SHORT_LIST"], shorts, "\n")
                while (nshort > 0 && shorts[nshort] == "") nshort--
                for (i = 1; i <= nshort; i++) short_ok[shorts[i]] = 1
                base = file
                sub(/.*\//, "", base)
                dir = file
                if (dir ~ /\//) sub(/\/[^\/]*$/, "", dir)
                else dir = "."
            }
            NR == 1 && /^#!/ { next }
            done { next }
            /^# @details:/ {
                in_details = 1
                tag = "details"
                val = $0
                sub(/^# @details:[[:space:]]*/, "", val)
                n++
                order[n] = "@" tag
                count["@" tag]++
                if (count["@" tag] == 1) {
                    first_ln["@" tag] = FNR
                    first_val["@" tag] = val
                }
                next
            }
            /^#   / || /^#\t/ {
                if (in_details) next
                done = 1
                next
            }
            /^# @[a-z0-9-]+:/ {
                in_details = 0
                tag = $0
                sub(/^# @/, "", tag)
                sub(/:.*$/, "", tag)
                val = $0
                sub(/^# @[a-z0-9-]+:[[:space:]]*/, "", val)
                n++
                order[n] = "@" tag
                count["@" tag]++
                if (count["@" tag] == 1) {
                    first_ln["@" tag] = FNR
                    first_val["@" tag] = val
                }
                next
            }
            /^#/ {
                if (n > 0) done = 1
                next
            }
            /^$/ {
                if (n > 0) done = 1
                next
            }
            { if (n > 0 || NR > 1) done = 1 }
            END {
                # File header must start with @file (coding.md). A leading setting-tag
                # block in a .conf is not the file header.
                if (mode == "normal" && n > 0 && order[1] != "@file") {
                    delete count
                    n = 0
                }
                if (mode == "short") {
                    for (i = 1; i <= n; i++) {
                        if (!(order[i] in short_ok)) {
                            report("short-header-extra", "short-header file has " order[i], order[i], first_ln[order[i]])
                        }
                    }
                    same = (n == nshort)
                    if (same) {
                        for (i = 1; i <= nshort; i++) {
                            if (order[i] != shorts[i]) { same = 0; break }
                        }
                    }
                    if (!same) {
                        got = ""
                        for (i = 1; i <= n; i++) got = got (i > 1 ? " " : "") order[i]
                        expected_tags = ""
                        for (i = 1; i <= nshort; i++) expected_tags = expected_tags (i > 1 ? " " : "") shorts[i]
                        report("short-header-order", "short-header tags must be exactly: " expected_tags, got, (n ? first_ln[order[1]] : ""))
                    }
                } else {
                    for (i = 1; i <= nreq; i++) {
                        t = reqs[i]
                        if (!(t in count) || count[t] == 0) {
                            report("missing", "missing " t, t, "")
                        } else if (count[t] > 1) {
                            report("duplicate", "duplicate " t " (" count[t] " times)", first_val[t], first_ln[t])
                        }
                    }
                    if ("@file" in count && count["@file"] >= 1 && first_val["@file"] != base) {
                        report("path-mismatch", "@file is \"" first_val["@file"] "\", expected \"" base "\"", first_val["@file"], first_ln["@file"])
                    }
                    if ("@source-dir" in count && count["@source-dir"] >= 1 && first_val["@source-dir"] != dir) {
                        report("path-mismatch", "@source-dir is \"" first_val["@source-dir"] "\", expected \"" dir "\"", first_val["@source-dir"], first_ln["@source-dir"])
                    }
                }
                printf "SUMMARY %d\n", bad
            }
        ' "${file}")
    done

    for file in ${short_header_files[@]+"${short_header_files[@]}"}; do
        if [[ ! -f "${file}" ]]; then
            _bashdoc_required_emit problem missing "${file}" "" "short-header file is missing"
        fi
    done

    write-log "${run_dir}" lint-bashdoc-required-tags "Bashdoc: ${bad} problems"
    echo "NOTE: ${bad} problems"
    (( bad == 0 )) || return 2
}
