#!/usr/bin/env bash
# @file: cockpit-config-arg.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/config
# @dest-dir: /opt/podshift/cockpit/api/fn/config
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Prints one string argument of a config action, with any control character marked.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints a string field of the action arguments, or a single \x01 when it has a control character.
# @details:
#   Shell command substitution drops trailing newlines and Bash cannot hold a NUL byte, so a
#   value with control characters could reach the checks changed. Any such value is printed as
#   one \x01 character instead, which the name and value checks then refuse. The input contract
#   has already checked that the field is a string.
# @arg: $1 - action arguments as one JSON object.
# @arg: $2 - field name, for example key or value.
# @stdout: the field text, or \x01.
# @exitcode: 0 when the field is a string, 1 otherwise.
cockpit-config-arg() {
    local args name
    args="${1-}"
    name="${2-}"
    printf '%s' "${args}" | jq -j --arg name "${name}" '
        .[$name]
        | if type != "string" then halt_error(1)
          elif (explode | any(. < 32 or . == 127)) then "\u0001"
          else . end
    ' 2>/dev/null
}
