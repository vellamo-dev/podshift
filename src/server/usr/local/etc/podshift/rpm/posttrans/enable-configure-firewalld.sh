#!/usr/bin/env bash
# @file: enable-configure-firewalld.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: FWD
# @description: Enables and configures the firewall
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
# Enables firewall for a system.
#
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

# @description: Enables and configures the firewall.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
enable-configure-firewalld() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-FWD"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_212D1F830C25}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Enabling and configuring firewall..."

    if systemctl is-enabled --quiet firewalld 2>/dev/null; then
        echo -e "\tAlready enabled"
    else
        echo -e "\tEnabling..."
        systemctl enable firewalld 2>/dev/null \
            || print-step-warn "failed to enable firewalld."
    fi
    if systemctl is-active --quiet firewalld 2>/dev/null; then
        echo -e "\tAlready started"
    else
        echo -e "\tStarting..."
        systemctl start firewalld 2>/dev/null \
            || print-step-warn "failed to start firewalld."
    fi

    # Import firewall presets.
    echo -e "\tImporting rules..."
    systemctl preset firewalld.service cockpit.socket pmcd.service pmlogger.service user@300.service 2>/dev/null \
        || print-step-warn "failed to apply firewall presets."

    # Configure firewall rules.
    echo -e "\tConfiguring rules..."
    # Remove the default ssh service (benign if already absent).
    firewall-cmd --permanent --remove-service=ssh 2>/dev/null || true
    # Add the podshift service.
    firewall-cmd --permanent --zone=public --add-service=podshift 2>/dev/null \
        || print-step-warn "failed to add the podshift firewall service."
    # Reload the firewall.
    firewall-cmd --reload 2>/dev/null \
        || print-step-warn "failed to reload the firewall."

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && enable-configure-firewalld
fi
