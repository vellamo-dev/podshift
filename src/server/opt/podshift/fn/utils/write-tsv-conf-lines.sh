#!/usr/bin/env bash
# @file: write-tsv-conf-lines.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints the valid lines of tsv.conf in canonical form, for a rewrite of the file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_F9A9D538E659:-}" ]]; then
    DIR_F9A9D538E659="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_F9A9D538E659
fi

# shellcheck source=./parse-tsv-conf-line.sh
declare -F parse-tsv-conf-line >/dev/null || source "${DIR_F9A9D538E659}/parse-tsv-conf-line.sh"

# @description: Prints comments, blank lines and TSV_NAME='value' lines, dropping any other line.
# @details:
#   Uses parse-tsv-conf-line, the same parser as read-tsv-conf-lines. Comment and blank lines are
#   kept as they are. Each TSV_ line is printed as KEY='value', with a single quote in the value
#   written as '\''. Lines for the name in $2 are left out, so the caller can append a new value
#   or remove the key. Any other line is dropped, and when one or more were dropped a note is
#   printed to stderr. A missing file prints nothing.
# @arg: $1 - path of the tsv.conf file.
# @arg: $2 - optional TSV_* name whose lines are left out.
# @stdout: the kept lines.
# @stderr: Dropped N invalid line(s) from tsv.conf. when N is more than 0.
# @exitcode: 0 on success, 1 when the file exists but cannot be read.
write-tsv-conf-lines() {
    local file skip line tsv_key tsv_value dropped rc q esc
    file="${1-}"
    skip="${2-}"
    dropped=0
    q="'"
    esc="'\\''"
    [[ -e "${file}" ]] || return 0
    [[ -f "${file}" && -r "${file}" ]] || return 1
    while IFS= read -r line || [[ -n "${line}" ]]; do
        rc=0
        parse-tsv-conf-line "${line}" tsv_key tsv_value || rc=$?
        if [[ "${rc}" -eq 0 ]]; then
            [[ -n "${skip}" && "${tsv_key}" == "${skip}" ]] && continue
            printf "%s='%s'\n" "${tsv_key}" "${tsv_value//"${q}"/${esc}}"
        elif [[ "${rc}" -eq 2 ]]; then
            printf '%s\n' "${line%$'\r'}"
        else
            dropped=$((dropped + 1))
        fi
    done < "${file}"
    if [[ "${dropped}" -gt 0 ]]; then
        echo "Dropped ${dropped} invalid line(s) from tsv.conf." >&2
    fi
    return 0
}
