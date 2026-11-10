#!/usr/bin/env bash
# @file: cockpit-validate-contract.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Checks one JSON value against one contract with jq, recursing through nested properties and items.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks one JSON value against one contract.
# @details:
#   The supported keywords are type, properties, required, additionalProperties false, items, enum
#   and const. Any other keyword, or a supported keyword used in an unsupported shape, rejects the
#   contract. Nested properties and items are checked at every level. Defaults are not filled in.
# @arg: $1 - contract JSON.
# @arg: $2 - value JSON.
# @exitcode: 0 when the value matches, 1 when it does not, 2 when the contract is not in the supported subset or is not JSON.
cockpit-validate-contract() {
    local contract value result
    contract="${1-}"
    value="${2-}"
    if ! result="$(jq -n -r --argjson contract "${contract}" --argjson value "${value}" '
        def is_type_name:
            . == "object" or . == "array" or . == "string" or . == "integer"
            or . == "number" or . == "boolean" or . == "null";
        def schema_ok:
            type == "object"
            and ((keys - ["type","properties","required","additionalProperties","items","enum","const"]) | length == 0)
            and (if has("type") then ((.type | type) == "string" and (.type | is_type_name)) else true end)
            and (if has("properties") then ((.properties | type) == "object" and all(.properties[]; schema_ok)) else true end)
            and (if has("required") then ((.required | type) == "array" and all(.required[]; type == "string")) else true end)
            and (if has("additionalProperties") then .additionalProperties == false else true end)
            and (if has("items") then ((.items | type) == "object" and (.items | schema_ok)) else true end)
            and (if has("enum") then ((.enum | type) == "array") else true end);
        def is_integer:
            type == "number" and isfinite and . == floor;
        def value_ok($s):
            . as $v
            | (if $s | has("type") then
                if $s.type == "object" then ($v | type) == "object"
                elif $s.type == "array" then ($v | type) == "array"
                elif $s.type == "string" then ($v | type) == "string"
                elif $s.type == "boolean" then ($v | type) == "boolean"
                elif $s.type == "null" then $v == null
                elif $s.type == "number" then ($v | type) == "number"
                elif $s.type == "integer" then ($v | is_integer)
                else false end
              else true end)
            and (if $s | has("const") then $v == $s.const else true end)
            and (if $s | has("enum") then any($s.enum[]; . == $v) else true end)
            and (if (($s | has("properties")) or ($s | has("required")) or ($s | has("additionalProperties"))) then
                  ($v | type) == "object"
                  and (if $s | has("required") then reduce $s.required[] as $k (true; . and ($v | has($k))) else true end)
                  and (if (($s | has("additionalProperties")) and ($s.additionalProperties == false)) then
                        reduce ($v | keys[]) as $k (true; . and ((($s.properties // {}) | has($k))))
                      else true end)
                  and (reduce ($v | keys[]) as $k (true;
                        . and (if (($s.properties // {}) | has($k)) then ($v[$k] | value_ok($s.properties[$k])) else true end)))
                else true end)
            and (if $s | has("items") then
                  ($v | type) == "array"
                  and (reduce $v[] as $item (true; . and ($item | value_ok($s.items))))
                else true end);
        if ($contract | schema_ok | not) then "bad-contract"
        elif ($value | value_ok($contract)) then "ok"
        else "mismatch" end
    ' 2>/dev/null)"; then
        return 2
    fi
    case "${result}" in
        ok) return 0 ;;
        mismatch) return 1 ;;
        *) return 2 ;;
    esac
}
