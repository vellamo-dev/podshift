#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/network
# @dest-dir: /opt/podshift/cli/modules/network
# @host-edit: no
# @group: cli
# @category: entry
# @description: Examines, prints, checks, sets, fixes, and reloads the host's external network.
# @run-as: any
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_B3898190C001:-}" ]]; then
    DIR_B3898190C001="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_B3898190C001
fi

# @description: Dispatches the network subcommands.
# @details:
#   Each subcommand is one function in fn/, loaded only when it runs. Network facts that other
#   parts of PodShift may use, such as nw-device or nw-list-devices, are in /opt/podshift/fn/network.
# @arg: $1 - optional subcommand (examine, print, check, set, fix, reload), or --help.
# @stderr: errors for an unknown subcommand.
# @exitcode: the exit code of the subcommand, 1 for an unknown one.
podshift-network() {
    case "${1:-}" in
        ""|examine)
            # shellcheck source=fn/podshift-network-examine.sh
            declare -F podshift-network-examine >/dev/null || source "${DIR_B3898190C001}/fn/podshift-network-examine.sh"
            shift; podshift-network-examine "$@"
            ;;
        print)
            # shellcheck source=fn/podshift-network-print.sh
            declare -F podshift-network-print >/dev/null || source "${DIR_B3898190C001}/fn/podshift-network-print.sh"
            podshift-network-print
            ;;
        check)
            # shellcheck source=fn/podshift-network-check.sh
            declare -F podshift-network-check >/dev/null || source "${DIR_B3898190C001}/fn/podshift-network-check.sh"
            podshift-network-check
            ;;
        set)
            # shellcheck source=fn/podshift-network-set.sh
            declare -F podshift-network-set >/dev/null || source "${DIR_B3898190C001}/fn/podshift-network-set.sh"
            shift; podshift-network-set "$@"
            ;;
        fix)
            # shellcheck source=fn/podshift-network-fix.sh
            declare -F podshift-network-fix >/dev/null || source "${DIR_B3898190C001}/fn/podshift-network-fix.sh"
            podshift-network-fix
            ;;
        reload)
            # shellcheck source=fn/podshift-network-reload.sh
            declare -F podshift-network-reload >/dev/null || source "${DIR_B3898190C001}/fn/podshift-network-reload.sh"
            podshift-network-reload
            ;;
        --help|-h)
            # shellcheck source=../../../fn/common/podshift-help.sh
            declare -F podshift-help >/dev/null || source "${DIR_B3898190C001}/../../../fn/common/podshift-help.sh"
            podshift-help network
            ;;
        *) echo "Unknown network subcommand: ${1}. See 'podshift network --help'." >&2; return 1 ;;
    esac
}

podshift-network "$@"
