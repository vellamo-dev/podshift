#!/usr/bin/env bash
# @file: enable-fail2ban.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: F2B
# @description: Enables and starts fail2ban
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Enables Fail2Ban to tighten the server security.
#
# Fail2Ban is an intrusion prevention software that monitors system log files
# for suspicious activity, such as repeated failed login attempts, and
# automatically updates local firewall rules to temporarily block offending IP addresses.
#
# See more: https://github.com/fail2ban/fail2ban

if [[ -z "${DIR_186F265F7E42:-}" ]]; then
    DIR_186F265F7E42="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_186F265F7E42
fi

# @description: Enables and starts fail2ban.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
enable-fail2ban() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-F2B"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_186F265F7E42}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Enabling and starting fail2ban..."

    if systemctl is-enabled --quiet fail2ban 2>/dev/null; then
        echo -e "\tAlready enabled"
    else
        echo -e "\tEnabling..."
        systemctl enable fail2ban 2>/dev/null \
            || print-step-warn "failed to enable fail2ban."
    fi

    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        echo -e "\tAlready started"
    else
        echo -e "\tStarting..."
        systemctl start fail2ban 2>/dev/null \
            || print-step-warn "failed to start fail2ban."
    fi

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && enable-fail2ban
fi
