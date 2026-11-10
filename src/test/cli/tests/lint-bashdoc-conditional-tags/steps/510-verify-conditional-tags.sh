#!/usr/bin/env bash
# @file: 510-verify-conditional-tags.sh
# @source-dir: src/test/cli/tests/lint-bashdoc-conditional-tags/steps
# @group: test
# @category: step
# @description: Verify conditional tags.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks path- and category-dependent bashdoc tags on scanned files.
# @details:
#   Reads src/test/cli/tests/lint-bashdoc-tags/data/tags.conf for scan paths, conf files,
#   short-header and exception lists, host-edit-yes, step prefixes, step entry files,
#   step-outside-rpm and run-as values. Skips short-header and exception files.
#   Under src/server, @dest-dir must equal @source-dir with the src/server/ prefix removed
#   (so src/server/opt/podshift/cli gives /opt/podshift/cli), and @host-edit must be no
#   unless the file is listed in [host-edit-yes]. Outside src/server those two tags must
#   not appear. @category: step files and the listed entry scripts need @step with the
#   matching PS-XX prefix; make-rootless-remote-key.sh is allowed via [step-outside-rpm].
#   @category: check files need @title, @rationale and @run-as. Module main.sh files also
#   need @run-as (lint-help-files 540 already checks modules; this suite covers them too).
#   Each finding is written to <run_dir>/lint-bashdoc-conditional-tags.log as one line after
#   the timestamp that write-log adds, with five tab-separated fields: severity, kind, file,
#   line and text. severity is problem. kind is one of missing, dest-mismatch, not-allowed,
#   bad-value or bad-prefix. In file and text a backslash is written as \\ and a tab as \t.
# @arg: $1 - the run folder.
# @stdout: NOTE with the problem count, and a DETAIL line for each finding.
# @exitcode: 0 if all are fine, 2 otherwise (PodShift problem).
verify-conditional-tags() {
    local run_dir tags_conf section line file bad n
    local -a scan_paths short_header_files exception_files conf_files files
    local -a host_edit_yes step_prefixes step_entry_files step_outside_rpm run_as_values
    run_dir="${1}"
    tags_conf="src/test/cli/tests/lint-bashdoc-tags/data/tags.conf"
    bad=0
    scan_paths=()
    short_header_files=()
    exception_files=()
    conf_files=()
    files=()
    host_edit_yes=()
    step_prefixes=()
    step_entry_files=()
    step_outside_rpm=()
    run_as_values=()

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
            host-edit-yes) host_edit_yes+=("${line}") ;;
            step-prefixes) step_prefixes+=("${line}") ;;
            step-entry-files) step_entry_files+=("${line}") ;;
            step-outside-rpm) step_outside_rpm+=("${line}") ;;
            run-as-values) run_as_values+=("${line}") ;;
        esac
    done < "${tags_conf}"

    write-log "${run_dir}" lint-bashdoc-conditional-tags \
        "Bashdoc: conditional tags, fields severity, kind, file, line, text, tab-separated"

    _bashdoc_conditional_emit() {
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
        write-log "${run_dir}" lint-bashdoc-conditional-tags "$(awk -v sev="${sev}" -v kind="${kind}" -v f="${fpath}" -v ln="${ln}" -v text="${text}" '
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

    for file in ${scan_paths[@]+"${scan_paths[@]}"}; do
        [[ -d "${file}" ]] || continue
        while IFS= read -r line; do
            [[ -n "${line}" ]] || continue
            files+=("${line}")
        done < <(find "${file}" -type f -name '*.sh' | sort)
    done
    for file in ${conf_files[@]+"${conf_files[@]}"}; do
        if [[ ! -f "${file}" ]]; then
            _bashdoc_conditional_emit problem missing "${file}" "" "listed conf file is missing"
            continue
        fi
        files+=("${file}")
    done

    local short_set exception_set
    short_set=$'\n'
    for file in ${short_header_files[@]+"${short_header_files[@]}"}; do
        short_set="${short_set}${file}"$'\n'
    done
    exception_set=$'\n'
    for file in ${exception_files[@]+"${exception_files[@]}"}; do
        exception_set="${exception_set}${file}"$'\n'
    done

    local host_yes_list step_pref_list step_entry_list step_out_list run_as_list
    host_yes_list="$(printf '%s\n' ${host_edit_yes[@]+"${host_edit_yes[@]}"})"
    step_pref_list="$(printf '%s\n' ${step_prefixes[@]+"${step_prefixes[@]}"})"
    step_entry_list="$(printf '%s\n' ${step_entry_files[@]+"${step_entry_files[@]}"})"
    step_out_list="$(printf '%s\n' ${step_outside_rpm[@]+"${step_outside_rpm[@]}"})"
    run_as_list="$(printf '%s\n' ${run_as_values[@]+"${run_as_values[@]}"})"

    for file in ${files[@]+"${files[@]}"}; do
        [[ "${exception_set}" == *$'\n'"${file}"$'\n'* ]] && continue
        [[ "${short_set}" == *$'\n'"${file}"$'\n'* ]] && continue

        while IFS= read -r line; do
            case "${line}" in
                LOG\ *) write-log "${run_dir}" lint-bashdoc-conditional-tags "${line#LOG }" ;;
                SUMMARY\ *) n="${line#SUMMARY }"; bad=$((bad + n)) ;;
                *) printf '%s\n' "${line}" ;;
            esac
        done < <(HOST_YES="${host_yes_list}" STEP_PREF="${step_pref_list}" STEP_ENTRY="${step_entry_list}" STEP_OUT="${step_out_list}" RUN_AS="${run_as_list}" awk -v file="${file}" '
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
            function load_map(env, keys, vals,   n, i, line, eq, k, v) {
                n = split(env, lines, "\n")
                for (i = 1; i <= n; i++) {
                    line = lines[i]
                    if (line == "") continue
                    eq = index(line, "=")
                    if (eq == 0) continue
                    k = substr(line, 1, eq - 1)
                    v = substr(line, eq + 1)
                    keys[k] = 1
                    vals[k] = v
                }
            }
            function load_set(env, set,   n, i, line) {
                n = split(env, lines, "\n")
                for (i = 1; i <= n; i++) {
                    line = lines[i]
                    if (line == "") continue
                    set[line] = 1
                }
            }
            function step_prefix_of(path,   best, best_len, p, plen) {
                best = ""
                best_len = -1
                for (p in step_pref_keys) {
                    plen = length(p)
                    if (path == p || index(path, p "/") == 1) {
                        if (plen > best_len) {
                            best = step_pref_vals[p]
                            best_len = plen
                        }
                    }
                }
                return best
            }
            BEGIN {
                load_set(ENVIRON["HOST_YES"], host_yes)
                load_map(ENVIRON["STEP_PREF"], step_pref_keys, step_pref_vals)
                load_map(ENVIRON["STEP_ENTRY"], step_entry_keys, step_entry_vals)
                load_map(ENVIRON["STEP_OUT"], step_out_keys, step_out_vals)
                load_set(ENVIRON["RUN_AS"], run_as_ok)
                under_server = (index(file, "src/server/") == 1)
                is_module_main = (file ~ /^src\/server\/opt\/podshift\/cli\/modules\/[^\/]+\/main\.sh$/)
            }
            NR == 1 && /^#!/ { next }
            done { next }
            /^# @details:/ {
                in_details = 1
                tag = "details"
                val = $0
                sub(/^# @details:[[:space:]]*/, "", val)
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
                count["@" tag]++
                if (count["@" tag] == 1) {
                    first_ln["@" tag] = FNR
                    first_val["@" tag] = val
                    # Remember first tag; if it is not @file the block is not a file header
                    # (same rule as lint-bashdoc-required-tags for setting-tag conf files).
                    ntags++
                    if (ntags == 1) first_tag = "@" tag
                }
                next
            }
            /^#/ {
                if (ntags > 0) done = 1
                next
            }
            /^$/ {
                if (ntags > 0) done = 1
                next
            }
            { if (ntags > 0 || NR > 1) done = 1 }
            END {
                if (ntags > 0 && first_tag != "@file") {
                    delete count
                    delete first_ln
                    delete first_val
                    ntags = 0
                }

                category = ("@category" in count) ? first_val["@category"] : ""
                source_dir = ("@source-dir" in count) ? first_val["@source-dir"] : ""
                has_dest = ("@dest-dir" in count && count["@dest-dir"] >= 1)
                has_host = ("@host-edit" in count && count["@host-edit"] >= 1)
                has_step = ("@step" in count && count["@step"] >= 1)
                has_title = ("@title" in count && count["@title"] >= 1)
                has_rationale = ("@rationale" in count && count["@rationale"] >= 1)
                has_run_as = ("@run-as" in count && count["@run-as"] >= 1)

                # --- @dest-dir and @host-edit ---
                if (under_server) {
                    if (!has_dest) {
                        report("missing", "missing @dest-dir", "@dest-dir", "")
                    } else {
                        expected_dest = source_dir
                        sub(/^src\/server/, "", expected_dest)
                        if (expected_dest == "") expected_dest = "/"
                        else if (expected_dest !~ /^\//) expected_dest = "/" expected_dest
                        if (first_val["@dest-dir"] != expected_dest) {
                            report("dest-mismatch", "@dest-dir is \"" first_val["@dest-dir"] "\", expected \"" expected_dest "\"", first_val["@dest-dir"], first_ln["@dest-dir"])
                        }
                    }
                    if (!has_host) {
                        report("missing", "missing @host-edit", "@host-edit", "")
                    } else {
                        hv = first_val["@host-edit"]
                        if (file in host_yes) {
                            if (hv != "yes" && hv != "no") {
                                report("bad-value", "@host-edit is \"" hv "\", expected yes or no", hv, first_ln["@host-edit"])
                            }
                        } else if (hv == "yes") {
                            report("not-allowed", "@host-edit: yes is not allowed for this file", hv, first_ln["@host-edit"])
                        } else if (hv != "no") {
                            report("bad-value", "@host-edit is \"" hv "\", expected no", hv, first_ln["@host-edit"])
                        }
                    }
                } else {
                    if (has_dest) {
                        report("not-allowed", "@dest-dir is not allowed outside src/server", first_val["@dest-dir"], first_ln["@dest-dir"])
                    }
                    if (has_host) {
                        report("not-allowed", "@host-edit is not allowed outside src/server", first_val["@host-edit"], first_ln["@host-edit"])
                    }
                }

                # --- @step ---
                expected_prefix = ""
                requires_step = 0
                if (file in step_out_keys) {
                    expected_prefix = step_out_vals[file]
                    requires_step = 1
                } else if (file in step_entry_keys) {
                    expected_prefix = step_entry_vals[file]
                    requires_step = 1
                } else if (category == "step") {
                    expected_prefix = step_prefix_of(file)
                    requires_step = 1
                }

                if (requires_step) {
                    if (!has_step) {
                        report("missing", "missing @step", "@step", "")
                    } else {
                        sv = first_val["@step"]
                        if (sv !~ /^PS-[A-Z]{2}-[A-Z0-9]{3}$/) {
                            report("bad-value", "@step is \"" sv "\", expected PS-XX-YYY", sv, first_ln["@step"])
                        } else if (expected_prefix == "") {
                            report("not-allowed", "@step is not allowed outside step folders", sv, first_ln["@step"])
                        } else {
                            got_prefix = sv
                            sub(/-[A-Z0-9]{3}$/, "", got_prefix)
                            if (got_prefix != expected_prefix) {
                                report("bad-prefix", "@step prefix is \"" got_prefix "\", expected \"" expected_prefix "\"", sv, first_ln["@step"])
                            }
                        }
                    }
                } else if (has_step) {
                    report("not-allowed", "@step is not allowed on this file", first_val["@step"], first_ln["@step"])
                }

                # --- checks: @title, @rationale, @run-as ---
                if (category == "check") {
                    if (!has_title) {
                        report("missing", "missing @title", "@title", "")
                    }
                    if (!has_rationale) {
                        report("missing", "missing @rationale", "@rationale", "")
                    }
                    if (!has_run_as) {
                        report("missing", "missing @run-as", "@run-as", "")
                    } else if (!(first_val["@run-as"] in run_as_ok)) {
                        report("bad-value", "@run-as is \"" first_val["@run-as"] "\", expected any, podshift or root", first_val["@run-as"], first_ln["@run-as"])
                    }
                } else {
                    if (has_title) {
                        report("not-allowed", "@title is only allowed on @category: check", first_val["@title"], first_ln["@title"])
                    }
                    if (has_rationale) {
                        report("not-allowed", "@rationale is only allowed on @category: check", first_val["@rationale"], first_ln["@rationale"])
                    }
                }

                # --- module main.sh @run-as ---
                if (is_module_main) {
                    if (!has_run_as) {
                        report("missing", "missing @run-as", "@run-as", "")
                    } else if (!(first_val["@run-as"] in run_as_ok)) {
                        report("bad-value", "@run-as is \"" first_val["@run-as"] "\", expected any, podshift or root", first_val["@run-as"], first_ln["@run-as"])
                    }
                }

                printf "SUMMARY %d\n", bad
            }
        ' "${file}")
    done

    write-log "${run_dir}" lint-bashdoc-conditional-tags "Bashdoc: ${bad} problems"
    echo "NOTE: ${bad} problems"
    (( bad == 0 )) || return 2
}
