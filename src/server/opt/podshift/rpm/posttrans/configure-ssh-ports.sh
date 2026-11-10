#!/usr/bin/env bash
# @file: configure-ssh-ports.sh
# @source-dir: src/server/opt/podshift/rpm/posttrans
# @dest-dir: /opt/podshift/rpm/posttrans
# @host-edit: no
# @group: posttrans
# @category: step
# @step: PS-PT-SSP
# @description: Makes sshd listen on ports 22 and 1022.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Adds a drop-in to sshd so it listens on port 22 and port 1022.
# It does not edit /etc/ssh/sshd_config and does not touch the firewall:
# the firewalld ssh service (port 22) stays on, and the podshift service
# already opens 1022. To close port 22 for the network, an admin runs
# 'podshift ssh port 1022'. Port 1022 only brings less noise in the logs.
# The protection is the key-only login and fail2ban.
#
# A custom SSH port is left alone. An upgrade never changes the firewall.
# Port 1022 needs the ssh_port_t SELinux label (update-selinux runs before).

if [[ -z "${DIR_ACF1F23ED9E4:-}" ]]; then
    DIR_ACF1F23ED9E4="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_ACF1F23ED9E4
fi

# @description: Writes the sshd drop-in with ports 22 and 1022, checks it and restarts sshd.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
configure-ssh-ports() {
    # Reserved step tag (matches @step in the header).
    local -r step_tag="PS-PT-SSP"
    local -r drop_in="/etc/ssh/sshd_config.d/10-podshift-ssh-ports.conf"
    local template
    # shellcheck source=../../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_ACF1F23ED9E4}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Configuring SSH ports 22 and 1022..."

    if ! command -v sshd >/dev/null 2>&1; then
        print-step-warn "sshd not found, SSH ports not configured."
        return 0
    fi

    # An upgrade finds the drop-in and changes nothing.
    if [[ -f "${drop_in}" ]]; then
        echo -e "\tAlready configured"
        print-step-ok
        return 0
    fi

    # A custom port is the admin's choice: hands off.
    # shellcheck source=../../fn/network/is-ssh-port-custom.sh
    declare -F is-ssh-port-custom >/dev/null || source "${DIR_ACF1F23ED9E4}/../../fn/network/is-ssh-port-custom.sh"
    if is-ssh-port-custom "$(sshd -T 2>/dev/null)" "22"; then
        print-step-skip "custom SSH port found, skipped"
        return 0
    fi

    # shellcheck source=../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_ACF1F23ED9E4}/../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    # shellcheck source=../../assets/tpl/10-podshift-ssh-ports.conf
    template="${PODSHIFT_RUNTIME_CONF_TEMPLATES}/10-podshift-ssh-ports.conf"
    echo -e "\tWriting ${drop_in}"
    if ! install -D -m 0644 "${template}" "${drop_in}"; then
        print-step-warn "failed to write ${drop_in}, SSH ports not configured."
        return 0
    fi
    restorecon "${drop_in}" 2>/dev/null || true

    # Check the configuration before restarting. On an error remove the drop-in.
    echo -e "\tValidating configuration"
    if ! sshd -t 2>/dev/null; then
        rm -f "${drop_in}"
        print-step-warn "sshd configuration is invalid with the new ports, drop-in removed."
        return 0
    fi

    echo -e "\tRestarting sshd"
    if ! systemctl restart sshd; then
        rm -f "${drop_in}"
        systemctl restart sshd >/dev/null 2>&1 || true
        print-step-warn "failed to restart sshd, drop-in removed."
        return 0
    fi

    # sshd -T shows the ports it is told to use, not the ones it got.
    # Without the SELinux label sshd starts on port 22 only, so look at ss.
    # shellcheck source=../../fn/network/is-port-listening.sh
    declare -F is-port-listening >/dev/null || source "${DIR_ACF1F23ED9E4}/../../fn/network/is-port-listening.sh"
    if ! is-port-listening 1022; then
        print-step-warn "sshd is not listening on 1022, check the SELinux port label. Port 22 still works."
        return 0
    fi

    print-step-ok
    return 0
}
