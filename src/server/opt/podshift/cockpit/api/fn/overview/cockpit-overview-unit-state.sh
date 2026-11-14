#!/usr/bin/env bash
# @file: cockpit-overview-unit-state.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Maps a systemd ActiveState and SubState to a final overview status label.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the display label for one unit from its ActiveState and SubState.
# @details:
#   The label is the text shown in the UI, with no further conversion. Failed, Starting,
#   Stopping and Reloading follow ActiveState. An active unit is Waiting, Exited or Running
#   from its SubState (waiting stays Waiting; exited stays Exited; listening and other
#   active substates are Running). An inactive unit is Stopped. Unknown or empty states
#   fail so the caller can store null.
# @arg: $1 - systemd ActiveState, for example active, inactive or failed.
# @arg: $2 - systemd SubState, for example running, waiting, listening or exited.
# @stdout: one label, such as Running, Waiting, Exited, Stopped or Failed.
# @exitcode: 0 when a label was printed, 1 when the state is empty or not recognised.
cockpit-overview-unit-state() {
    local active sub
    active="${1-}"
    sub="${2-}"
    case "${active}" in
        failed)
            printf 'Failed\n'
            ;;
        activating)
            printf 'Starting\n'
            ;;
        deactivating)
            printf 'Stopping\n'
            ;;
        reloading)
            printf 'Reloading\n'
            ;;
        inactive)
            printf 'Stopped\n'
            ;;
        active)
            case "${sub}" in
                waiting)
                    printf 'Waiting\n'
                    ;;
                exited)
                    printf 'Exited\n'
                    ;;
                *)
                    printf 'Running\n'
                    ;;
            esac
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}

# @description: Prints the display label for a unit from systemctl show output.
# @details:
#   Reads LoadState, ActiveState and SubState from the text. A missing unit
#   (LoadState not-found) or empty text fails so the caller can store null.
# @arg: $1 - optional systemctl show text; when omitted, the text is read from stdin.
# @stdout: one label, such as Running or Stopped.
# @exitcode: 0 when a label was printed, 1 when the unit is missing or the state is unknown.
cockpit-overview-unit-state-from-show() {
    local raw load active sub
    raw="${1-}"
    if [[ -z "${raw}" ]]; then
        raw="$(cat)"
    fi
    [[ -n "${raw}" ]] || return 1
    load="$(printf '%s\n' "${raw}" | awk -F= '$1=="LoadState" { print $2; exit }')"
    active="$(printf '%s\n' "${raw}" | awk -F= '$1=="ActiveState" { print $2; exit }')"
    sub="$(printf '%s\n' "${raw}" | awk -F= '$1=="SubState" { print $2; exit }')"
    case "${load}" in
        not-found|'')
            return 1
            ;;
    esac
    cockpit-overview-unit-state "${active}" "${sub}"
}
