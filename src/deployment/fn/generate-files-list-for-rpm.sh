#!/usr/bin/env bash
# @file: generate-files-list-for-rpm.sh
# @dir: src/deployment/fn
# @group: deployment
# @prefix: PS-DP
# @id: FLL
# @description: Generates the RPM %files list from the build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

# @description: Writes the list of deployed files (files.list) for the %files directive.
# @param: $1 - build root directory.
# @param: $2 - output files.list path.
generate-files-list-for-rpm() {
    local -r step_tag="PS-DP-FLL"
    local path_build path_files_list
    path_build=$(realpath -m "$1")
    path_files_list="$2"
    print-step-header "${step_tag}" "Generating files list..."
    : >"${path_files_list}"
    find "${path_build}" -type f -printf '/%P\n' | sort >>"${path_files_list}"
    cat "${path_files_list}"
    print-step-ok
}