#!/usr/bin/env bash
# @file: 510-verify-install-output.sh
# @source-dir: src/test/cli/tests/install-rpm/steps
# @group: test
# @category: step
# @description: Verify install output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks install.log: dnf must finish with Complete! and every expected step must report OK or SKIP.
# @details:
#   The expected steps are in data/expected-steps.conf. Other warning or error lines are collected
#   in install-warnings.log and do not fail the step.
# @arg: $1 - the run folder.
# @stdout: NOTE with the step counts, DETAIL lines for steps that are not OK.
# @exitcode: 0 if all is well, 1 if install.log is missing, 2 otherwise.
verify-install-output() {
    local run_dir log_file conf warn_file results tag kind desc status ok skip bad warnings note rc
    run_dir="${1}"
    log_file="${run_dir}/install.log"
    conf="src/test/cli/tests/install-rpm/data/expected-steps.conf"
    warn_file="${run_dir}/install-warnings.log"
    [[ -f "${log_file}" ]] || { echo "install.log not found in ${run_dir}"; return 1; }
    rc=0
    if ! grep -q '^Complete!' "${log_file}"; then
        echo "DETAIL: ✘ dnf did not finish (no Complete! line)"
        rc=2
    fi
    # Each [PS-...] header with its final status: WARN wins over OK, OK over SKIP.
    results="$(awk '
        function emit() { print step, (warn ? "WARN" : ok ? "OK" : skip ? "SKIP" : "NONE") }
        /\[PS-/ { if (step != "") emit(); match($0, /\[PS-[^]]+\]/); step = substr($0, RSTART + 1, RLENGTH - 2); ok = warn = skip = 0; next }
        /\[WARN\]/ { warn = 1 }
        /\[OK\]/ { ok = 1 }
        /\[SKIP\]/ { skip = 1 }
        END { if (step != "") emit() }
    ' "${log_file}")"
    ok=0
    skip=0
    bad=0
    while read -r tag kind desc; do
        [[ -n "${tag}" && "${tag}" != "#"* ]] || continue
        status="$(printf '%s\n' "${results}" | awk -v t="${tag}" '$1 == t { print $2 }')"
        if [[ "${kind}" == "marker" ]]; then
            [[ -n "${status}" ]] && continue
            echo "DETAIL: ✘ ${desc} (not reported)"
            bad=$((bad + 1))
            continue
        fi
        case "${status}" in
            OK) ok=$((ok + 1)) ;;
            SKIP) skip=$((skip + 1)); echo "DETAIL: ○ ${desc} (skipped)" ;;
            WARN) bad=$((bad + 1)); echo "DETAIL: ⚠ ${desc} (warning)" ;;
            *) bad=$((bad + 1)); echo "DETAIL: ✘ ${desc} (no status)" ;;
        esac
    done <"${conf}"
    grep -nE 'Warning|warning|level=warning|level=error|[Ee]rror|failed|Failed' "${log_file}" | grep -v '\[WARN\]' >"${warn_file}"
    warnings="$(grep -c . "${warn_file}")"
    note="${ok} OK, ${skip} skipped, ${bad} not OK"
    (( warnings == 0 )) || note="${note}, ${warnings} other warnings in install-warnings.log"
    write-log "${run_dir}" install-rpm "Install output: ${note}"
    echo "NOTE: ${note}"
    (( bad == 0 )) || rc=2
    return "${rc}"
}
