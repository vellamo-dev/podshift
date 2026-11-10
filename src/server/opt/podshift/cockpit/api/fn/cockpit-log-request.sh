#!/usr/bin/env bash
# @file: cockpit-log-request.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Records safe request metadata (action, result code, duration) in the journal under the podshift-api tag.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3B7DC3D0F3C8:-}" ]]; then
    DIR_3B7DC3D0F3C8="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3B7DC3D0F3C8
fi

# @description: Writes one journal line with the action, result code and duration in milliseconds.
# @details:
#   The action is a matched dispatch entry or a fixed marker, and the code is a known result code.
#   Caller text that is neither is replaced before it is logged.
# @arg: $1 - matched action name, or a fixed marker: not-root, invalid-request, unknown-action.
# @arg: $2 - result code.
# @arg: $3 - duration in milliseconds.
# @exitcode: 0 when the line was handed to logger, 1 when logger is missing or fails. The caller reports a logging failure. This function does not write the response.
cockpit-log-request() {
    local action code duration_ms safe_action safe_code resolved canonical
    action="${1:-}"
    code="${2:-}"
    duration_ms="${3:-}"
    safe_action="invalid-request"
    case "${action}" in
        not-root|invalid-request|unknown-action)
            safe_action="${action}"
            ;;
        *)
            # shellcheck source=./cockpit-dispatch-action.sh
            declare -F cockpit-dispatch-action >/dev/null || source "${DIR_3B7DC3D0F3C8}/cockpit-dispatch-action.sh"
            if resolved="$(cockpit-dispatch-action lookup "${action}" 2>/dev/null)"; then
                canonical="$(printf '%s' "${resolved}" | jq -r '.action' 2>/dev/null || true)"
                case "${canonical}" in
                    ''|*[!abcdefghijklmnopqrstuvwxyz0123456789-]*)
                        safe_action="unknown-action"
                        ;;
                    *)
                        safe_action="${canonical}"
                        ;;
                esac
            else
                safe_action="unknown-action"
            fi
            ;;
    esac
    case "${code}" in
        OK|INVALID_REQUEST|UNSUPPORTED_VERSION|UNKNOWN_ACTION|INVALID_ARGS|NOT_ROOT|REALM_UNAVAILABLE|INTERNAL|ACTION_RETIRED)
            safe_code="${code}"
            ;;
        *)
            safe_code="INTERNAL"
            ;;
    esac
    case "${duration_ms}" in
        ''|*[!0123456789]*) duration_ms=0 ;;
    esac
    command -v logger >/dev/null 2>&1 || return 1
    logger -t podshift-api "action=${safe_action} code=${safe_code} duration_ms=${duration_ms}" || return 1
    return 0
}
