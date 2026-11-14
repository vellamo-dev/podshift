#!/usr/bin/env bash
# @file: cockpit-inspect-args.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/inspect
# @dest-dir: /opt/podshift/cockpit/api/fn/inspect
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Checks the kind, ref and mode arguments of the inspect action and prints them.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the kind, ref and mode of an inspect request, or refuses them.
# @details:
#   kind must be container, image, volume, network or secret. ref must be 1 to 256 characters of letters,
#   digits and . : / @ _ -, and must not start with -. mode is optional and can only be file. The
#   input contract already checks the same, so this is a second check right before podman runs.
# @arg: $1 - action arguments as one JSON object, for example {"kind":"volume","ref":"pgdata"}.
# @stdout: kind, a tab, ref, a tab and mode (empty when not given).
# @exitcode: 0 when all are accepted, 1 otherwise.
cockpit-inspect-args() {
    local args kind ref mode
    args="${1-}"
    # jq -j prints no newline. The x printed after it keeps a trailing newline from being cut off.
    kind="$(printf '%s' "${args}" | jq -j 'if type == "object" and (.kind | type) == "string" then .kind else "" end' 2>/dev/null && printf x)" || return 1
    kind="${kind%x}"
    ref="$(printf '%s' "${args}" | jq -j 'if type == "object" and (.ref | type) == "string" then .ref else "" end' 2>/dev/null && printf x)" || return 1
    ref="${ref%x}"
    mode="$(printf '%s' "${args}" | jq -j 'if type != "object" then "?" elif has("mode") | not then "" elif (.mode | type) == "string" then .mode else "?" end' 2>/dev/null && printf x)" || return 1
    mode="${mode%x}"
    case "${kind}" in
        container|image|volume|network|secret) ;;
        *) return 1 ;;
    esac
    [[ -n "${ref}" && "${#ref}" -le 256 ]] || return 1
    case "${ref}" in
        -*) return 1 ;;
        *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789._:/@-]*) return 1 ;;
    esac
    case "${mode}" in
        ''|file) ;;
        *) return 1 ;;
    esac
    printf '%s\t%s\t%s\n' "${kind}" "${ref}" "${mode}"
    return 0
}
