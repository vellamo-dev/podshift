#!/usr/bin/env bash
# @file: get-fedora-version.sh
# @dir: /opt/podshift/fn/utils
# @group: utils
# @description: Prints the Fedora version id.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Prints the Fedora version id (e.g. "44") to stdout.
# @stdout: prints the version id
# @exitcode: 0 on success, 1 if /etc/os-release is unavailable or VERSION_ID is missing.
get-fedora-version() {
    local version_id
    [[ -r /etc/os-release ]] || return 1
    version_id="$(grep '^VERSION_ID=' /etc/os-release | cut -d= -f2 | tr -d '"')"
    [[ -n "${version_id}" ]] || return 1
    printf '%s\n' "${version_id}"
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && get-fedora-version
fi
