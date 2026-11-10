#!/usr/bin/env bash
# @file: is-port-listening.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Tells whether something on this machine listens on a TCP port.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3C1A5DC7C19D:-}" ]]; then
    DIR_3C1A5DC7C19D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3C1A5DC7C19D
fi

# @description: Returns 0 if a TCP port is listening on this machine, read from ss -tln; it cannot see an outside firewall.
# @arg: $1 - the port number.
# @exitcode: 0 if the port is listening, 1 otherwise.
is-port-listening() {
    local port
    port="${1:-}"
    # shellcheck source=./is-port-in-ss-list.sh
    declare -F is-port-in-ss-list >/dev/null || source "${DIR_3C1A5DC7C19D}/is-port-in-ss-list.sh"
    is-port-in-ss-list "$(ss -tln 2>/dev/null)" "${port}"
}
