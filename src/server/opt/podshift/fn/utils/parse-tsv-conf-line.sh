#!/usr/bin/env bash
# @file: parse-tsv-conf-line.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Parses one line of tsv.conf as data into a TSV_* name and its value.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Splits a TSV_NAME=value line and decodes the value, without running or expanding it.
# @details:
#   The name is the text before the first =, and must be TSV_ followed by A-Z, 0-9 or _. One
#   leading and one trailing single quote are removed from the value, then each '\'' (the escaped
#   single quote written by update-tsv-conf) becomes '. A trailing carriage return is ignored. A
#   comment line (first non-blank character #) or a blank line returns 2. Any other line returns
#   1. The name and value are set with printf -v into the variables named by $2 and $3, only when
#   the line is a TSV_ line.
# @arg: $1 - the line, without its newline.
# @arg: $2 - name of the variable that receives the key.
# @arg: $3 - name of the variable that receives the value.
# @exitcode: 0 for a TSV_ line, 1 for a line that is not valid, 2 for a comment or blank line.
parse-tsv-conf-line() {
    local line key value rest q esc
    line="${1-}"
    line="${line%$'\r'}"
    rest="${line#"${line%%[![:blank:]]*}"}"
    [[ -z "${rest}" || "${rest}" == "#"* ]] && return 2
    [[ "${line}" == *=* ]] || return 1
    key="${line%%=*}"
    value="${line#*=}"
    rest="${key#TSV_}"
    [[ "${key}" == TSV_* && -n "${rest}" && "${rest}" != *[!ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789_]* ]] || return 1
    q="'"
    esc="'\\''"
    value="${value#"${q}"}"
    value="${value%"${q}"}"
    value="${value//"${esc}"/${q}}"
    printf -v "${2}" '%s' "${key}"
    printf -v "${3}" '%s' "${value}"
    return 0
}
