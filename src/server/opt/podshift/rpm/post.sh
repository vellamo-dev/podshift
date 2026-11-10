#!/usr/bin/env bash
# @file: post.sh
# @source-dir: src/server/opt/podshift/rpm
# @dest-dir: /opt/podshift/rpm
# @host-edit: no
# @group: post
# @category: entry
# @step: PS-PO-0PO
# @description: Coordinates the post-install steps.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# This script prepares the system after the PodShift package has been
# installed or upgraded. Instead of putting all logic into one giant
# post-script, the work is split into many small, focused scripts.
# This main script coordinates their execution.

if [[ -z "${DIR_AB0D2891B52F:-}" ]]; then
    DIR_AB0D2891B52F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_AB0D2891B52F
fi

# @description: Coordinates the post-install steps.
podshift-rpm-do-post() {
    local rpm_dir action
    action="${1}"
    rpm_dir="${2}"
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PO-0PO"
    # shellcheck source=../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${rpm_dir}/../fn/utils/print-step.sh"

    print-step-header "${step_tag}" "Preparing system (post)..."
    echo -e "\tInstall mode: ${action}"
    # shellcheck source=../fn/utils/is-install-type-desktop.sh
    declare -F is-install-type-desktop >/dev/null || source "${rpm_dir}/../fn/utils/is-install-type-desktop.sh"
    if is-install-type-desktop; then
        echo -e "\tInstall type: desktop"
    else
        echo -e "\tInstall type: server"
    fi

    # Trigger creation of directories if needed
    # shellcheck source=./post/trigger-rootless-dirs-update.sh
    source "${rpm_dir}/post/trigger-rootless-dirs-update.sh"
    trigger-rootless-dirs-update

    # Enable NetworkManager
    # shellcheck source=./post/enable-nw-manager.sh
    source "${rpm_dir}/post/enable-nw-manager.sh"
    enable-nw-manager

}

podshift-rpm-do-post "${1:-0}" "${DIR_AB0D2891B52F}"
