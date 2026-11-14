#!/usr/bin/env bash
# @file: cockpit-contract-failing-args.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Names the top-level arguments that fail an input contract, for the INVALID_ARGS message.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1FA1BD7E605F:-}" ]]; then
    DIR_1FA1BD7E605F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1FA1BD7E605F
fi

# @description: Prints the names of the arguments that fail the contract, sorted and joined with ", ".
# @details:
#   An argument fails when it is not in properties and additionalProperties is false, when it is
#   required and missing, or when its value fails its own contract. Only names of 1 to 64 letters,
#   digits, _, - and . are printed, so caller text that looks like anything else is never echoed.
#   Values are never printed.
# @arg: $1 - input contract JSON of an object.
# @arg: $2 - args JSON object.
# @stdout: the names, for example "kind, ref".
# @exitcode: 0 when at least one name was printed, 1 when none can be named.
cockpit-contract-failing-args() {
    local contract value names key sub rc
    local -a failing
    contract="${1-}"
    value="${2-}"
    # shellcheck source=./cockpit-validate-contract.sh
    declare -F cockpit-validate-contract >/dev/null || source "${DIR_1FA1BD7E605F}/cockpit-validate-contract.sh"
    names="$(jq -n -r --argjson c "${contract}" --argjson v "${value}" '
        if ($v | type) != "object" or ($c | type) != "object" then empty
        else
            ($c.properties // {}) as $p
            | ([($v | keys[]) | select(. as $k | (($p | has($k)) | not) and ($c.additionalProperties == false))]
               + [($c.required // [])[] | select(. as $k | ($v | has($k)) | not)])[]
        end
    ' 2>/dev/null)" || return 1
    failing=()
    while IFS= read -r key; do
        [[ -n "${key}" ]] && failing+=("${key}")
    done <<< "${names}"
    while IFS= read -r key; do
        [[ -n "${key}" ]] || continue
        sub="$(jq -n -c --argjson c "${contract}" --arg k "${key}" '$c.properties[$k]' 2>/dev/null)" || continue
        cockpit-validate-contract "${sub}" "$(jq -n -c --argjson v "${value}" --arg k "${key}" '$v[$k]')" && rc=0 || rc=$?
        [[ "${rc}" -eq 0 ]] || failing+=("${key}")
    done < <(jq -n -r --argjson c "${contract}" --argjson v "${value}" '
        if ($v | type) == "object" and ($c | type) == "object" then
            ($c.properties // {}) as $p | $v | keys[] | select(. as $k | $p | has($k))
        else empty end
    ' 2>/dev/null)
    [[ "${#failing[@]}" -gt 0 ]] || return 1
    names="$(printf '%s\n' "${failing[@]}" | LC_ALL=C grep -E '^[A-Za-z0-9_.-]{1,64}$' | LC_ALL=C sort -u | paste -s -d ',' - | sed 's/,/, /g')"
    [[ -n "${names}" ]] || return 1
    printf '%s\n' "${names}"
    return 0
}
