#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/ssh
# @dest-dir: /opt/podshift/cli/modules/ssh
# @host-edit: no
# @group: cli
# @category: entry
# @description: Turns the firewall's ssh service (port 22) on or off, while sshd keeps listening on ports 22 and 1022.
# @run-as: root
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Dispatches the ssh subcommands.
# @arg: $1 - subcommand (port).
# @exitcode: 0 on success, 1 on failure.
podshift-ssh() {
    case "${1:-}" in
        port) shift; podshift-ssh-port "$@" ;;
        *) echo "Unknown ssh subcommand: ${1:-}. See 'podshift --help ssh'." >&2; return 1 ;;
    esac
}

# @description: Turns the firewall ssh service off (port 1022) or on (port 22) in the zone of the default-route interface.
# @details:
#   The sshd ports never change.
# @arg: $@ - 22 or 1022, and an optional --force that skips the listening check.
# @stdout: the result.
# @stderr: errors and the warning.
# @exitcode: 0 on success or when there is nothing to do, 1 on failure or a wrong argument.
podshift-ssh-port() {
    local port force arg zone
    port=""
    force=0

    for arg in "$@"; do
        case "${arg}" in
            22|1022) port="${arg}" ;;
            --force) force=1 ;;
            *) echo "Usage: podshift ssh port 22|1022 [--force]" >&2; return 1 ;;
        esac
    done
    if [[ -z "${port}" ]]; then
        echo "Usage: podshift ssh port 22|1022 [--force]" >&2
        return 1
    fi

    # shellcheck source=../../../fn/utils/require-admin.sh
    declare -F require-admin >/dev/null || source /opt/podshift/fn/utils/require-admin.sh
    require-admin || return 1

    # A custom SSH port is the admin's choice: hands off.
    # shellcheck source=../../../fn/network/is-ssh-port-custom.sh
    declare -F is-ssh-port-custom >/dev/null || source /opt/podshift/fn/network/is-ssh-port-custom.sh
    if is-ssh-port-custom "$(sshd -T 2>/dev/null)" "22 1022"; then
        echo "custom SSH port found, nothing changed" >&2
        return 1
    fi

    # shellcheck source=../../../fn/network/get-firewall-zone.sh
    declare -F get-firewall-zone >/dev/null || source /opt/podshift/fn/network/get-firewall-zone.sh
    zone="$(get-firewall-zone)" || zone=""
    if [[ -z "${zone}" ]]; then
        echo "Cannot find the firewall zone. Is firewalld running?" >&2
        return 1
    fi

    case "${port}" in
        1022) podshift-ssh-port-1022 "${zone}" "${force}" ;;
        22)   podshift-ssh-port-22 "${zone}" ;;
    esac
}

# @description: Checks that sshd listens on 1022, opens port 1022 in a zone if needed, then turns the ssh service off.
# @arg: $1 - the firewall zone.
# @arg: $2 - 1 to skip the listening check, 0 to do it.
# @exitcode: 0 on success or when it was already off, 1 on failure.
podshift-ssh-port-1022() {
    local zone force
    zone="${1}"
    force="${2}"

    # shellcheck source=../../../fn/network/is-firewall-service-on.sh
    declare -F is-firewall-service-on >/dev/null || source /opt/podshift/fn/network/is-firewall-service-on.sh
    if ! is-firewall-service-on "${zone}" ssh; then
        echo "The ssh service is already off in zone ${zone}. Nothing to do."
        return 0
    fi

    if [[ "${force}" -ne 1 ]]; then
        # shellcheck source=../../../fn/network/is-port-listening.sh
        declare -F is-port-listening >/dev/null || source /opt/podshift/fn/network/is-port-listening.sh
        if ! is-port-listening 1022; then
            echo "sshd is not listening on port 1022, nothing changed. Check 'systemctl status sshd' and the SELinux port label, or use --force." >&2
            return 1
        fi
    fi

    # shellcheck source=../../../fn/utils/print-warning.sh
    declare -F print-warning >/dev/null || source /opt/podshift/fn/utils/print-warning.sh
    print-warning "This checks only this machine. Test ssh -p 1022 from another terminal first."

    # Port 1022 must be open in the firewall before port 22 closes. A server
    # install opens it with the podshift service; on any other install, open
    # only port 1022/tcp here.
    if ! is-firewall-service-on "${zone}" podshift \
        && ! firewall-cmd --permanent --zone="${zone}" --query-port=1022/tcp >/dev/null 2>&1; then
        if ! firewall-cmd --permanent --zone="${zone}" --add-port=1022/tcp >/dev/null 2>&1; then
            echo "Failed to open port 1022 in zone ${zone}, nothing changed." >&2
            return 1
        fi
        echo "Port 1022 is now open in zone ${zone}."
    fi

    if firewall-cmd --permanent --zone="${zone}" --remove-service=ssh >/dev/null 2>&1 \
        && firewall-cmd --reload >/dev/null 2>&1; then
        echo "The ssh service is now off in zone ${zone}. SSH on port 1022 stays open."
        return 0
    fi
    echo "Failed to turn the ssh service off in zone ${zone}." >&2
    return 1
}

# @description: Turns the ssh service on in a zone.
# @arg: $1 - the firewall zone.
# @exitcode: 0 on success or when it was already on, 1 on failure.
podshift-ssh-port-22() {
    local zone
    zone="${1}"

    # shellcheck source=../../../fn/network/is-firewall-service-on.sh
    declare -F is-firewall-service-on >/dev/null || source /opt/podshift/fn/network/is-firewall-service-on.sh
    if is-firewall-service-on "${zone}" ssh; then
        echo "The ssh service is already on in zone ${zone}. Nothing to do."
        return 0
    fi

    if firewall-cmd --permanent --zone="${zone}" --add-service=ssh >/dev/null 2>&1 \
        && firewall-cmd --reload >/dev/null 2>&1; then
        echo "The ssh service is now on in zone ${zone}. SSH on port 22 is open."
        return 0
    fi
    echo "Failed to turn the ssh service on in zone ${zone}." >&2
    return 1
}

podshift-ssh "$@"
