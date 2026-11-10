#!/usr/bin/env bash
# @file: get-fedora-version.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints the Fedora version id.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Prints the Fedora version id (e.g. "45") to stdout.
# @stdout: prints the version id
# @exitcode: 0 on success, 1 if /etc/os-release is unavailable or VERSION_ID is missing.
get-fedora-version() {
    local version_id
    [[ -r /etc/os-release ]] || return 1
    version_id="$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    [[ -n "${version_id}" ]] || return 1
    printf '%s\n' "${version_id}"
}
