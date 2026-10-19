#!/usr/bin/env bash
# enable-configure-firewalld.sh
# /usr/local/etc/podshift/rpm/posttrans
# Enables firewall for a system.

# Enables and configures firewalld as part of the PodShift installation.
# It activates the firewall and applies custom firewall rules tailored
# for the PodShift environment.
#
# Firewalld provides a dynamically managed firewall with support
# for network/firewall zones that define the trust level
# of network connections or interfaces.
#
# You can control the firewall rules with the firewall-cmd console utility.

if [[ -z "${DIR_212D1F830C25:-}" ]]; then
    DIR_212D1F830C25="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_212D1F830C25
fi

enable-configure-firewalld() {
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_212D1F830C25}/../../fn/utils/print-warning.sh"

    echo -e "\nEnabling and configuring firewall..."

    if systemctl is-enabled --quiet firewalld 2>/dev/null; then
        echo -e "\tAlready enabled"
    else
        echo -e "\tEnabling..."
        systemctl enable firewalld 2>/dev/null \
            || print-warning "failed to enable firewalld."
    fi
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        echo -e "\tAlready started"
    else
        echo -e "\tStarting..."
        systemctl start firewalld 2>/dev/null \
            || print-warning "failed to start firewalld."
    fi

    # Import firewall presets.
    echo -e "\tImporting rules..."
    systemctl preset firewalld.service cockpit.socket pmcd.service pmlogger.service user@300.service 2>/dev/null \
        || print-warning "failed to apply firewall presets."

    # Configure firewall rules.
    echo -e "\tConfiguring rules..."
    # Remove the default ssh service (benign if already absent).
    firewall-cmd --permanent --remove-service=ssh 2>/dev/null || true
    # Add the podshift service.
    firewall-cmd --permanent --zone=public --add-service=podshift 2>/dev/null \
        || print-warning "failed to add the podshift firewall service."
    # Reload the firewall.
    firewall-cmd --reload 2>/dev/null \
        || print-warning "failed to reload the firewall."

    echo -e "\tDone"
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && enable-configure-firewalld
fi
