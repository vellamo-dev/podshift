#!/usr/bin/env bash
# @file: is-tsv-var-used.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Tells if a quadlet file uses any ${TSV_NAME} variable.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the file for a ${TSV_NAME} variable and ignores other variables and systemd specifiers.
# @details:
#   Checks for a ${TSV_NAME} variable, where NAME is made of A-Z, 0-9 and _. Other variables ($VAR,
#   ${OTHER}) and systemd specifiers (%h, %n) are not PodShift's and are ignored.
# @arg: $1 - quadlet file.
# @stdout: nothing.
# @exitcode: 0 if the file contains at least one ${TSV_NAME}, 1 if not or if the file cannot be read.
is-tsv-var-used() {
    local file
    file="${1}"
    [[ -f "${file}" && -r "${file}" ]] || return 1
    grep -Eq -- '\$\{TSV_[A-Z0-9_]+\}' "${file}"
}
