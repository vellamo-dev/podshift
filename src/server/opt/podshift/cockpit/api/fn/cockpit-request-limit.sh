#!/usr/bin/env bash
# @file: cockpit-request-limit.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Prints the largest request size in bytes that one action accepts.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the request size bound of one action: 131072 for quadlet-drop, else 65536.
# @details:
#   quadlet-drop carries a base64 file of up to 50 KB, so its request may be up to 131072 bytes.
#   Every other action, and an unknown name, keeps the 65536-byte bound.
# @arg: $1 - action name.
# @stdout: the bound in bytes.
# @exitcode: 0 always.
cockpit-request-limit() {
    case "${1-}" in
        quadlet-drop) printf '131072\n' ;;
        *) printf '65536\n' ;;
    esac
    return 0
}
