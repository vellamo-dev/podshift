#!/usr/bin/env bash
# @file: 201-podman-rootless.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/200-runtime
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/200-runtime
# @host-edit: no
# @group: health-check
# @category: check
# @title: Rootless Podman
# @run-as: podshift
# @description: Verifies rootless podman actually works.
# @rationale: Without a working rootless runtime, containers cannot start.
# @fix: Run podman info as the podshift user to see the error.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the podman-rootless check.
# @stdout: one TSV line: podman-rootless<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-podman-rootless() {
    local out
    out="$(podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null)"
    if [[ "${out}" == "true" ]]; then
        printf 'podman-rootless\tOK\trootless podman works\n'
        return 0
    fi
    printf 'podman-rootless\tFAIL\trootless podman not working\n'
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-podman-rootless
