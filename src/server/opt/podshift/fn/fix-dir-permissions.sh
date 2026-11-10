#!/usr/bin/env bash
# @file: fix-dir-permissions.sh
# @source-dir: src/server/opt/podshift/fn
# @dest-dir: /opt/podshift/fn
# @host-edit: no
# @group: common
# @category: helper
# @description: Restores the SELinux labels of the directories listed in restorecon-dirs.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs restorecon on each directory listed in /opt/podshift/conf/restorecon-dirs.
# @exitcode: 0 always.
fix-dir-permissions() {
    local path_file_dirs_list
    path_file_dirs_list=/opt/podshift/conf/restorecon-dirs
    if [ -f "${path_file_dirs_list}" ]; then
        cat "${path_file_dirs_list}" | while read -r dir; do
            [ -n "$dir" ] && [ -e "/$dir" ] && restorecon -Rv "/$dir" 2>/dev/null || :
        done
    fi
}
