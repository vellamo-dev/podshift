#!/usr/bin/env bash
# @file: rpm-install.sh
# @source-dir: src/deployment
# @group: deployment
# @category: entry
# @step: PS-DP-0DP
# @description: Entry point that stages the server tree into the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

if [[ -z "${DIR_E791E4A6E1FF:-}" ]]; then
    DIR_E791E4A6E1FF="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E791E4A6E1FF
fi

# @description: Stages the server tree into the build root and generates the RPM file list.
# @arg: $1 - build root directory.
# @arg: $2 - RPM exec directory (where files.list is written).
# @exitcode: 0 on success, 1 on failure.
prepare-files-for-rpm-package() {
    local -r step_tag="PS-DP-0DP"
    local source_dir build_root rpm_exec_dir
    build_root="${1}"
    rpm_exec_dir="${2}"
    source_dir="$(dirname "${DIR_E791E4A6E1FF}")/server"

    # shellcheck source=./fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_E791E4A6E1FF}/fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Preparing files for RPM package..."

    # shellcheck source=./fn/generate-rpm-dirs-list.sh
    declare -F generate-rpm-dirs-list >/dev/null || source "${DIR_E791E4A6E1FF}/fn/generate-rpm-dirs-list.sh"
    # Generate a list of directories
    generate-rpm-dirs-list "${source_dir}"

    # shellcheck source=./fn/deploy-dirs.sh
    declare -F deploy-dirs >/dev/null || source "${DIR_E791E4A6E1FF}/fn/deploy-dirs.sh"
    # Clone directories
    deploy-dirs "${build_root}" "${source_dir}"

    # shellcheck source=./fn/deploy-sh-scripts.sh
    declare -F deploy-sh-scripts >/dev/null || source "${DIR_E791E4A6E1FF}/fn/deploy-sh-scripts.sh"
    # Clone shell scripts
    deploy-sh-scripts "${build_root}" "${source_dir}"

    # shellcheck source=./fn/deploy-files.sh
    declare -F deploy-files >/dev/null || source "${DIR_E791E4A6E1FF}/fn/deploy-files.sh"
    # Clone other files
    deploy-files "${build_root}" "${source_dir}"

    # shellcheck source=./fn/deploy-sh-symlinks.sh
    declare -F deploy-sh-symlinks >/dev/null || source "${DIR_E791E4A6E1FF}/fn/deploy-sh-symlinks.sh"
    # Create extensionless command links
    deploy-sh-symlinks "${build_root}" "${source_dir}"

    # shellcheck source=./fn/generate-files-list-for-rpm.sh
    declare -F generate-files-list-for-rpm >/dev/null || source "${DIR_E791E4A6E1FF}/fn/generate-files-list-for-rpm.sh"
    # Generate files' list for RPM packager
    generate-files-list-for-rpm "${build_root}" "${rpm_exec_dir}/files.list"

    cd "${rpm_exec_dir}"
    print-step-ok "Files ready for RPM package creation"
}

prepare-files-for-rpm-package "${1}" "${2}"
