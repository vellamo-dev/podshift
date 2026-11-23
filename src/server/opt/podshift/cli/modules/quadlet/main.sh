#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/quadlet
# @dest-dir: /opt/podshift/cli/modules/quadlet
# @host-edit: no
# @group: cli
# @category: entry
# @description: Removes an installed quadlet file or app of the podshift user.
# @details:
#   Runs as the podshift user; root uses `sudo -u podshift -i podshift quadlet rm <name>`.
# @run-as: podshift
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Dispatches the quadlet subcommands.
# @arg: $@ - subcommand and its arguments: rm <file|app> [--volumes] [--yes], or --help.
# @stderr: errors for an unknown subcommand.
# @exitcode: 0 on success, 1 on failure.
podshift-quadlet() {
    case "${1:-}" in
        rm) shift; podshift-quadlet-rm "$@" ;;
        --help|-h)
            # shellcheck source=../../../fn/common/podshift-help.sh
            declare -F podshift-help >/dev/null || source /opt/podshift/fn/common/podshift-help.sh
            podshift-help quadlet
            ;;
        "") echo "No subcommand given. See 'podshift quadlet --help'." >&2; return 1 ;;
        *) echo "Unknown quadlet subcommand: ${1}. See 'podshift quadlet --help'." >&2; return 1 ;;
    esac
}

# @description: Removes one installed quadlet file or app with remove-item, after a confirmation.
# @details:
#   A name with a quadlet extension (web.container) is a single file, any other name an app (the
#   zip name without .zip). It is refused while another quadlet or container uses it. Podman
#   volumes are kept unless --volumes is given. --yes skips the question.
# @arg: $@ - name, then optional --volumes and --yes.
# @stdout: the result.
# @stderr: the reason when the removal is refused or fails.
# @exitcode: 0 if removed or not confirmed, 1 otherwise.
podshift-quadlet-rm() {
    local name volumes yes answer reason rc
    name=""
    volumes=0
    yes=0
    while (( $# > 0 )); do
        case "${1}" in
            --volumes) volumes=1 ;;
            --yes|-y) yes=1 ;;
            -*) echo "Unknown option: ${1}" >&2; return 1 ;;
            *)
                if [[ -n "${name}" ]]; then
                    echo "Only one name can be removed at a time." >&2
                    return 1
                fi
                name="${1}"
                ;;
        esac
        shift
    done
    if [[ -z "${name}" ]]; then
        echo "No name given. Usage: podshift quadlet rm <file|app> [--volumes] [--yes]" >&2
        return 1
    fi

    # shellcheck source=../../../fn/utils/require-podshift.sh
    declare -F require-podshift >/dev/null || source /opt/podshift/fn/utils/require-podshift.sh
    require-podshift || return 1
    # shellcheck source=../../../fn/rootless/load-rootless-conf.sh
    declare -F load-rootless-conf >/dev/null || source /opt/podshift/fn/rootless/load-rootless-conf.sh || return 1
    load-rootless-conf || return 1
    # shellcheck source=../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source /opt/podshift/fn/load-podshift-conf-main.sh
    load-podshift-conf-main
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" || -z "${PODSHIFT_QUADLET_STOP_TIMEOUT:-}" ]]; then
        echo "PODSHIFT_PODMAN_QUADLETS_DIR or PODSHIFT_QUADLET_STOP_TIMEOUT is not set" >&2
        return 1
    fi

    if (( yes == 0 )); then
        if (( volumes == 1 )); then
            read -rp "Remove ${name} and its volumes? [y/N] " answer
        else
            read -rp "Remove ${name}? [y/N] " answer
        fi
        if [[ "${answer}" != "y" && "${answer}" != "Y" ]]; then
            echo "Not removed."
            return 0
        fi
    fi

    # shellcheck source=../../../fn/quadlet/remove-item.sh
    declare -F remove-item >/dev/null || source /opt/podshift/fn/quadlet/remove-item.sh
    reason="$(remove-item "${name}" "${PODSHIFT_PODMAN_QUADLETS_DIR}" "${volumes}" "${PODSHIFT_QUADLET_STOP_TIMEOUT}")" && rc=0 || rc=$?
    if (( rc == 0 )); then
        echo "Removed ${name}."
        return 0
    fi
    echo "${name} was not removed: ${reason}" >&2
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    podshift-quadlet "$@"
fi
