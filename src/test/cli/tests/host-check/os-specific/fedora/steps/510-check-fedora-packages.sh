#!/usr/bin/env bash
# @file: 510-check-fedora-packages.sh
# @source-dir: src/test/cli/tests/host-check/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Fedora packages.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the Fedora packages the tests need are installed.
# @stdout: each missing package and how to fix it.
# @arg: $1 - the run folder.
# @exitcode: 0 if all are installed, 3 otherwise (cannot run here).
check-fedora-packages() {
    local run_dir rc
    run_dir="${1}"
    rc=0
    write-log "${run_dir}" host-check "podman: $(command -v podman || echo not found), rpmbuild: $(command -v rpmbuild || echo not found)"
    command -v podman >/dev/null 2>&1 || { echo "podman not found"; echo "Fix: sudo dnf install podman"; rc=3; }
    command -v rpmbuild >/dev/null 2>&1 || { echo "rpmbuild not found"; echo "Fix: sudo dnf install rpm-build"; rc=3; }
    return "${rc}"
}
