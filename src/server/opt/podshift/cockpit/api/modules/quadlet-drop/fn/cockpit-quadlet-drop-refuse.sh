#!/usr/bin/env bash
# @file: cockpit-quadlet-drop-refuse.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-drop/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-drop/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Removes the upload file, if any, and prints a refused result.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes the upload file, if any, and prints a refused result.
# @arg: $1 - upload file, or empty.
# @arg: $2 - file name.
# @arg: $3 - problem line, CODE<tab>message.
# @stdout: one JSON object.
# @exitcode: 0 when the result was written, 1 otherwise.
cockpit-quadlet-drop-refuse() {
    [[ -z "${1-}" ]] || rm -f -- "${1}"
    cockpit-quadlet-drop-result "${2-}" "${3-}"
}
