#!/usr/bin/env bash
# @file: is-host-reachable.sh
# @source-dir: src/server/opt/podshift/fn/network
# @dest-dir: /opt/podshift/fn/network
# @host-edit: no
# @group: network
# @category: helper
# @description: Tells whether a host answers over HTTPS within 3 seconds.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 if https://<host>/ answers within 3 seconds; any HTTP status counts as an answer.
# @details:
#   Used by podshift network check and the registries health check, so both probe the same way.
#   The caller checks that curl is installed.
# @arg: $1 - host name, for example quay.io.
# @exitcode: 0 if the host answered, 1 otherwise.
is-host-reachable() {
    local host
    host="${1}"
    curl -s -o /dev/null --max-time 3 "https://${host}/" 2>/dev/null
}
