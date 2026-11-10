#!/usr/bin/env bash
# @file: image-tags.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Lists every tag of an image.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints each local image with the given name, one per line as name:tag.
# @arg: $1 - the image name, without a tag.
# @stdout: the images.
image-tags() {
    container image ls 2>/dev/null | awk -v n="${1}" 'NR > 1 && $1 == n { print $1 ":" $2 }'
}
