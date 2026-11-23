#!/usr/bin/env bash
# @file: cockpit-overview-info-podman-version.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-info/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-info/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the installed Podman version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the installed Podman version.
# @stdout: a version string, or nothing when Podman is missing.
# @exitcode: 0 always.
cockpit-overview-info-podman-version() {
    local version
    version="$(podman version --format '{{.Client.Version}}' 2>/dev/null || true)"
    if [[ -z "${version}" ]]; then
        version="$(rpm -q --qf '%{VERSION}' podman 2>/dev/null || true)"
    fi
    case "${version}" in
        ''|*is\ not\ installed*)
            return 0
            ;;
    esac
    printf '%s\n' "${version}"
}
