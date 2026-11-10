#!/usr/bin/env bash
# @file: fill-tsv-vars.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Fills the ${TSV_NAME} variables of a quadlet file in place from a values file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Replaces each ${TSV_NAME} in the quadlet file with the value of the shell variable TSV_NAME.
# @details:
#   Replaces each ${TSV_NAME} in the quadlet file with the value of the shell variable TSV_NAME,
#   where NAME is made of A-Z, 0-9 and _. The caller loads the values first (tsv.conf,
#   runtime.conf, TSV_NW1..8). Nothing is evaluated: the value is read with indirect expansion,
#   only for names of that form. Values are inserted literally, so /, &, \, | and $ in a value are
#   safe, and an inserted value is not scanned again. A name that is unset or has an empty value is
#   left as is, so is-tsv-var-used can catch it afterwards. Other variables ($VAR, ${OTHER}) and
#   systemd specifiers (%h, %n) are not touched. The file is only rewritten if something changed.
# @arg: $1 - quadlet file, changed in place.
# @stdout: nothing.
# @exitcode: 0 on success (also when some names stay unfilled), 1 if no file is given, or it cannot be read or written.
fill-tsv-vars() {
    local file content rest out match name pre value re changed
    file="${1-}"
    [[ -n "${file}" && -f "${file}" && -r "${file}" && -w "${file}" ]] || return 1

    # Replace one match at a time, so the values are never used as a pattern.
    content="$(cat -- "${file}"; printf x)"
    content="${content%x}"
    rest="${content}"
    out=""
    changed=""
    re='\$\{(TSV_[A-Z0-9_]+)\}'
    while [[ "${rest}" =~ ${re} ]]; do
        match="${BASH_REMATCH[0]}"
        name="${BASH_REMATCH[1]}"
        pre="${rest%%"${match}"*}"
        rest="${rest#*"${match}"}"
        value="${!name-}"
        if [[ -n "${value}" ]]; then
            out+="${pre}${value}"
            changed="yes"
        else
            out+="${pre}${match}"
        fi
    done
    out+="${rest}"
    [[ -z "${changed}" ]] || printf '%s' "${out}" > "${file}" || return 1
    return 0
}
