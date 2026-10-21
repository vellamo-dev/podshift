#!/usr/bin/env bash
# @file: rpm-install.sh
# @dir: src/deployment
# @group: deployment
# @prefix: PS-DP
# @id: 0DP
# @description: Entry point that stages the server tree into the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

RI_SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly RI_SCRIPT_DIR

# @description: Stages the server tree into the build root and generates the RPM file list.
# @param: $1 - build root directory.
# @param: $2 - RPM exec directory (where files.list is written).
# @exitcode: 0 on success, 1 on failure.
prepare-files-for-rpm-package() {
    local -r step_tag="PS-DP-0DP"
    local source_dir build_root rpm_exec_dir
    build_root="${1}"
    rpm_exec_dir="${2}"
    source_dir="$(dirname "${RI_SCRIPT_DIR}")/server"

    source "${RI_SCRIPT_DIR}/fn/_load.sh" || exit 1
    print-step-header "${step_tag}" "Preparing files for RPM package..."

    # Generate a list of directories
    generate-rpm-dirs-list "${source_dir}"

    # Clone directories
    deploy-dirs "${build_root}" "${source_dir}"

    # Clone shell scripts
    deploy-sh-scripts "${build_root}" "${source_dir}"

    # Clone other files
    deploy-files "${build_root}" "${source_dir}"

    # Generate files' list for RPM packager
    generate-files-list-for-rpm "${build_root}" "${rpm_exec_dir}/files.list"

    cd "${rpm_exec_dir}"
    print-step-ok "Files ready for RPM package creation"
}

prepare-files-for-rpm-package "${1}" "${2}"
