#!/usr/bin/env bash
# get-fedora-version.sh
# /usr/local/etc/podshift/fn/utils

# Prints the Fedora version id (e.g. "44") to stdout.
# Returns non-zero if /etc/os-release is unavailable or VERSION_ID is missing.
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
