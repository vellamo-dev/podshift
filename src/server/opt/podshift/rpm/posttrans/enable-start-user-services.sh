#!/usr/bin/env bash
# @file: enable-start-user-services.sh
# @source-dir: src/server/opt/podshift/rpm/posttrans
# @dest-dir: /opt/podshift/rpm/posttrans
# @host-edit: no
# @group: posttrans
# @category: step
# @step: PS-PT-USR
# @description: Enables and starts the PodShift user services.
# @details:
#   Applies the user unit enablement preset (90-podshift.preset) and starts each managed user
#   unit in a fixed order. The units are listed once, in the main function, so adding a new unit
#   means adding it to that list and to the preset (apply-user-preset). Sub-item lines follow one
#   repeating pattern for easy machine parsing: User <category> '<item>' <action> <result>, where
#   <result> is always the last word (succeeded or failed).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1E4A9B7C3D6F:-}" ]]; then
    DIR_1E4A9B7C3D6F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1E4A9B7C3D6F
fi

# @description: Enables and starts the PodShift user services.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
enable-start-user-services() {
    local unit
    local -r step_tag="PS-PT-USR"
    local -ra units=(
        systemd-tmpfiles-setup.service
        podman.socket
        podshift-drop.path
        podshift-qdl-validate.path
        podshift-qdl-install.path
        podshift-qdl-remove.path
        podshift-drop-safety.timer
        podman-auto-update.timer
    )
    # shellcheck source=../../fn/utils/print-step-header.sh
    declare -F print-step-header >/dev/null || source "${DIR_1E4A9B7C3D6F}/../../fn/utils/print-step-header.sh"
    print-step-header "${step_tag}" "Enabling and starting user services..."

    if ! id podshift >/dev/null 2>&1; then
        # shellcheck source=../../fn/utils/print-step-skip.sh
        declare -F print-step-skip >/dev/null || source "${DIR_1E4A9B7C3D6F}/../../fn/utils/print-step-skip.sh"
        print-step-skip "User 'podshift' does not exist"
        return 0
    fi

    # shellcheck source=../utils/reload-user-manager.sh
    declare -F reload-user-manager >/dev/null || source "${DIR_1E4A9B7C3D6F}/../utils/reload-user-manager.sh"
    reload-user-manager
    # shellcheck source=../utils/apply-user-preset.sh
    declare -F apply-user-preset >/dev/null || source "${DIR_1E4A9B7C3D6F}/../utils/apply-user-preset.sh"
    apply-user-preset
    # shellcheck source=../utils/start-user-unit.sh
    declare -F start-user-unit >/dev/null || source "${DIR_1E4A9B7C3D6F}/../utils/start-user-unit.sh"
    for unit in "${units[@]}"; do
        start-user-unit "${unit}"
    done

    # shellcheck source=../../fn/utils/print-step-ok.sh
    declare -F print-step-ok >/dev/null || source "${DIR_1E4A9B7C3D6F}/../../fn/utils/print-step-ok.sh"
    print-step-ok
}
