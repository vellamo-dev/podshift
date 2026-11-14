#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cockpit/api
# @dest-dir: /opt/podshift/cockpit/api
# @host-edit: no
# @group: cockpit
# @category: entry
# @description: Cockpit API entry: reads one JSON request from stdin and writes one JSON response.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_79C489F39EE5:-}" ]]; then
    DIR_79C489F39EE5="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_79C489F39EE5
fi

# @description: Prints the current time in milliseconds, for the journal duration.
# @stdout: milliseconds since the epoch.
# @exitcode: 0 always.
cockpit-now-ms() {
    local raw
    raw="$(date +%s%3N 2>/dev/null || true)"
    case "${raw}" in
        ''|*[!0123456789]*)
            raw="$(date +%s 2>/dev/null || printf '0')"
            printf '%s000\n' "${raw}"
            ;;
        *)
            printf '%s\n' "${raw}"
            ;;
    esac
    return 0
}

# @description: Writes one response envelope and then one safe journal line.
# @details:
#   A logging failure is reported on stderr and does not change the response.
# @arg: $1 - status code.
# @arg: $2 - status message.
# @arg: $3 - request JSON, or empty for null.
# @arg: $4 - data JSON, or empty for null.
# @arg: $5 - log action or fixed marker.
# @arg: $6 - start time in milliseconds.
# @stdout: one JSON response.
# @stderr: a fixed note when the response or the journal write fails.
# @exitcode: 0 when the envelope was written, 1 when it was not.
cockpit-finish() {
    local code message request_json data_json log_action start_ms now_ms duration_ms
    code="${1:-}"
    message="${2-}"
    request_json="${3-}"
    data_json="${4-}"
    log_action="${5:-invalid-request}"
    start_ms="${6:-0}"
    # shellcheck source=fn/cockpit-write-response.sh
    declare -F cockpit-write-response >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-write-response.sh"
    # shellcheck source=fn/cockpit-log-request.sh
    declare -F cockpit-log-request >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-log-request.sh"
    if ! cockpit-write-response "${code}" "${message}" "${request_json}" "${data_json}"; then
        printf 'podshift-api: could not write the response\n' >&2
        return 1
    fi
    now_ms="$(cockpit-now-ms)"
    duration_ms=$((now_ms - start_ms))
    if (( duration_ms < 0 )); then
        duration_ms=0
    fi
    cockpit-log-request "${log_action}" "${code}" "${duration_ms}" || printf 'podshift-api: journal logging failed\n' >&2
    return 0
}

# @description: Handles one request after the root check and writes one response envelope.
# @details:
#   Reads stdin, checks the envelope, capability metadata and contracts, and runs the module.
# @arg: $1 - start time in milliseconds.
# @stdout: one JSON response.
# @exitcode: 0 when the envelope was written, 1 when it was not.
cockpit-serve() {
    local start_ms body read_rc parsed code action args_json dispatch_json
    local canonical fn_name module_dir cap_json cap_rc input_contract output_contract
    local contract_rc data run_rc out_rc request_json message failing
    start_ms="${1:-0}"
    # shellcheck source=fn/cockpit-read-request.sh
    declare -F cockpit-read-request >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-read-request.sh"
    # shellcheck source=fn/cockpit-validate-envelope.sh
    declare -F cockpit-validate-envelope >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-validate-envelope.sh"
    # shellcheck source=fn/cockpit-dispatch-action.sh
    declare -F cockpit-dispatch-action >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-dispatch-action.sh"
    # shellcheck source=fn/cockpit-load-capability.sh
    declare -F cockpit-load-capability >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-load-capability.sh"
    # shellcheck source=fn/cockpit-validate-capability.sh
    declare -F cockpit-validate-capability >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-validate-capability.sh"
    # shellcheck source=fn/cockpit-validate-contract.sh
    declare -F cockpit-validate-contract >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-validate-contract.sh"
    # shellcheck source=fn/cockpit-run-module.sh
    declare -F cockpit-run-module >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-run-module.sh"

    body="$(cockpit-read-request)" && read_rc=0 || read_rc=$?
    if [[ "${read_rc}" -ne 0 ]]; then
        cockpit-finish "INVALID_REQUEST" "The request must be one JSON object with apiVersion, action and args." "" "" "invalid-request" "${start_ms}"
        return $?
    fi
    parsed="$(cockpit-validate-envelope "${body}")" || parsed='{"code":"INVALID_REQUEST"}'
    code="$(printf '%s' "${parsed}" | jq -r '.code' 2>/dev/null || printf 'INVALID_REQUEST')"
    case "${code}" in
        OK) ;;
        UNSUPPORTED_VERSION)
            cockpit-finish "UNSUPPORTED_VERSION" "apiVersion 1 is the only supported version." "" "" "invalid-request" "${start_ms}"
            return $?
            ;;
        *)
            cockpit-finish "INVALID_REQUEST" "The request must be one JSON object with apiVersion, action and args." "" "" "invalid-request" "${start_ms}"
            return $?
            ;;
    esac
    action="$(printf '%s' "${parsed}" | jq -r '.action')" || action=""
    args_json="$(printf '%s' "${parsed}" | jq -c '.args')" || args_json="null"
    if ! dispatch_json="$(cockpit-dispatch-action lookup "${action}" 2>/dev/null)"; then
        cockpit-finish "UNKNOWN_ACTION" "The action is not recognised." "" "" "unknown-action" "${start_ms}"
        return $?
    fi
    canonical="$(printf '%s' "${dispatch_json}" | jq -r '.action')" || canonical=""
    if [[ -z "${canonical}" || "${canonical}" != "${action}" ]]; then
        cockpit-finish "INTERNAL" "The handler could not complete the action." "" "" "invalid-request" "${start_ms}"
        return $?
    fi
    fn_name="$(printf '%s' "${dispatch_json}" | jq -r '.function')" || fn_name=""
    module_dir="$(printf '%s' "${dispatch_json}" | jq -r '.directory')" || module_dir=""
    request_json="$(jq -n -c --arg action "${canonical}" '{action:$action, args:null}')" || request_json="null"
    if ! cap_json="$(cockpit-load-capability "${module_dir}")"; then
        cockpit-finish "INTERNAL" "The action metadata is missing or invalid." "${request_json}" "" "${canonical}" "${start_ms}"
        return $?
    fi
    cockpit-validate-capability "${canonical}" "${cap_json}" && cap_rc=0 || cap_rc=$?
    if [[ "${cap_rc}" -eq 2 ]]; then
        cockpit-finish "ACTION_RETIRED" "This action is retired and no longer runs." "${request_json}" "" "${canonical}" "${start_ms}"
        return $?
    fi
    if [[ "${cap_rc}" -ne 0 ]]; then
        cockpit-finish "INTERNAL" "The action metadata is missing or invalid." "${request_json}" "" "${canonical}" "${start_ms}"
        return $?
    fi
    input_contract="$(printf '%s' "${cap_json}" | jq -c '.input')" || input_contract=""
    cockpit-validate-contract "${input_contract}" "${args_json}" && contract_rc=0 || contract_rc=$?
    if [[ "${contract_rc}" -ne 0 ]]; then
        # shellcheck source=fn/cockpit-contract-failing-args.sh
        declare -F cockpit-contract-failing-args >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-contract-failing-args.sh"
        failing="$(cockpit-contract-failing-args "${input_contract}" "${args_json}" 2>/dev/null)" || failing=""
        if [[ -n "${failing}" ]]; then
            message="Given arguments are not supported: ${failing}."
        else
            message="Given arguments are not supported."
        fi
        cockpit-finish "INVALID_ARGS" "${message}" "${request_json}" "" "${canonical}" "${start_ms}"
        return $?
    fi
    request_json="$(jq -n -c --arg action "${canonical}" --argjson args "${args_json}" '{action:$action, args:$args}')" || request_json="null"
    data="$(cockpit-run-module "${canonical}" "${args_json}")" && run_rc=0 || run_rc=$?
    if [[ "${run_rc}" -eq 10 ]]; then
        cockpit-finish "REALM_UNAVAILABLE" "The podshift session could not be entered. Check that the podshift user is logged in and linger is enabled." "${request_json}" "" "${canonical}" "${start_ms}"
        return $?
    fi
    if [[ "${run_rc}" -ne 0 ]]; then
        cockpit-finish "INTERNAL" "The handler could not complete the action." "${request_json}" "" "${canonical}" "${start_ms}"
        return $?
    fi
    output_contract="$(printf '%s' "${cap_json}" | jq -c '.output')" || output_contract=""
    cockpit-validate-contract "${output_contract}" "${data}" && out_rc=0 || out_rc=$?
    if [[ "${out_rc}" -ne 0 ]]; then
        cockpit-finish "INTERNAL" "The handler could not complete the action." "${request_json}" "" "${canonical}" "${start_ms}"
        return $?
    fi
    if [[ "${canonical}" == "ping" ]]; then
        message="Ping completed"
    else
        message="Action completed"
    fi
    # fn_name is resolved so a root-realm module and the session script use the same map entry.
    [[ -n "${fn_name}" ]] || {
        cockpit-finish "INTERNAL" "The handler could not complete the action." "${request_json}" "" "${canonical}" "${start_ms}"
        return $?
    }
    cockpit-finish "OK" "${message}" "${request_json}" "${data}" "${canonical}" "${start_ms}"
    return $?
}

# @description: Refuses a process that is not root before stdin is read, then handles one request.
# @stdout: one JSON response when an envelope can be written.
# @stderr: a fixed note when jq is missing or the envelope cannot be written.
# @exitcode: 0 when the envelope was written, including errors, 1 when it was not.
cockpit-main() {
    local start_ms
    if ! command -v jq >/dev/null 2>&1; then
        printf 'podshift-api: jq is required to write a response\n' >&2
        return 1
    fi
    start_ms="$(cockpit-now-ms)"
    if [[ "${EUID}" -ne 0 ]]; then
        # shellcheck source=fn/cockpit-write-response.sh
        declare -F cockpit-write-response >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-write-response.sh"
        # shellcheck source=fn/cockpit-log-request.sh
        declare -F cockpit-log-request >/dev/null || source "${DIR_79C489F39EE5}/fn/cockpit-log-request.sh"
        cockpit-finish "NOT_ROOT" "Start this program as root. In Cockpit, authorize the administrative action so the handler is started with superuser require." "" "" "not-root" "${start_ms}"
        return $?
    fi
    cockpit-serve "${start_ms}"
    return $?
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
    cockpit-main "$@"
fi
