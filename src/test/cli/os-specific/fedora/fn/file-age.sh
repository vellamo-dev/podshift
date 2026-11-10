#!/usr/bin/env bash
# @file: file-age.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Prints the age of a file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints how long ago a file was last changed, in seconds, or nothing if it does not exist.
# @arg: $1 - the file.
# @stdout: the age in seconds.
file-age() {
    local changed
    changed="$(stat -c %Y "${1}" 2>/dev/null)"
    [[ -n "${changed}" ]] || return 0
    printf '%s\n' "$(( $(date +%s) - changed ))"
}
