#!/usr/bin/env bash
# @file: is-tsv-config-value-sensitive.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Tells if a value matches a known secret format from the tsv-rules.conf text.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 when the value matches one value pattern from the rules text.
# @details:
#   Each "value <regex>" line of the rules is an extended regular expression, matched with the
#   Bash =~ operator. Only exact, well-known formats are listed, such as private key headers and
#   GitHub, GitLab, Slack, AWS and JWT tokens. There is no guess by randomness, so digests,
#   UUIDs and long IDs are not secrets. Other rule lines are ignored.
# @arg: $1 - the value.
# @arg: $2 - the text of tsv-rules.conf.
# @stdout: nothing.
# @exitcode: 0 if the value looks like a secret, 1 if not.
is-tsv-config-value-sensitive() {
    local value rules line pattern
    value="${1-}"
    rules="${2-}"
    while IFS= read -r line; do
        [[ "${line}" == "value "* ]] || continue
        pattern="${line#value }"
        [[ -n "${pattern}" ]] || continue
        [[ "${value}" =~ ${pattern} ]] && return 0
    done <<< "${rules}"
    return 1
}
