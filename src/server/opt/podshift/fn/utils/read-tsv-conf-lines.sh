#!/usr/bin/env bash
# @file: read-tsv-conf-lines.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Loads the custom TSV_* values from tsv.conf as data, without sourcing the file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_9C4DFA8FEF49:-}" ]]; then
    DIR_9C4DFA8FEF49="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_9C4DFA8FEF49
fi

# shellcheck source=./parse-tsv-conf-line.sh
declare -F parse-tsv-conf-line >/dev/null || source "${DIR_9C4DFA8FEF49}/parse-tsv-conf-line.sh"

# @description: Sets and exports every TSV_NAME=value line of a tsv.conf file, in file order.
# @details:
#   Pure Bash with no subprocess. Each line goes through parse-tsv-conf-line, so values are never
#   run or expanded, and comments, blank lines and any other lines are ignored. A last line
#   without a newline is read too. A later line for the same name wins.
# @arg: $1 - path of the tsv.conf file.
# @exitcode: 0 when the file was read, 1 when it cannot be read.
read-tsv-conf-lines() {
    local file line tsv_key tsv_value
    file="${1-}"
    [[ -n "${file}" && -f "${file}" && -r "${file}" ]] || return 1
    while IFS= read -r line || [[ -n "${line}" ]]; do
        if parse-tsv-conf-line "${line}" tsv_key tsv_value; then
            printf -v "${tsv_key}" '%s' "${tsv_value}"
            export "${tsv_key?}"
        fi
    done < "${file}"
    return 0
}
