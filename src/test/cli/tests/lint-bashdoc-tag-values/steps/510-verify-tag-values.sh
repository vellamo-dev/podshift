#!/usr/bin/env bash
# @file: 510-verify-tag-values.sh
# @source-dir: src/test/cli/tests/lint-bashdoc-tag-values/steps
# @group: test
# @category: step
# @description: Verify tag values.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks bashdoc tag names and allowed values against the marked tables in coding.md.
# @details:
#   Reads src/test/cli/tests/lint-bashdoc-tags/data/tags.conf for scan paths, conf files,
#   short-header and exception lists. Known tags, old tag names and allowed values come from
#   docs/coding.md between the <!-- lint:tags -->, <!-- lint:allowed-values --> and
#   <!-- lint:old-tags --> markers (each closed by <!-- lint:end -->). Override the coding.md
#   path with BASHDOC_CODING_MD for harnesses. Skips exception files. Scans every # @tag:
#   line in file and function headers. Does not re-check @host-edit, @run-as or @step.
#   @license-url must start with https://. @exitcode is not syntax-checked; some values
#   start with prose. Each finding is written to <run_dir>/lint-bashdoc-tag-values.log as
#   one line after the timestamp that write-log adds, with five tab-separated fields:
#   severity, kind, file, line and text. severity is problem. kind is one of doc-parse,
#   unknown, old-name or bad-value. In file and text a backslash is written as \\ and a
#   tab as \t.
# @arg: $1 - the run folder.
# @stdout: NOTE with the problem count, and a DETAIL line for each finding.
# @exitcode: 0 if all are fine, 2 otherwise (PodShift problem).
verify-tag-values() {
    local run_dir tags_conf coding_md section line file bad n work_dir
    local -a scan_paths short_header_files exception_files conf_files files
    run_dir="${1}"
    tags_conf="src/test/cli/tests/lint-bashdoc-tags/data/tags.conf"
    coding_md="${BASHDOC_CODING_MD:-docs/coding.md}"
    work_dir="artifacts/work/lint-bashdoc-tag-values"
    bad=0
    scan_paths=()
    short_header_files=()
    exception_files=()
    conf_files=()
    files=()

    mkdir -p "${work_dir}"

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
            short-header-files) short_header_files+=("${line}") ;;
            exception-files) exception_files+=("${line}") ;;
            conf-files) conf_files+=("${line}") ;;
        esac
    done < "${tags_conf}"

    write-log "${run_dir}" lint-bashdoc-tag-values \
        "Bashdoc: tag values, fields severity, kind, file, line, text, tab-separated"

    _bashdoc_tag_values_emit() {
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
        write-log "${run_dir}" lint-bashdoc-tag-values "$(awk -v sev="${sev}" -v kind="${kind}" -v f="${fpath}" -v ln="${ln}" -v text="${text}" '
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

    if [[ ! -f "${coding_md}" ]]; then
        _bashdoc_tag_values_emit problem doc-parse "${coding_md}" "" "coding.md is missing"
        write-log "${run_dir}" lint-bashdoc-tag-values "Bashdoc: ${bad} problems"
        echo "NOTE: ${bad} problems"
        return 2
    fi

    # Parse marked tables from coding.md into work files. Fail with doc-parse if a block
    # is missing or empty, or if allowed-values lacks @group, @category or @type.
    local parse_status known_file old_file allowed_file parse_err
    known_file="${work_dir}/known-tags.txt"
    old_file="${work_dir}/old-tags.tsv"
    allowed_file="${work_dir}/allowed.tsv"
    parse_err="${work_dir}/parse-errors.txt"
    : > "${known_file}"
    : > "${old_file}"
    : > "${allowed_file}"
    : > "${parse_err}"

    parse_status="$(awk -v out_tags="${known_file}" -v out_old="${old_file}" -v out_allowed="${allowed_file}" -v out_err="${parse_err}" '
        BEGIN {
            section = ""
            kn = 0
            om = 0
            ntags = 0
            saw_tags = 0
            saw_allowed = 0
            saw_old = 0
        }
        /^<!-- lint:allowed-values -->$/ { section = "allowed"; saw_allowed = 1; next }
        /^<!-- lint:tags -->$/ { section = "tags"; saw_tags = 1; next }
        /^<!-- lint:old-tags -->$/ { section = "old"; saw_old = 1; next }
        /^<!-- lint:end -->$/ { section = ""; next }

        section == "allowed" {
            if ($0 ~ /^- `@[a-z-]+`:/) {
                if (match($0, /`@[a-z-]+`/)) {
                    tag = substr($0, RSTART + 1, RLENGTH - 2)
                } else next
                rest = $0
                sub(/^- `@[a-z-]+`:[[:space:]]*/, "", rest)
                vals[tag] = ""
                while (match(rest, /`[^`]+`/)) {
                    v = substr(rest, RSTART + 1, RLENGTH - 2)
                    vals[tag] = vals[tag] (vals[tag] == "" ? "" : "\t") v
                    rest = substr(rest, RSTART + RLENGTH)
                }
                order[++ntags] = tag
            }
            next
        }

        section == "tags" {
            if ($0 ~ /^\| `@[a-z-]+` / || $0 ~ /^\| `@[a-z-]+`\|/) {
                if (match($0, /`@[a-z-]+`/)) {
                    t = substr($0, RSTART + 1, RLENGTH - 2)
                    if (!(t in known)) {
                        known[t] = 1
                        korder[++kn] = t
                    }
                }
            }
            next
        }

        section == "old" {
            if ($0 ~ /^\| `/ && $0 !~ /^\| Old / && $0 !~ /^\|---/) {
                line = $0
                c = 0
                delete cells
                while (match(line, /`[^`]+`/)) {
                    c++
                    cells[c] = substr(line, RSTART + 1, RLENGTH - 2)
                    line = substr(line, RSTART + RLENGTH)
                }
                if (c >= 2 && substr(cells[1], 1, 1) == "@") {
                    oldmap[++om] = cells[1] "\t" cells[2]
                }
            }
            next
        }

        END {
            err = 0
            if (!saw_tags) {
                print "missing <!-- lint:tags --> marker" > out_err
                err = 1
            } else if (kn == 0) {
                print "lint:tags block is empty" > out_err
                err = 1
            }
            if (!saw_allowed) {
                print "missing <!-- lint:allowed-values --> marker" > out_err
                err = 1
            } else if (ntags == 0) {
                print "lint:allowed-values block is empty" > out_err
                err = 1
            }
            if (!saw_old) {
                print "missing <!-- lint:old-tags --> marker" > out_err
                err = 1
            } else if (om == 0) {
                print "lint:old-tags block has no @ tag rows" > out_err
                err = 1
            }
            if (!("@group" in vals)) {
                print "allowed-values lacks @group" > out_err
                err = 1
            }
            if (!("@category" in vals)) {
                print "allowed-values lacks @category" > out_err
                err = 1
            }
            if (!("@type" in vals)) {
                print "allowed-values lacks @type" > out_err
                err = 1
            }
            if (err) {
                print "FAIL"
                exit 0
            }
            for (i = 1; i <= kn; i++) print korder[i] > out_tags
            for (i = 1; i <= om; i++) print oldmap[i] > out_old
            for (i = 1; i <= ntags; i++) {
                t = order[i]
                print t "\t" vals[t] > out_allowed
            }
            print "OK " kn " " om " " ntags
        }
    ' "${coding_md}")"

    if [[ "${parse_status}" == FAIL* ]] || [[ "${parse_status}" != OK* ]]; then
        while IFS= read -r line || [[ -n "${line}" ]]; do
            [[ -n "${line}" ]] || continue
            _bashdoc_tag_values_emit problem doc-parse "${coding_md}" "" "${line}"
        done < "${parse_err}"
        if [[ "${bad}" -eq 0 ]]; then
            _bashdoc_tag_values_emit problem doc-parse "${coding_md}" "" "failed to parse coding.md markers"
        fi
        write-log "${run_dir}" lint-bashdoc-tag-values "Bashdoc: ${bad} problems"
        echo "NOTE: ${bad} problems"
        return 2
    fi

    # parse_status is: OK <known> <old> <allowed-tags>
    local known_n old_n allowed_n
    known_n="$(printf '%s\n' "${parse_status}" | awk '{print $2}')"
    old_n="$(printf '%s\n' "${parse_status}" | awk '{print $3}')"
    allowed_n="$(printf '%s\n' "${parse_status}" | awk '{print $4}')"
    write-log "${run_dir}" lint-bashdoc-tag-values \
        "Bashdoc: parsed coding.md known=${known_n} old=${old_n} allowed-tags=${allowed_n}"
    echo "NOTE: parsed coding.md: ${known_n} known tags, ${old_n} old tags, ${allowed_n} allowed-value tags"

    # Build the file list: .sh under scan paths, plus listed conf files. Skip exceptions.
    local exception_set
    exception_set=$'\n'
    for file in ${exception_files[@]+"${exception_files[@]}"}; do
        exception_set="${exception_set}${file}"$'\n'
    done

    for file in ${scan_paths[@]+"${scan_paths[@]}"}; do
        [[ -d "${file}" ]] || continue
        while IFS= read -r line; do
            [[ -n "${line}" ]] || continue
            [[ "${exception_set}" == *$'\n'"${line}"$'\n'* ]] && continue
            files+=("${line}")
        done < <(find "${file}" -type f -name '*.sh' | sort)
    done
    for file in ${conf_files[@]+"${conf_files[@]}"}; do
        if [[ ! -f "${file}" ]]; then
            _bashdoc_tag_values_emit problem unknown "${file}" "" "listed conf file is missing"
            continue
        fi
        [[ "${exception_set}" == *$'\n'"${file}"$'\n'* ]] && continue
        files+=("${file}")
    done

    # Load known, old and allowed into ENVIRON-friendly strings for awk.
    local known_list old_list allowed_blob
    known_list="$(cat "${known_file}")"
    old_list="$(cat "${old_file}")"
    allowed_blob="$(cat "${allowed_file}")"

    for file in ${files[@]+"${files[@]}"}; do
        while IFS= read -r line; do
            case "${line}" in
                LOG\ *) write-log "${run_dir}" lint-bashdoc-tag-values "${line#LOG }" ;;
                SUMMARY\ *) n="${line#SUMMARY }"; bad=$((bad + n)) ;;
                *) printf '%s\n' "${line}" ;;
            esac
        done < <(KNOWN_LIST="${known_list}" OLD_LIST="${old_list}" ALLOWED_BLOB="${allowed_blob}" awk -v file="${file}" '
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
                nknown = split(ENVIRON["KNOWN_LIST"], karr, "\n")
                while (nknown > 0 && karr[nknown] == "") nknown--
                for (i = 1; i <= nknown; i++) known[karr[i]] = 1

                nold = split(ENVIRON["OLD_LIST"], oarr, "\n")
                while (nold > 0 && oarr[nold] == "") nold--
                for (i = 1; i <= nold; i++) {
                    if (oarr[i] == "") continue
                    split(oarr[i], pair, "\t")
                    if (pair[1] != "") oldmap[pair[1]] = pair[2]
                }

                # ALLOWED_BLOB lines: @tag\tval1\tval2...
                nall = split(ENVIRON["ALLOWED_BLOB"], aarr, "\n")
                while (nall > 0 && aarr[nall] == "") nall--
                for (i = 1; i <= nall; i++) {
                    if (aarr[i] == "") continue
                    nf = split(aarr[i], parts, "\t")
                    if (nf < 1) continue
                    tag = parts[1]
                    has_allowed[tag] = 1
                    for (j = 2; j <= nf; j++) allowed[tag, parts[j]] = 1
                }
                in_details = 0
            }
            # Match real tag lines only. @details continuation lines are "#   ..." and
            # do not match. A later "# @..." line ends the details block.
            /^# @[a-z0-9-]+:/ {
                in_details = 0
                tag = $0
                sub(/^# @/, "", tag)
                sub(/:.*$/, "", tag)
                full = "@" tag
                val = $0
                sub(/^# @[a-z0-9-]+:[[:space:]]*/, "", val)

                if (full in oldmap) {
                    report("old-name", full " is an old name; use " oldmap[full], full " -> " oldmap[full], FNR)
                    next
                }
                if (!(full in known)) {
                    report("unknown", "unknown tag " full, full, FNR)
                    next
                }
                if (full in has_allowed) {
                    if (!((full, val) in allowed)) {
                        report("bad-value", full " value \"" val "\" is not allowed", val, FNR)
                    }
                }
                if (full == "@license-url") {
                    if (val !~ /^https:\/\//) {
                        report("bad-value", "@license-url must start with https://", val, FNR)
                    }
                }
                if (full == "@details") in_details = 1
                next
            }
            /^#  / || /^#\t/ {
                # continuation / indented comment; ignore inside or outside details
                next
            }
            /^#/ { in_details = 0; next }
            END { printf "SUMMARY %d\n", bad }
        ' "${file}")
    done

    write-log "${run_dir}" lint-bashdoc-tag-values "Bashdoc: ${bad} problems"
    echo "NOTE: ${bad} problems"
    (( bad == 0 )) || return 2
}
