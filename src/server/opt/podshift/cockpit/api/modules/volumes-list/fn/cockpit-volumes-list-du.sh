#!/usr/bin/env bash
# @file: cockpit-volumes-list-du.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/volumes-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/volumes-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the disk usage of one folder in bytes, limited to the given seconds.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the disk usage of one folder in bytes, limited to the given seconds.
# @details:
#   Runs du -sb (GNU coreutils). Files that the podshift user cannot read, such as files that a
#   container wrote with another subuid, are skipped by du, so the number can be too small. du then
#   exits non-zero, but its number is still printed. Nothing is printed on a timeout.
# @arg: $1 - folder path.
# @arg: $2 - seconds du may run.
# @stdout: du output, <bytes><TAB><path>, or nothing.
# @exitcode: the du exit code; callers use the output, not the code.
cockpit-volumes-list-du() {
    if command -v timeout >/dev/null 2>&1; then
        timeout "${2-}" du -sb -- "${1-}" 2>/dev/null
    else
        du -sb -- "${1-}" 2>/dev/null
    fi
}
