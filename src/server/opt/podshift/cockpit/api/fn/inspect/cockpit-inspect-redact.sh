#!/usr/bin/env bash
# @file: cockpit-inspect-redact.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/inspect
# @dest-dir: /opt/podshift/cockpit/api/fn/inspect
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Removes secret values from podman inspect JSON before the inspect action returns or writes it.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints podman inspect JSON with SecretData removed from every secret object.
# @details:
#   The inspect module never passes --showsecret, so podman secret inspect prints no SecretData.
#   This is a second guard: for kind secret, SecretData is deleted from every object of the
#   array, at any depth. Other kinds are printed unchanged, compact.
# @arg: $1 - kind: container, image, volume, network or secret.
# @arg: $2 - JSON array from podman <kind> inspect.
# @stdout: the JSON array, compact.
# @exitcode: 0 when the array was written, 1 when the input is not a JSON array or the kind is empty.
cockpit-inspect-redact() {
    local kind raw
    kind="${1-}"
    raw="${2-}"
    [[ -n "${kind}" && -n "${raw}" ]] || return 1
    printf '%s' "${raw}" | jq -c -e --arg kind "${kind}" '
        if type != "array" then error("not an array")
        elif $kind == "secret" then walk(if type == "object" then del(.SecretData) else . end)
        else . end
    ' 2>/dev/null || return 1
}
