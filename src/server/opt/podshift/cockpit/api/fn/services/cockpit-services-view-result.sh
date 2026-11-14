#!/usr/bin/env bash
# @file: cockpit-services-view-result.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/services
# @dest-dir: /opt/podshift/cockpit/api/fn/services
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the service-view action data from the text of systemctl cat or systemctl status.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints {unit, mode, found, text}, a not-found result or a too-large result.
# @details:
#   With found no, the result is {unit, mode, found: false} and stdin is not read. Otherwise the
#   text is read from stdin as is. When the compact result line, newline included, is longer than
#   the byte limit, text is left out and tooLarge is true, with size set to the bytes of the text.
# @arg: $1 - unit name.
# @arg: $2 - mode: unit or status.
# @arg: $3 - yes when the unit was found, no otherwise.
# @arg: $4 - byte limit of the result line, for example 131072.
# @stdout: one JSON object.
# @exitcode: 0 when the object was written, 1 when an argument is missing or the limit is not a number.
cockpit-services-view-result() {
    local unit mode found limit text out bytes size
    unit="${1-}"
    mode="${2-}"
    found="${3-}"
    limit="${4-}"
    [[ -n "${unit}" && -n "${mode}" ]] || return 1
    [[ "${limit}" =~ ^[0-9]+$ ]] || return 1
    if [[ "${found}" != "yes" ]]; then
        jq -n -c --arg unit "${unit}" --arg mode "${mode}" '{unit: $unit, mode: $mode, found: false}'
        return
    fi
    # The x keeps trailing newlines of the text.
    text="$(cat; printf x)"
    text="${text%x}"
    out="$(printf '%s' "${text}" | jq -R -s -c --arg unit "${unit}" --arg mode "${mode}" '{unit: $unit, mode: $mode, found: true, text: .}' 2>/dev/null)" || return 1
    bytes="$(printf '%s\n' "${out}" | LC_ALL=C wc -c | tr -d '[:space:]')"
    if (( bytes <= limit )); then
        printf '%s\n' "${out}"
        return 0
    fi
    size="$(printf '%s' "${text}" | LC_ALL=C wc -c | tr -d '[:space:]')"
    jq -n -c --arg unit "${unit}" --arg mode "${mode}" --argjson size "${size}" \
        '{unit: $unit, mode: $mode, found: true, tooLarge: true, size: $size}'
}
