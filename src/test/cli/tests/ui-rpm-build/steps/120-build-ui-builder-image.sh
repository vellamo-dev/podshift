#!/usr/bin/env bash
# @file: 120-build-ui-builder-image.sh
# @source-dir: src/test/cli/tests/ui-rpm-build/steps
# @group: test
# @category: step
# @description: Build cockpit-podshift RPM builder image.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Builds the cockpit-podshift RPM builder image from Dockerfile.ui-rpm-builder, or reuses it if it is new enough.
# @arg: $1 - the run folder.
# @stdout: NOTE with what happened and why, and the build output.
# @exitcode: 0 if the image is ready or skipped, 1 otherwise.
build-ui-builder-image() {
    [[ "${TST_UI_PRESENT}" == "true" ]] || { echo "NOTE: skipped"; return 0; }
    build-or-reuse-image "${1}" ui-rpm-build "${TST_UI_RPM_BUILDER_IMG}:${TST_FEDORA_VERSION}" Dockerfile.ui-rpm-builder \
        "${TST_UI_RPM_BUILDER_REUSE}" "${TST_UI_RPM_BUILDER_MAX_AGE_HOURS}" "${TST_UI_RPM_BUILDER_NO_CACHE}"
}
