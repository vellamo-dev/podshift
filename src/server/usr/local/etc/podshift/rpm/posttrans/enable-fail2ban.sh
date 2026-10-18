#!/usr/bin/env bash
# enable-fail2ban.sh
# /usr/local/etc/podshift/rpm/posttrans
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
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_186F265F7E42}/../../fn/utils/print-warning.sh"

    echo -e "\nEnabling and starting fail2ban..."

    if systemctl is-enabled --quiet fail2ban 2>/dev/null; then
        echo -e "\tAlready enabled"
    else
        echo -e "\tEnabling..."
        systemctl enable fail2ban 2>/dev/null \
            || print-warning "failed to enable fail2ban."
    fi

    if systemctl is-active --quiet fail2ban 2>/dev/null; then
        echo -e "\tAlready started"
    else
        echo -e "\tStarting..."
        systemctl start fail2ban 2>/dev/null \
            || print-warning "failed to start fail2ban."
    fi

    echo -e "\tDone"
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && enable-fail2ban
fi
