#!/usr/bin/env bash
# @file: generate-rpm-dirs-list.sh
# @dir: src/deployment/fn
# @group: deployment
# @prefix: PS-DP
# @id: DRL
# @description: Generates the SELinux restorecon directory list from the source tree.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

# @description: Derives the deployed directory set and writes conf/restorecon-dirs.
# @param: $1 - source tree directory.
generate-rpm-dirs-list() {
    local -r step_tag="PS-DP-DRL"
    local root_path file_dirs_list path_file_dirs_list
    root_path=$(realpath "$1")
    file_dirs_list=/usr/local/etc/podshift/conf/restorecon-dirs
    path_file_dirs_list="${root_path}/${file_dirs_list}"
    print-step-header "${step_tag}" "Generating directories list..."
    : >"${path_file_dirs_list}"
    cd "${root_path}"
    find . -type f | sed 's|/[^/]*$||' | sed 's|^./|/|' | sort -u | grep -v '^/[^/]*$' >"${path_file_dirs_list}"
    cat "${path_file_dirs_list}"
    print-step-ok
}