#!/usr/bin/env bash
# @file: cockpit-overview-ssh-port.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Extracts the listening SSH port numbers from sshd -T output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints unique SSH port numbers from sshd -T text, separated by a comma and a space.
# @details:
#   Only lines of the form "port <number>" are used, in any letter case. Ports are sorted numerically and
#   duplicates are dropped. When no port is found, nothing is printed.
# @arg: $1 - optional sshd -T text; when omitted, the text is read from stdin.
# @stdout: one or more port numbers, for example 1022 or 22, 1022.
# @exitcode: 0 when at least one port was printed, 1 otherwise.
cockpit-overview-ssh-port() {
    local raw ports
    raw="${1-}"
    if [[ -z "${raw}" ]]; then
        raw="$(cat)"
    fi
    ports="$(printf '%s\n' "${raw}" | awk '
        tolower($1) == "port" && $2 ~ /^[0-9]+$/ { if (!seen[$2]++) ports[++n] = $2 + 0 }
        END {
            if (n == 0) exit 1
            for (i = 1; i <= n; i++) {
                for (j = i + 1; j <= n; j++) {
                    if (ports[j] < ports[i]) {
                        t = ports[i]; ports[i] = ports[j]; ports[j] = t
                    }
                }
            }
            out = ports[1]
            for (i = 2; i <= n; i++) out = out ", " ports[i]
            print out
        }
    ')" || return 1
    [[ -n "${ports}" ]] || return 1
    printf '%s\n' "${ports}"
    return 0
}
