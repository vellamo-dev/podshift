#!/usr/bin/env bash
# @file: cockpit-validate-capability.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Checks that capability metadata is well formed and agrees with the dispatch map.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_9BDC82826860:-}" ]]; then
    DIR_9BDC82826860="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_9BDC82826860
fi

# @description: Checks one capability document against the action name from the dispatch map.
# @details:
#   Input and output contracts must use only the supported vocabulary. A retired action is
#   recognised and is not treated as ready to run.
# @arg: $1 - action name from the dispatch map.
# @arg: $2 - capability.json text.
# @exitcode: 0 when status is active or deprecated, 2 when status is retired, 1 when the document is missing a field, has an unknown field, disagrees with the action, or has an invalid contract.
cockpit-validate-capability() {
    local expected raw decision input_contract output_contract schema_rc
    expected="${1:-}"
    raw="${2-}"
    # shellcheck source=./cockpit-validate-contract.sh
    declare -F cockpit-validate-contract >/dev/null || source "${DIR_9BDC82826860}/cockpit-validate-contract.sh"
    if ! decision="$(printf '%s' "${raw}" | jq -c -s --arg expected "${expected}" '
        if length != 1 then "invalid"
        elif (.[0] | type) != "object" then "invalid"
        else
            .[0] as $c
            | if (($c | keys) - ["action","name","description","status","input","output"] | length) != 0 then "invalid"
              elif (["action","name","description","status","input","output"] - ($c | keys) | length) != 0 then "invalid"
              elif ($c.action | type) != "string" or $c.action != $expected then "invalid"
              elif ($c.name | type) != "string" or ($c.name | length) < 1 then "invalid"
              elif ($c.description | type) != "string" or ($c.description | length) < 1 then "invalid"
              elif ($c.status != "active" and $c.status != "deprecated" and $c.status != "retired") then "invalid"
              elif ($c.input | type) != "object" or ($c.output | type) != "object" then "invalid"
              else $c.status end
        end
    ' 2>/dev/null)"; then
        return 1
    fi
    # jq -c -s prints a JSON string, including the quotes.
    case "${decision}" in
        '"active"'|'"deprecated"'|'"retired"') ;;
        *) return 1 ;;
    esac
    input_contract="$(printf '%s' "${raw}" | jq -c -s '.[0].input' 2>/dev/null)" || return 1
    output_contract="$(printf '%s' "${raw}" | jq -c -s '.[0].output' 2>/dev/null)" || return 1
    cockpit-validate-contract "${input_contract}" null && schema_rc=0 || schema_rc=$?
    [[ "${schema_rc}" -ne 2 ]] || return 1
    cockpit-validate-contract "${output_contract}" null && schema_rc=0 || schema_rc=$?
    [[ "${schema_rc}" -ne 2 ]] || return 1
    if [[ "${decision}" == '"retired"' ]]; then
        return 2
    fi
    return 0
}
