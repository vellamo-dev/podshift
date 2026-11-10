#!/usr/bin/env bash
# @file: get-podman-version.sh
# @source-dir: src/server/opt/podshift/fn/common
# @dest-dir: /opt/podshift/fn/common
# @host-edit: no
# @group: common
# @category: helper
# @description: Prints the Podman version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Podman version, or nothing when Podman is absent.
# @stdout: the version string, or nothing.
# @exitcode: 0 always.
get-podman-version() {
    local version
    if command -v podman >/dev/null 2>&1; then
        version="$(podman --version 2>/dev/null | awk '{print $NF}')"
        [[ -n "${version}" ]] && printf '%s\n' "${version}"
    fi
    return 0
}
