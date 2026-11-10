#!/usr/bin/env bash
# @file: get-quadlet-ini.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Reads sections, keys and values from a quadlet file, like crudini --get.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reads sections, keys or a value from a quadlet file as INI, in pure Bash and case-sensitive.
# @details:
#   Skips blank lines and lines starting with # or ;. Lines after a line ending in a backslash are
#   continuation lines and are skipped.
# @arg: $1 - quadlet file.
# @arg: $2 - section name (optional).
# @arg: $3 - key name (optional).
# @stdout: no section: the section names, one per line, in first-seen order. Section: its keys with a non-empty value, one per line, in first-seen order. Section and key: the value, last occurrence wins. On error, one line: "bad line N" or "cannot read".
# @exitcode: 0 if read, 1 on an error or if the section or key asked for is not present or the value is empty.
get-quadlet-ini() {
    local file section key line number current found continued name value result list
    file="${1}"
    section="${2-}"
    key="${3-}"
    if [[ ! -f "${file}" || ! -r "${file}" ]]; then
        echo "cannot read"
        return 1
    fi
    number=0; current=""; found=""; continued=""; result=""; list=$'\n'
    while IFS= read -r line || [[ -n "${line}" ]]; do
        number=$(( number + 1 ))
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -z "${line}" || "${line}" == "#"* || "${line}" == ";"* ]] && continue
        if [[ -n "${continued}" ]]; then
            [[ "${line}" == *"\\" ]] || continued=""
            continue
        fi
        if [[ "${line}" =~ ^\[(.+)\]$ ]]; then
            current="${BASH_REMATCH[1]}"
            [[ "${current}" == "${section}" ]] && found="yes"
            [[ -z "${section}" && "${list}" != *$'\n'"${current}"$'\n'* ]] && list+="${current}"$'\n'
            continue
        fi
        name="${line%%=*}"; name="${name%"${name##*[![:space:]]}"}"
        value="${line#*=}"; value="${value#"${value%%[![:space:]]*}"}"
        if [[ "${line}" != *=* || -z "${name}" || -z "${current}" ]]; then
            echo "bad line ${number}"
            return 1
        fi
        [[ "${line}" == *"\\" ]] && continued="yes"
        [[ -n "${section}" && "${current}" == "${section}" ]] || continue
        if [[ -n "${key}" ]]; then
            [[ "${name}" == "${key}" ]] && result="${value}"
        elif [[ -n "${value}" && "${list}" != *$'\n'"${name}"$'\n'* ]]; then
            list+="${name}"$'\n'
        fi
    done < "${file}"
    [[ -z "${section}" || -n "${found}" ]] || return 1
    if [[ -n "${key}" ]]; then
        [[ -n "${result}" ]] || return 1
        echo "${result}"
        return 0
    fi
    printf '%s' "${list#$'\n'}"
}
