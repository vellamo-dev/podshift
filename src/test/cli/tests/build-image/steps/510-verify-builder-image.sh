#!/usr/bin/env bash
# @file: 510-verify-builder-image.sh
# @source-dir: src/test/cli/tests/build-image/steps
# @group: test
# @category: step
# @description: Verify RPM builder image.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the RPM builder image exists.
# @arg: $1 - the run folder.
# @stdout: the problem, if any.
# @exitcode: 0 if the image exists, 1 otherwise.
verify-builder-image() {
    image-exists "${1}" build-image "${TST_RPM_BUILDER_IMG}:${TST_FEDORA_VERSION}"
}
