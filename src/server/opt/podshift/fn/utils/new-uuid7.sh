#!/usr/bin/env bash
# @file: new-uuid7.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Makes a new UUIDv7 from the clock and /dev/urandom, used as the ID of each drop.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_A82B22A12864:-}" ]]; then
    DIR_A82B22A12864="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A82B22A12864
fi

# @description: Reads the time in milliseconds and 10 random bytes and prints them as a UUIDv7.
# @details:
#   The time is GNU date +%s%3N. When that does not give 13 digits (BSD date on a Mac, in local
#   tests), whole seconds with 000 are used. The random bytes are read once with
#   od -An -N10 -tx1 /dev/urandom. format-uuid7 builds the UUID.
# @stdout: the UUID.
# @exitcode: 0 when it was printed, 1 when the clock or /dev/urandom cannot be read.
new-uuid7() {
    local ms random
    # shellcheck source=./format-uuid7.sh
    declare -F format-uuid7 >/dev/null || source "${DIR_A82B22A12864}/format-uuid7.sh"
    ms="$(date +%s%3N 2>/dev/null)" || ms=""
    [[ "${ms}" =~ ^[0123456789]{13}$ ]] || ms="$(date +%s 2>/dev/null)000"
    random="$(od -An -N10 -tx1 /dev/urandom 2>/dev/null | tr -d ' \n')" || return 1
    format-uuid7 "${ms}" "${random}"
}
