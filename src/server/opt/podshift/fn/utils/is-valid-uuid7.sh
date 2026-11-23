#!/usr/bin/env bash
# @file: is-valid-uuid7.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Tells if a text is a UUIDv7 in lower case, the form of a PodShift drop ID.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the text against xxxxxxxx-xxxx-7xxx-Vxxx-xxxxxxxxxxxx in lower-case hex.
# @details:
#   x is a lower-case hex digit, the version digit is 7 and V, the variant digit, is 8, 9, a or b.
#   The hex digits are a literal list, not a range, so the result does not depend on the locale.
# @arg: $1 - the text.
# @stdout: nothing.
# @exitcode: 0 if it is a UUIDv7, 1 if not.
is-valid-uuid7() {
    local -r h='[0123456789abcdef]'
    [[ "${1-}" =~ ^${h}{8}-${h}{4}-7${h}{3}-[89ab]${h}{3}-${h}{12}$ ]]
}
