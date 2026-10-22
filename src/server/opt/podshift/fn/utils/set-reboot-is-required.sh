#!/usr/bin/env bash
# @file: set-reboot-is-required.sh
# @dir: /opt/podshift/fn/utils
# @group: utils
# @description: Sets the reboot-required flag.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Sets the reboot-required flag (creates /run/reboot-required).
# @exitcode: 0 always (non-fatal, failures are logged via logger).
set-reboot-is-required() {
    mkdir -p /run 2>/dev/null || logger -t podshift "failed to create /run." || true
    touch /run/reboot-required 2>/dev/null || logger -t podshift "failed to create the reboot-required flag." || true
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && set-reboot-is-required
fi
