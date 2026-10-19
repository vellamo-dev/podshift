#!/usr/bin/env bash
# @file: is-admin.sh
# @dir: /usr/local/etc/podshift/fn/utils
# @group: utils
# @description: Detects whether the current user has administrator privileges.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the current user is root or has passwordless sudo.
# @exitcode: 0 if admin, 1 otherwise.
is-admin() {
    [[ "${EUID}" -eq 0 ]] || sudo -n true 2>/dev/null
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-admin
fi
