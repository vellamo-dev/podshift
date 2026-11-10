#!/usr/bin/env bash
# @file: 530-check-container-version.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/mac/steps
# @group: test
# @category: step
# @description: Apple container version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the Apple container tool is TST_MIN_CONTAINER_VERSION or newer.
# @stdout: the version found, and how to fix it if too old.
# @arg: $1 - the run folder.
# @exitcode: 0 if new enough, 3 otherwise (cannot run here).
check-container-version() {
    local run_dir found
    run_dir="${1}"
    found="$(container --version 2>/dev/null | grep -Eo '[0-9]+\.[0-9]+(\.[0-9]+)?' | head -n 1)"
    write-log "${run_dir}" host-check "Apple container version: ${found:-not found}, needs ${TST_MIN_CONTAINER_VERSION}"
    echo "NOTE: ${found:-not found}"
    is-version-at-least "${found:-0}" "${TST_MIN_CONTAINER_VERSION}" && return 0
    echo "Found ${found:-none}, ${TST_MIN_CONTAINER_VERSION} or newer needed"
    echo "Fix: install or update it from https://github.com/apple/container/releases"
    return 3
}
