#!/usr/bin/env bash
# @file: image-age.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Prints the age of a Podman image.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the age of an image in seconds, or nothing if the image does not exist.
# @arg: $1 - the image with its tag.
# @stdout: the age in seconds.
image-age() {
    local created
    created="$(podman image inspect --format '{{.Created.Unix}}' "${1}" 2>/dev/null)"
    [[ -n "${created}" ]] || return 0
    printf '%s\n' "$(( ($(date +%s) - created) ))"
}
