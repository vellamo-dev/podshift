#!/usr/bin/env bash
# @file: preun.sh
# @source-dir: src/server/opt/podshift/rpm
# @dest-dir: /opt/podshift/rpm
# @host-edit: no
# @group: preun
# @category: entry
# @step: PS-PR-0PR
# @description: Coordinates the pre-uninstall steps.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# This script runs before the PodShift package files are removed. It is
# invoked from the RPM %preun scriptlet, so the package's own scripts are
# still available to source. It never removes user data; it only disables
# the PodShift-managed services. On upgrade it does nothing, because the
# package is still installed.

if [[ -z "${DIR_2B7E9A4C6F1D:-}" ]]; then
    DIR_2B7E9A4C6F1D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_2B7E9A4C6F1D
fi

# @description: Coordinates the pre-uninstall steps.
podshift-rpm-do-preun() {
    local rpm_dir action
    action="${1}"
    rpm_dir="${2}"
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PR-0PR"
    # shellcheck source=../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${rpm_dir}/../fn/utils/print-step.sh"

    print-step-header "${step_tag}" "Preparing system (preun)..."
    echo -e "\tUninstall type: ${action}"

    # Upgrade: the package is still installed, nothing to undo.
    if [[ "${action}" -gt 0 ]]; then
        print-step-skip "upgrade, nothing to undo"
        return 0
    fi

    # Disable the podman auto-update timer
    # shellcheck source=./preun/remove-podman-auto-update.sh
    source "${rpm_dir}/preun/remove-podman-auto-update.sh"
    remove-podman-auto-update
}

podshift-rpm-do-preun "${1:-0}" "${DIR_2B7E9A4C6F1D}"
