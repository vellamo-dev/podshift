#!/usr/bin/env bash
# @file: json-q.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Quotes a value as a JSON string.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Quotes and escapes a value as a JSON string.
# @arg: $1 - the value.
# @stdout: the JSON string, including the quotes.
# @exitcode: 0 always.
json-q() {
    local value
    value="${1}"
    value="${value//\\/\\\\}"
    value="${value//\"/\\\"}"
    value="${value//$'\t'/\\t}"
    value="${value//$'\n'/\\n}"
    printf '"%s"' "${value}"
}
