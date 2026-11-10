#!/usr/bin/env bash
# @file: cockpit-write-response.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Builds the standard JSON response envelope with jq, using the existing podshift-version rule for the product version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_2C4B298360B3:-}" ]]; then
    DIR_2C4B298360B3="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_2C4B298360B3
fi

# @description: Prints one response envelope.
# @details:
#   The product version comes from get-podshift-version. Request and data are inserted as JSON
#   values. An empty request or data argument becomes null.
# @arg: $1 - status code.
# @arg: $2 - status message.
# @arg: $3 - request JSON, or empty for null.
# @arg: $4 - data JSON, or empty for null.
# @stdout: one JSON object.
# @exitcode: 0 when the envelope was written, 1 when the version or the envelope could not be built.
cockpit-write-response() {
    local code message request_json data_json version
    code="${1:-}"
    message="${2-}"
    request_json="${3-}"
    data_json="${4-}"
    [[ -n "${request_json}" ]] || request_json="null"
    [[ -n "${data_json}" ]] || data_json="null"
    # shellcheck source=../../../fn/common/get-podshift-version.sh
    declare -F get-podshift-version >/dev/null || source "${DIR_2C4B298360B3}/../../../fn/common/get-podshift-version.sh"
    version="$(get-podshift-version)" || return 1
    jq -n -c \
        --arg version "${version}" \
        --arg code "${code}" \
        --arg message "${message}" \
        --argjson request "${request_json}" \
        --argjson data "${data_json}" \
        '{
            podshift: {version: $version, apiVersion: 1},
            request: $request,
            status: {ok: ($code == "OK"), code: $code, message: $message},
            data: $data
        }'
}
