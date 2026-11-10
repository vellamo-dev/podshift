#!/usr/bin/env bash
# @file: 200-podman.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/200-runtime
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/200-runtime
# @host-edit: no
# @group: health-check
# @category: check
# @title: Podman
# @run-as: any
# @description: Verifies podman is installed.
# @rationale: PodShift is built on rootless Podman; nothing runs without it.
# @fix: sudo dnf install podman
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the podman check.
# @stdout: one TSV line: podman<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 2 = FAIL.
health-check-podman() {
    if command -v podman >/dev/null 2>&1; then
        printf 'podman\tOK\tinstalled\n'
        return 0
    fi
    printf 'podman\tFAIL\tnot installed\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-podman
