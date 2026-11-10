#!/usr/bin/env bash
# @file: get-firewall-zone.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Prints the firewalld zone of the default-route network interface.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_AFB3CAAF40D5:-}" ]]; then
    DIR_AFB3CAAF40D5="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_AFB3CAAF40D5
fi

# @description: Prints the firewalld zone that holds the network interface of the default route.
# @details:
#   A service is then added to the zone that really faces the network. Falls back to the default
#   zone when the interface has no zone.
# @stdout: the zone name.
# @exitcode: 0 if a zone was found, 1 if firewalld cannot be asked.
get-firewall-zone() {
    local device zone
    # shellcheck source=./nw-device.sh
    declare -F nw-device >/dev/null || source "${DIR_AFB3CAAF40D5}/nw-device.sh"
    zone=""
    device="$(nw-device)"
    if [[ -n "${device}" ]]; then
        zone="$(firewall-cmd --get-zone-of-interface="${device}" 2>/dev/null)" || zone=""
    fi
    [[ "${zone}" != "no zone" ]] || zone=""
    [[ -n "${zone}" ]] || zone="$(firewall-cmd --get-default-zone 2>/dev/null)" || zone=""
    [[ -n "${zone}" ]] || return 1
    echo "${zone}"
}
