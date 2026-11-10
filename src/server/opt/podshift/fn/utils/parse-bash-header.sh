#!/usr/bin/env bash
# @file: parse-bash-header.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Parses a script's @tag header into JSON or TSV.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Quotes and escapes a value as a JSON string.
# @arg: $1 - value.
# @stdout: the JSON string, including quotes.
json-q() {
    local s
    s="${1}"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '"%s"' "${s}"
}

# @description: Parses the leading @tag block of a script.
# @arg: $1 - script path.
# @arg: $2 - output format: json (default) or tsv.
# @stdout: JSON object, or one key<TAB>value line per tag.
# @exitcode: 0 on success, 1 if the file is missing.
parse-bash-header() {
    local script mode line key value first
    script="${1}"
    mode="${2:-json}"

    if [[ ! -f "${script}" ]]; then
        echo "Error: ${script} not found." >&2
        return 1
    fi

    if [[ "${mode}" == "tsv" ]]; then
        while IFS= read -r line; do
            [[ -z "${line}" ]] && break
            [[ "${line}" != "#"* ]] && break
            [[ "${line}" == "# @"* ]] || continue
            line="${line#\# }"
            key="${line%%:*}"
            value="${line#*: }"
            printf '%s\t%s\n' "${key#@}" "${value}"
        done < "${script}"
        return 0
    fi

    first=1
    printf '{'
    while IFS= read -r line; do
        [[ -z "${line}" ]] && break
        [[ "${line}" != "#"* ]] && break
        [[ "${line}" == "# @"* ]] || continue
        line="${line#\# }"
        key="${line%%:*}"
        value="${line#*: }"
        [[ ${first} -eq 1 ]] || printf ','
        printf '%s:%s' "$(json-q "${key#@}")" "$(json-q "${value}")"
        first=0
    done < "${script}"
    printf '}\n'
    return 0
}

parse-bash-header "$@"
