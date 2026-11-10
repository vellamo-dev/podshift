#!/usr/bin/env bash
# @file: cockpit-validate-envelope.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Checks the shared request envelope: one JSON object with apiVersion, action and an args object, and no unknown fields.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks one raw request body and always prints a decision.
# @details:
#   Malformed JSON, repeated values, the wrong shape and unknown fields are INVALID_REQUEST. A
#   numeric apiVersion other than 1 is UNSUPPORTED_VERSION. It does not decide whether the action
#   name is known.
# @arg: $1 - the raw request body.
# @stdout: one JSON object with code, and action plus args when the envelope shape is accepted.
# @exitcode: 0 when a decision object was written, 1 when jq could not be run.
cockpit-validate-envelope() {
    local raw result
    raw="${1-}"
    if ! result="$(printf '%s' "${raw}" | jq -c -s '
        if length != 1 then {code:"INVALID_REQUEST"}
        elif (.[0] | type) != "object" then {code:"INVALID_REQUEST"}
        else
            .[0] as $o
            | if (($o | keys) - ["apiVersion","action","args"] | length) != 0 then {code:"INVALID_REQUEST"}
              elif (["apiVersion","action","args"] - ($o | keys) | length) != 0 then {code:"INVALID_REQUEST"}
              elif ($o.apiVersion | type) != "number" then {code:"INVALID_REQUEST"}
              elif ($o.action | type) != "string" then {code:"INVALID_REQUEST"}
              elif ($o.args | type) != "object" then {code:"INVALID_REQUEST"}
              elif $o.apiVersion != 1 then {code:"UNSUPPORTED_VERSION"}
              else {code:"OK", action:$o.action, args:$o.args}
              end
        end
    ' 2>/dev/null)"; then
        printf '%s\n' '{"code":"INVALID_REQUEST"}'
        return 0
    fi
    if [[ -z "${result}" ]]; then
        printf '%s\n' '{"code":"INVALID_REQUEST"}'
        return 0
    fi
    printf '%s\n' "${result}"
    return 0
}
