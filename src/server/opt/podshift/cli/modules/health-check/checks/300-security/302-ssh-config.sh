#!/usr/bin/env bash
# @file: 302-ssh-config.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/300-security
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/300-security
# @host-edit: no
# @group: health-check
# @category: check
# @title: SSH
# @run-as: root
# @install-type: server
# @description: Verifies sshd runs with key-only login and listens on port 1022.
# @rationale: Password login lets bots guess passwords. A missing 1022 listener means the SSH port setup did not work.
# @fix: Check 'sshd -T | grep -i passwordauthentication', then 'sudo systemctl status sshd' and the SELinux port label for 1022: sudo semanage port -l | grep ssh
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E780CA43AAFE:-}" ]]; then
    DIR_E780CA43AAFE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E780CA43AAFE
fi

# @description: Runs the SSH check: sshd is active, password login is off, and sshd listens on 1022.
# @details:
#   Also reports the firewall ssh service (port 22) as on or off, without failing either way.
# @stdout: one TSV line: ssh-config<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 2 = FAIL.
health-check-ssh-config() {
    local sshd_output zone service_state ports
    # shellcheck source=../../../../../fn/network/is-ssh-port-custom.sh
    declare -F is-ssh-port-custom >/dev/null || source "${DIR_E780CA43AAFE}/../../../../../fn/network/is-ssh-port-custom.sh"
    # shellcheck source=../../../../../fn/network/is-port-listening.sh
    declare -F is-port-listening >/dev/null || source "${DIR_E780CA43AAFE}/../../../../../fn/network/is-port-listening.sh"
    # shellcheck source=../../../../../fn/network/get-firewall-zone.sh
    declare -F get-firewall-zone >/dev/null || source "${DIR_E780CA43AAFE}/../../../../../fn/network/get-firewall-zone.sh"
    # shellcheck source=../../../../../fn/network/is-firewall-service-on.sh
    declare -F is-firewall-service-on >/dev/null || source "${DIR_E780CA43AAFE}/../../../../../fn/network/is-firewall-service-on.sh"

    if ! systemctl is-active --quiet sshd 2>/dev/null; then
        printf 'ssh-config\tFAIL\tsshd is not running\n'
        return 2
    fi

    # The effective settings, not the files: another drop-in can override one.
    sshd_output="$(sshd -T 2>/dev/null)"
    if ! grep -qix 'passwordauthentication no' <<<"${sshd_output}"; then
        printf 'ssh-config\tFAIL\tpassword login is on\n'
        return 2
    fi

    # A custom port is the admin's choice: PodShift leaves it alone.
    if is-ssh-port-custom "${sshd_output}" "22 1022"; then
        ports="$(grep -E '^port ' <<<"${sshd_output}" | sed 's/^port //' | tr '\n' ' ')"
        printf 'ssh-config\tOK\tkey-only login, custom SSH port %snot checked\n' "${ports}"
        return 0
    fi

    if ! is-port-listening 1022; then
        printf 'ssh-config\tFAIL\tsshd is not listening on port 1022\n'
        return 2
    fi

    service_state="unknown, firewalld is not running"
    zone="$(get-firewall-zone)" || zone=""
    if [[ -n "${zone}" ]]; then
        if is-firewall-service-on "${zone}" ssh; then
            service_state="on"
        else
            service_state="off"
        fi
        printf 'ssh-config\tOK\tkey-only login, listening on 1022, ssh service in %s: %s\n' "${zone}" "${service_state}"
        return 0
    fi
    printf 'ssh-config\tOK\tkey-only login, listening on 1022, ssh service: %s\n' "${service_state}"
    return 0
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-ssh-config
