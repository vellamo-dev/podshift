#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check
# @dest-dir: /opt/podshift/cli/modules/health-check
# @host-edit: no
# @group: health-check
# @category: entry
# @description: Runs every health check in its own realm and prints the report.
# @run-as: any
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_7A3F9C1E5B8D:-}" ]]; then
    DIR_7A3F9C1E5B8D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7A3F9C1E5B8D
fi

# @description: Runs every health check and prints the report.
# @arg: $@ - optional flags: --tsv, --json, --plain, --fail-if-unhealthy.
# @stdout: the report in the chosen format. For people, each check is shown as it finishes, with a spinner while it runs at a terminal.
# @stderr: an error for an unknown option or when no checks are found.
# @exitcode: 0 = the run finished, 3 = cannot run (unknown option, no checks).
# @exitcode: with --fail-if-unhealthy: 0 = healthy, 1 = check incomplete, 2 = needs attention or issues found.
podshift-health-check() {
    local fn_dir mode fail_if_unhealthy caller who script group prev_group line out_file results verdict_line
    fn_dir="${DIR_7A3F9C1E5B8D}/fn"
    mode="human"
    fail_if_unhealthy=0
    results=""

    # 1. Read the options.
    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --tsv)               mode="tsv" ;;
            --json)              mode="json" ;;
            --plain)             PODSHIFT_PLAIN="true" ;;
            --fail-if-unhealthy) fail_if_unhealthy=1 ;;
            *) echo "Unknown option: ${1}. See 'podshift --help health-check'." >&2; return 3 ;;
        esac
        shift
    done

    # shellcheck source=/dev/null
    [[ -f "${DIR_7A3F9C1E5B8D}/../../../conf/main.conf" ]] && source "${DIR_7A3F9C1E5B8D}/../../../conf/main.conf"

    # 2. Decide once, while the output is still the terminal, whether it is interactive.
    # shellcheck source=../../../fn/utils/is-interactive-output.sh
    declare -F is-interactive-output >/dev/null || source "${DIR_7A3F9C1E5B8D}/../../../fn/utils/is-interactive-output.sh"
    PODSHIFT_OUTPUT="plain"
    [[ "${mode}" == "human" ]] && is-interactive-output && PODSHIFT_OUTPUT="interactive"

    # 3. Find out who is calling, once.
    # shellcheck source=fn/health-caller.sh
    declare -F health-caller >/dev/null || source "${fn_dir}/health-caller.sh"
    caller="$(health-caller)"
    # Who ran it, for the head line. A plain user is "other user", so nobody reads it as "switch to this user".
    case "${caller}" in
        other) who="as other user, some checks need root" ;;
        *)     who="as ${caller}" ;;
    esac

    # 4. Run every check and collect one result line per check. For people, show each check as it finishes.
    # shellcheck source=fn/health-result.sh
    declare -F health-result >/dev/null || source "${fn_dir}/health-result.sh"
    # shellcheck source=fn/health-run-live.sh
    declare -F health-run-live >/dev/null || source "${fn_dir}/health-run-live.sh"
    # shellcheck source=fn/health-render-group.sh
    declare -F health-render-group >/dev/null || source "${fn_dir}/health-render-group.sh"
    # shellcheck source=fn/health-render-row.sh
    declare -F health-render-row >/dev/null || source "${fn_dir}/health-render-row.sh"
    # shellcheck source=../../../fn/utils/paint.sh
    declare -F paint >/dev/null || source "${DIR_7A3F9C1E5B8D}/../../../fn/utils/paint.sh"
    out_file="$(mktemp)"
    prev_group=""
    for script in "${DIR_7A3F9C1E5B8D}/checks"/*/*.sh; do
        [[ -f "${script}" ]] || continue
        group="$(basename "$(dirname "${script}")")"
        group="${group#*-}"
        if [[ "${mode}" != "human" ]]; then
            results+="$(health-result "${script}" "${group}" "${caller}")"$'\n'
            continue
        fi
        [[ -n "${prev_group}" ]] || printf '%s %s\n' "$(paint marker '▶')" "$(paint title "Health check (${who})")"
        [[ "${group}" == "${prev_group}" ]] || health-render-group "${group}" "${DIR_7A3F9C1E5B8D}/groups.conf"
        prev_group="${group}"
        health-run-live "${script}" "${group}" "${caller}" "${out_file}"
        line="$(cat "${out_file}")"
        health-render-row "${line}" "${script}"
        results+="${line}"$'\n'
    done
    rm -f "${out_file}"
    results="${results%$'\n'}"
    if [[ -z "${results}" ]]; then
        echo "Health check: no checks found." >&2
        return 3
    fi

    # 5. Sum up the verdict.
    # shellcheck source=fn/health-verdict.sh
    declare -F health-verdict >/dev/null || source "${fn_dir}/health-verdict.sh"
    verdict_line="$(health-verdict "${results}")"

    # 6. Print the result, or the whole report in the chosen format.
    case "${mode}" in
        human)
            # shellcheck source=fn/health-render-result.sh
            declare -F health-render-result >/dev/null || source "${fn_dir}/health-render-result.sh"
            health-render-result "${verdict_line}"
            ;;
        tsv)
            # shellcheck source=fn/health-render-tsv.sh
            declare -F health-render-tsv >/dev/null || source "${fn_dir}/health-render-tsv.sh"
            health-render-tsv "${results}" "${verdict_line}" "${caller}"
            ;;
        json)
            # shellcheck source=fn/health-render-json.sh
            declare -F health-render-json >/dev/null || source "${fn_dir}/health-render-json.sh"
            health-render-json "${results}" "${verdict_line}" "${caller}"
            ;;
    esac

    # 7. Return: 0 means the run finished, unless --fail-if-unhealthy asks for the health result.
    [[ "${fail_if_unhealthy}" -eq 1 ]] || return 0
    case "${verdict_line%%$'\t'*}" in
        healthy)    return 0 ;;
        incomplete) return 1 ;;
        *)          return 2 ;;
    esac
}

podshift-health-check "$@"
