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

# @description: Writes one journal line with the action, result code and duration in milliseconds, plus a failure reason.
# @details:
#   The action is a matched dispatch entry or a fixed marker, and the code is a known result code.
#   Caller text that is neither is replaced before it is logged. A known reason (module, timeout,
#   size, output, realm, contract, metadata) is added as reason=<reason>; with a reason, a detail
#   such as the first stderr line of the module is added as detail=<text>: one line, bytes that are
#   not printable ASCII replaced by a space, cut to 200 characters. Callers pass only module stderr
#   as detail, never the request.
# @arg: $1 - matched action name, or a fixed marker: not-root, invalid-request, unknown-action.
# @arg: $2 - result code.
# @arg: $3 - duration in milliseconds.
# @arg: $4 - optional failure reason: module, timeout, size, output, realm, contract or metadata.
# @arg: $5 - optional detail, used only with a reason.
# @exitcode: 0 when the line was handed to logger, 1 when logger is missing or fails. The caller reports a logging failure. This function does not write the response.
cockpit-log-request() {
    local action code duration_ms reason detail safe_action safe_code resolved canonical line
    action="${1:-}"
    code="${2:-}"
    duration_ms="${3:-}"
    reason="${4:-}"
    detail="${5:-}"
    safe_action="invalid-request"
    case "${action}" in
        not-root|invalid-request|unknown-action)
            safe_action="${action}"
            ;;
        *)
            # shellcheck source=./cockpit-dispatch-action.sh
            declare -F cockpit-dispatch-action >/dev/null || source "${DIR_3B7DC3D0F3C8}/cockpit-dispatch-action.sh"
            if resolved="$(cockpit-dispatch-action fields "${action}" 2>/dev/null)"; then
                canonical="${resolved%%$'\t'*}"
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
    line="action=${safe_action} code=${safe_code} duration_ms=${duration_ms}"
    case "${reason}" in
        module|timeout|size|output|realm|contract|metadata) line+=" reason=${reason}" ;;
    esac
    if [[ "${line}" == *" reason="* && -n "${detail}" ]]; then
        detail="$(printf '%s' "${detail}" | head -n 1 | LC_ALL=C tr -c '[:print:]' ' ' | LC_ALL=C tr -s ' ' | sed -e 's/^ //' -e 's/ $//')"
        [[ -z "${detail}" ]] || line+=" detail=${detail:0:200}"
    fi
    command -v logger >/dev/null 2>&1 || return 1
    logger -t podshift-api "${line}" || return 1
    return 0
}
