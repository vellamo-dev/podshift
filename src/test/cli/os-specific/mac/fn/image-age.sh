#!/usr/bin/env bash
# @file: image-age.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Prints the age of a Apple container image.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the age of an image in seconds, or nothing if the image does not exist.
# @arg: $1 - the image with its tag.
# @stdout: the age in seconds.
image-age() {
    local stamp created
    stamp="$(container image inspect "${1}" 2>/dev/null | grep -m1 '"creationDate"' | sed -E 's/.*"([0-9-]{10}T[0-9:]{8}).*/\1/')"
    [[ -n "${stamp}" ]] || return 0
    created="$(date -j -u -f '%Y-%m-%dT%H:%M:%S' "${stamp}" +%s)" || return 0
    printf '%s\n' "$(( ($(date +%s) - created) ))"
}
