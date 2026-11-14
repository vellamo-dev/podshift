#!/usr/bin/env bash
# @file: cockpit-quadlet-view-result.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/quadlets
# @dest-dir: /opt/podshift/cockpit/api/fn/quadlets
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the quadlet-view action data from the state, the path and the file text.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the quadlet-view result: the file, an error, a not-found or a too-large result.
# @details:
#   State missing gives {unit, found: false}. NOT_QUADLET gives {unit, found: true, quadlet: false,
#   error}. FILE_NOT_FOUND, OUTSIDE_QUADLET_DIR and FILE_UNREADABLE give {unit, found: true,
#   quadlet: true, error, name, path, kind}. State ok reads the file text from stdin as is and
#   gives {unit, found: true, quadlet: true, name, path, kind, text}. name is the last part of the
#   path. When that compact line, newline included, is longer than the byte limit, text is left
#   out and tooLarge is true, with size set to the bytes of the text. stdin is read only for ok.
# @arg: $1 - unit name.
# @arg: $2 - state: ok, missing, NOT_QUADLET, FILE_NOT_FOUND, OUTSIDE_QUADLET_DIR or FILE_UNREADABLE.
# @arg: $3 - path of the Quadlet file; needed for ok and the file errors.
# @arg: $4 - Quadlet kind, for example container; needed for ok and the file errors.
# @arg: $5 - byte limit of the result line, for example 131072.
# @stdout: one JSON object.
# @exitcode: 0 when the object was written, 1 when an argument is missing or wrong.
cockpit-quadlet-view-result() {
    local unit state path kind limit text out bytes size
    unit="${1-}"
    state="${2-}"
    path="${3-}"
    kind="${4-}"
    limit="${5-}"
    [[ -n "${unit}" ]] || return 1
    [[ "${limit}" =~ ^[0-9]+$ ]] || return 1
    case "${state}" in
        missing)
            jq -n -c --arg unit "${unit}" '{unit: $unit, found: false}'
            return
            ;;
        NOT_QUADLET)
            jq -n -c --arg unit "${unit}" '{unit: $unit, found: true, quadlet: false, error: "NOT_QUADLET"}'
            return
            ;;
        ok|FILE_NOT_FOUND|OUTSIDE_QUADLET_DIR|FILE_UNREADABLE) ;;
        *) return 1 ;;
    esac
    [[ -n "${path}" && "${path##*/}" != "" && -n "${kind}" ]] || return 1
    if [[ "${state}" != "ok" ]]; then
        jq -n -c --arg unit "${unit}" --arg error "${state}" --arg path "${path}" --arg kind "${kind}" \
            '{unit: $unit, found: true, quadlet: true, error: $error, name: ($path | split("/") | last), path: $path, kind: $kind}'
        return
    fi
    # The x keeps trailing newlines of the text.
    text="$(cat; printf x)"
    text="${text%x}"
    out="$(printf '%s' "${text}" | jq -R -s -c --arg unit "${unit}" --arg path "${path}" --arg kind "${kind}" \
        '{unit: $unit, found: true, quadlet: true, name: ($path | split("/") | last), path: $path, kind: $kind, text: .}' 2>/dev/null)" || return 1
    bytes="$(printf '%s\n' "${out}" | LC_ALL=C wc -c | tr -d '[:space:]')"
    if (( bytes <= limit )); then
        printf '%s\n' "${out}"
        return 0
    fi
    size="$(printf '%s' "${text}" | LC_ALL=C wc -c | tr -d '[:space:]')"
    jq -n -c --arg unit "${unit}" --arg path "${path}" --arg kind "${kind}" --argjson size "${size}" \
        '{unit: $unit, found: true, quadlet: true, name: ($path | split("/") | last), path: $path, kind: $kind, tooLarge: true, size: $size}'
}
