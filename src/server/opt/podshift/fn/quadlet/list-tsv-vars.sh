#!/usr/bin/env bash
# @file: list-tsv-vars.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Lists the ${TSV_NAME} variables used in a quadlet file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Finds each ${TSV_NAME} variable and ignores other variables and systemd specifiers.
# @details:
#   Finds each ${TSV_NAME} variable, where NAME is made of A-Z, 0-9 and _. Other variables ($VAR,
#   ${OTHER}) and systemd specifiers (%h, %n) are not PodShift's and are ignored.
# @arg: $1 - quadlet file.
# @stdout: the names (TSV_NAME, without ${ and }), each once, sorted, one per line. Nothing if none are used.
# @exitcode: 0 if the file was read (even if no variable is used), 1 if it cannot be read.
list-tsv-vars() {
    local file
    file="${1}"
    [[ -f "${file}" && -r "${file}" ]] || return 1
    { grep -Eo -- '\$\{TSV_[A-Z0-9_]+\}' "${file}" || true; } \
        | sed -e 's/^\${//' -e 's/}$//' \
        | LC_ALL=C sort -u
    return 0
}
