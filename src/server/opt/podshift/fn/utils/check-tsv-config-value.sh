#!/usr/bin/env bash
# @file: check-tsv-config-value.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Checks that a value can be stored as a custom TSV_* value and used in a Quadlet line.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Refuses an empty value, control characters, quotes and a trailing backslash.
# @details:
#   fill-tsv-vars inserts a value into the Quadlet file as it is. A control character such as a
#   newline would end the line. A double or single quote opens a systemd quoted word that is not
#   closed, for example in Environment= or Exec=. A trailing backslash joins the next line when
#   the variable is at the end of a line. On failure one line is printed: a code, a tab and a
#   message. The codes are EMPTY_VALUE and INVALID_VALUE. The value itself is never printed.
# @arg: $1 - the value to check.
# @stdout: nothing when the value is accepted, else CODE<tab>message.
# @exitcode: 0 if the value is accepted, 1 if not.
check-tsv-config-value() {
    local value
    value="${1-}"
    if [[ -z "${value}" ]]; then
        printf 'EMPTY_VALUE\tValue must not be empty.\n'
        return 1
    fi
    if [[ "${value}" == *[[:cntrl:]]* || "${value}" == *'"'* || "${value}" == *"'"* || "${value}" == *'\' ]]; then
        printf 'INVALID_VALUE\tValue must not contain quotes (" or '"'"'), control characters or a trailing backslash.\n'
        return 1
    fi
    return 0
}
