#!/usr/bin/env bash
# @file: check-tsv-config-entry.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Checks a custom TSV_* name and value against the form rules and the secret rules.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3F17968E0092:-}" ]]; then
    DIR_3F17968E0092="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3F17968E0092
fi

# @description: Checks a name and a value in a fixed order and prints the first problem found.
# @details:
#   The order is: the name form and reserved prefixes (check-tsv-config-name), a secret word in
#   the name (is-tsv-config-name-sensitive), the value characters (check-tsv-config-value), then a
#   known secret format in the value (is-tsv-config-value-sensitive). podshift config and the
#   Cockpit API both use this check, so they accept and refuse the same entries. On failure one
#   line is printed: a code, a tab and a message. The codes are INVALID_NAME, RESERVED_NAME,
#   SENSITIVE_NAME, EMPTY_VALUE, INVALID_VALUE and SENSITIVE_VALUE. The value is never printed.
# @arg: $1 - the TSV_* name.
# @arg: $2 - the value.
# @arg: $3 - the text of tsv-rules.conf.
# @stdout: nothing when the entry is accepted, else CODE<tab>message.
# @exitcode: 0 if the entry is accepted, 1 if not.
check-tsv-config-entry() {
    local key value rules
    local -r secret_message="Secrets don't belong in config. Use a Podman secret instead."
    key="${1-}"
    value="${2-}"
    rules="${3-}"
    # shellcheck source=./check-tsv-config-name.sh
    declare -F check-tsv-config-name >/dev/null || source "${DIR_3F17968E0092}/check-tsv-config-name.sh"
    check-tsv-config-name "${key}" || return 1
    # shellcheck source=./is-tsv-config-name-sensitive.sh
    declare -F is-tsv-config-name-sensitive >/dev/null || source "${DIR_3F17968E0092}/is-tsv-config-name-sensitive.sh"
    if is-tsv-config-name-sensitive "${key}" "${rules}"; then
        printf 'SENSITIVE_NAME\t%s\n' "${secret_message}"
        return 1
    fi
    # shellcheck source=./check-tsv-config-value.sh
    declare -F check-tsv-config-value >/dev/null || source "${DIR_3F17968E0092}/check-tsv-config-value.sh"
    check-tsv-config-value "${value}" || return 1
    # shellcheck source=./is-tsv-config-value-sensitive.sh
    declare -F is-tsv-config-value-sensitive >/dev/null || source "${DIR_3F17968E0092}/is-tsv-config-value-sensitive.sh"
    if is-tsv-config-value-sensitive "${value}" "${rules}"; then
        printf 'SENSITIVE_VALUE\t%s\n' "${secret_message}"
        return 1
    fi
    return 0
}
