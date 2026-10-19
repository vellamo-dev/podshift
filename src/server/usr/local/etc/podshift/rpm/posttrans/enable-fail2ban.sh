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
# Enables Fail2ban to tighten the server security.
#
# Fail2ban is an intrusion prevention software that monitors system log files
# for suspicious activity, such as repeated failed login attempts, and
# automatically updates local firewall rules to temporarily block offending IP addresses.

if [[ -z "${DIR_186F265F7E42:-}" ]]; then
    DIR_186F265F7E42="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_186F265F7E42
fi

enable-fail2ban() {
    # Reserved step identity (matches @prefix and @id in the header).
    local -r step_prefix="PS-PT"
    local -r step_id="F2B"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_186F265F7E42}/../../fn/utils/print-step.sh"

    print-step-header "Enabling and starting fail2ban..."

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
