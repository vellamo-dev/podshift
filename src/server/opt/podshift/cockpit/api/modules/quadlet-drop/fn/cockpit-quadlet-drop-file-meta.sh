#!/usr/bin/env bash
# @file: cockpit-quadlet-drop-file-meta.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-drop/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-drop/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the owner, group and octal mode of one file, as "owner group mode".
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the owner, group and octal mode of one file, as "owner group mode".
# @arg: $1 - file path.
# @stdout: for example "podshift podshift 644".
# @exitcode: the stat exit code.
cockpit-quadlet-drop-file-meta() {
    stat -c '%U %G %a' -- "${1}" 2>/dev/null || stat -f '%Su %Sg %Lp' -- "${1}" 2>/dev/null
}
