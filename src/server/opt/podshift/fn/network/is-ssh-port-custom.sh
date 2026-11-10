#!/usr/bin/env bash
# @file: is-ssh-port-custom.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @unit-test: yes
# @description: Tells whether sshd listens on a port outside an allowed list.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 if the sshd settings hold a port that is not in the allowed list.
# @arg: $1 - the output of sshd -T (lines like "port 22").
# @arg: $2 - the allowed ports, separated by spaces (for example "22 1022").
# @exitcode: 0 if a port outside the list is found, 1 otherwise (also when there is no port line).
is-ssh-port-custom() {
    local sshd_output allowed line port
    sshd_output="${1:-}"
    allowed=" ${2:-} "
    while IFS= read -r line; do
        # sshd -T emits keywords in mixed case (Port, PasswordAuthentication): lowercase for a case-insensitive match.
        line="${line,,}"
        case "${line}" in
            "port "*)
                port="${line#port }"
                [[ "${allowed}" == *" ${port} "* ]] || return 0
                ;;
        esac
    done <<<"${sshd_output}"
    return 1
}
