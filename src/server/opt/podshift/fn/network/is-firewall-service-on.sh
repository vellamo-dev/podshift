#!/usr/bin/env bash
# @file: is-firewall-service-on.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Tells whether a firewalld service is on in a zone.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 if a firewalld service is on in a zone, in the permanent configuration (what survives a reload and a reboot).
# @arg: $1 - the zone name.
# @arg: $2 - the service name, for example ssh.
# @exitcode: 0 if the service is on in the zone, 1 if it is off or firewalld cannot be asked.
is-firewall-service-on() {
    local zone service
    zone="${1:-}"
    service="${2:-}"
    [[ -n "${zone}" && -n "${service}" ]] || return 1
    firewall-cmd --permanent --zone="${zone}" --query-service="${service}" >/dev/null 2>&1
}
