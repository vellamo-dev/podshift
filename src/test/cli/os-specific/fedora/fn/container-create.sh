#!/usr/bin/env bash
# @file: container-create.sh
# @source-dir: src/test/cli/os-specific/fedora/fn
# @group: test
# @category: helper
# @description: Creates a container with a host folder mounted at /share.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Creates a container from an image, with a host folder mounted at /share.
# @details:
#   The :Z flag lets SELinux allow the mount.
# @arg: $1 - the container name.
# @arg: $2 - the host folder for /share.
# @arg: $3 - the image with its tag.
# @exitcode: the exit code of the create.
container-create() {
    podman create --name "${1}" -v "${2}":/share:Z "${3}"
}
