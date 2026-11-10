#!/usr/bin/env bash
# @file: 110-build-builder-image.sh
# @source-dir: src/test/cli/tests/build-image/steps
# @group: test
# @category: step
# @description: Build RPM builder image.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Builds the RPM builder image from Dockerfile.rpm-builder, or reuses it if it is new enough.
# @arg: $1 - the run folder.
# @stdout: NOTE with what happened and why, and the build output.
# @exitcode: 0 if the image is ready, 1 otherwise.
build-builder-image() {
    build-or-reuse-image "${1}" build-image "${TST_RPM_BUILDER_IMG}:${TST_FEDORA_VERSION}" Dockerfile.rpm-builder \
        "${TST_RPM_BUILDER_REUSE}" "${TST_RPM_BUILDER_MAX_AGE_HOURS}" "${TST_RPM_BUILDER_NO_CACHE}"
}
