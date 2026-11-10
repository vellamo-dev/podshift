#!/usr/bin/env bash
# @file: image-exists.sh
# @source-dir: src/test/cli/shared/fn/image
# @group: test
# @category: helper
# @description: Checks that a test image exists.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the image exists.
# @arg: $1 - the run folder.
# @arg: $2 - the log name.
# @arg: $3 - the image with its tag.
# @stdout: the problem, if any.
# @exitcode: 0 if the image exists, 1 otherwise.
image-exists() {
    if container-cli image inspect "${3}" >/dev/null 2>&1; then
        write-log "${1}" "${2}" "Image ${3}: present"
        return 0
    fi
    write-log "${1}" "${2}" "Image ${3}: missing"
    echo "The image ${3} does not exist"
    return 1
}
