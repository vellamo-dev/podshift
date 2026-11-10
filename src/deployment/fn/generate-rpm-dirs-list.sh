#!/usr/bin/env bash
# @file: generate-rpm-dirs-list.sh
# @source-dir: src/deployment/fn
# @group: deployment
# @category: step
# @step: PS-DP-DRL
# @description: Generates the SELinux restorecon directory list from the source tree.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

if [[ -z "${DIR_C61F78822895:-}" ]]; then
    DIR_C61F78822895="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C61F78822895
fi

# @description: Derives the deployed directory set and writes conf/restorecon-dirs.
# @arg: $1 - source tree directory.
generate-rpm-dirs-list() {
    local -r step_tag="PS-DP-DRL"
    local root_path file_dirs_list path_file_dirs_list
    root_path=$(realpath "$1")
    file_dirs_list=/opt/podshift/conf/restorecon-dirs
    path_file_dirs_list="${root_path}/${file_dirs_list}"
    # shellcheck source=./utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_C61F78822895}/utils/print-step.sh"
    print-step-header "${step_tag}" "Generating directories list..."
    : >"${path_file_dirs_list}"
    cd "${root_path}"
    find . -type f | sed 's|/[^/]*$||' | sed 's|^./|/|' | sort -u | grep -v '^/[^/]*$' >"${path_file_dirs_list}"
    cat "${path_file_dirs_list}"
    print-step-ok
}
