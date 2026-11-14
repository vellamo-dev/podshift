#!/usr/bin/env bash
# @file: load-local-env.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @unit-test: yes
# @description: Loads RPM_VM_* keys from the project's local .env file, without sourcing it.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reads <root>/.env and exports unset RPM_VM_* keys, or does nothing if the file is missing.
# @details:
#   The file is parsed, never sourced. Only KEY=VALUE lines whose key matches
#   RPM_VM_[A-Z0-9_]+ are used. Optional surrounding single or double quotes on the
#   value are stripped. Comments, blank lines and any other keys are ignored. Values
#   are never printed.
# @arg: $1 - path of the project root that may contain .env.
# @exitcode: 0 if the file was loaded or is missing, 1 if it exists but cannot be read.
load-local-env() {
    local env_file line key value
    env_file="${1}/.env"
    [[ -e "${env_file}" ]] || return 0
    [[ -f "${env_file}" && -r "${env_file}" ]] || return 1
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%$'\r'}"
        [[ "${line}" =~ ^[[:space:]]*$ || "${line}" =~ ^[[:space:]]*# ]] && continue
        [[ "${line}" =~ ^[[:space:]]*(RPM_VM_[A-Z0-9_]+)=(.*)$ ]] || continue
        key="${BASH_REMATCH[1]}"
        value="${BASH_REMATCH[2]}"
        if [[ "${#value}" -ge 2 ]]; then
            if [[ "${value}" == \"*\" || "${value}" == \'*\' ]]; then
                if [[ "${value:0:1}" == "${value:$((${#value}-1)):1}" ]]; then
                    value="${value:1:$((${#value}-2))}"
                fi
            fi
        fi
        # An empty value already in the environment still counts as set.
        if [[ -n "${!key+x}" ]]; then
            continue
        fi
        printf -v "${key}" '%s' "${value}"
        export "${key?}"
    done < "${env_file}"
    return 0
}
