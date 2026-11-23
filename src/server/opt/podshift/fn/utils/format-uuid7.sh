#!/usr/bin/env bash
# @file: format-uuid7.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Builds a UUIDv7 from a millisecond Unix time and 10 random bytes.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the UUIDv7 of the given time and random hex, as in RFC 9562.
# @details:
#   The first 48 bits are the time in milliseconds, then the version 7, 12 random bits, the
#   variant bits 10, and 62 random bits. 19 of the 20 hex digits are used: the 4th one gives only
#   its 2 low bits. The result is in lower case, so IDs sort by time as text.
#   new-uuid7 reads the clock and /dev/urandom and calls this.
# @arg: $1 - Unix time in milliseconds, 1 to 15 digits and below 2^48.
# @arg: $2 - 20 hex digits (10 bytes), for example from od -An -N10 -tx1 /dev/urandom.
# @stdout: the UUID, for example 019aa6b1-2c3d-7e4f-9a5b-6c7d8e9fa0b1.
# @exitcode: 0 when it was printed, 1 when the time or the hex is not valid.
format-uuid7() {
    local ms random time
    local -r h='[0123456789abcdefABCDEF]'
    ms="${1-}"
    random="${2-}"
    [[ "${ms}" =~ ^[0123456789]{1,15}$ ]] || return 1
    ms="$((10#${ms}))"
    (( ms < 281474976710656 )) || return 1
    [[ "${random}" =~ ^${h}{20}$ ]] || return 1
    random="$(printf '%s' "${random}" | tr 'ABCDEF' 'abcdef')"
    printf -v time '%012x' "${ms}"
    printf '%s-%s-7%s-%x%s-%s\n' "${time:0:8}" "${time:8:4}" "${random:0:3}" \
        "$(( (16#${random:3:1} & 3) | 8 ))" "${random:4:3}" "${random:7:12}"
}
