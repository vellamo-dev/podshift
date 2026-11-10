#!/usr/bin/env bash
# @file: 510-verify-podman.sh
# @source-dir: src/test/cli/tests/host-container-start/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Verify Podman.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that Podman answers.
# @details:
#   Podman needs no separate system start.
# @arg: $1 - the run folder.
# @stdout: the problem and how to fix it, if any.
# @exitcode: 0 if Podman answers, 3 otherwise (cannot run here).
verify-podman() {
    local run_dir
    run_dir="${1}"
    if podman info >/dev/null 2>&1; then
        write-log "${run_dir}" host-container-start "Podman: ready"
        return 0
    fi
    write-log "${run_dir}" host-container-start "Podman: not ready"
    echo "Podman does not answer"
    echo "Fix: run podman info and check its output"
    return 3
}
