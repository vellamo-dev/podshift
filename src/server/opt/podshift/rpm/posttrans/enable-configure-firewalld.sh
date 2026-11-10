#!/usr/bin/env bash
# @file: enable-configure-firewalld.sh
# @source-dir: src/server/opt/podshift/rpm/posttrans
# @dest-dir: /opt/podshift/rpm/posttrans
# @host-edit: no
# @group: posttrans
# @category: step
# @step: PS-PT-FWD
# @description: Enables and configures the firewall.
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
    local zone
    # shellcheck source=../../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_212D1F830C25}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Enabling and configuring firewall..."

    # Desktop install: the firewall stays as it is.
    # shellcheck source=../../fn/utils/is-install-type-desktop.sh
    declare -F is-install-type-desktop >/dev/null || source "${DIR_212D1F830C25}/../../fn/utils/is-install-type-desktop.sh"
    if is-install-type-desktop; then
        print-step-skip "desktop install"
        return 0
    fi

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

    # Configure firewall rules.
    echo -e "\tConfiguring rules..."
    # Use the zone of the default-route interface, not a fixed one: the default
    # zone differs by image (for example FedoraServer or public). firewalld is
    # running here, so ask it. If it is not running (it failed to start), the
    # offline tool cannot see interfaces, so use its default zone.
    # shellcheck source=../../fn/network/get-firewall-zone.sh
    declare -F get-firewall-zone >/dev/null || source "${DIR_212D1F830C25}/../../fn/network/get-firewall-zone.sh"
    zone="$(get-firewall-zone)" || zone=""
    [[ -n "${zone}" ]] || zone="$(firewall-offline-cmd --get-default-zone 2>/dev/null)"
    [[ -n "${zone}" ]] || zone="public"
    echo -e "\tZone: ${zone}"
    # The ssh service (port 22) is left as it is. Only an admin changes it,
    # with podshift ssh port. Add the podshift service.
    firewall-offline-cmd --zone="${zone}" --add-service=podshift 2>/dev/null \
        || print-step-warn "failed to add the podshift firewall service to zone ${zone}."
    # Reload the firewall.
    firewall-cmd --reload 2>/dev/null \
        || print-step-warn "failed to reload the firewall."

    print-step-ok
}
