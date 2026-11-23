#!/usr/bin/env bash
# @file: cockpit-health-check-run.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/health-check/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/health-check/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Runs every CLI health check and prints one result line per check, with fix text.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_B14EF8DA54D3:-}" ]]; then
    DIR_B14EF8DA54D3="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_B14EF8DA54D3
fi

# @description: Runs every CLI health check and prints one result line per check, with fix text.
# @details:
#   Uses the same health-result and check scripts as `podshift health-check`, from the CLI module
#   folder /opt/podshift/cli/modules/health-check. A sixth field holds the check's @fix text for
#   INFO, WARN and FAIL, or is empty otherwise.
# @stdout: result lines: group, id, title, status, detail, fix.
# @exitcode: 0 always.
cockpit-health-check-run() {
    local script group caller line group_name id title status detail fix cli_dir
    cli_dir="${DIR_B14EF8DA54D3}/../../../../../cli/modules/health-check"
    # shellcheck source=../../../../../cli/modules/health-check/fn/health-caller.sh
    declare -F health-caller >/dev/null || source "${cli_dir}/fn/health-caller.sh"
    # shellcheck source=../../../../../cli/modules/health-check/fn/health-result.sh
    declare -F health-result >/dev/null || source "${cli_dir}/fn/health-result.sh"
    caller="$(health-caller)"
    for script in "${cli_dir}/checks"/*/*.sh; do
        [[ -f "${script}" ]] || continue
        group="$(basename "$(dirname "${script}")")"
        group="${group#*-}"
        line="$(health-result "${script}" "${group}" "${caller}")"
        IFS=$'\t' read -r group_name id title status detail <<< "${line}"
        fix=""
        case "${status}" in
            INFO|WARN|FAIL)
                fix="$(grep -m1 '^# @fix:' "${script}" 2>/dev/null | sed 's/^# @fix: //')"
                ;;
        esac
        printf '%s\t%s\n' "${line}" "${fix}"
    done
    return 0
}
