#!/usr/bin/env bash
# @file: enable-start-user-services.sh
# @dir: /opt/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: USR
# @description: Enables and starts the PodShift user services
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Applies the user unit enablement preset (90-podshift.preset) and starts
# each managed user unit. Every unit has its own function, called from the
# main function, so adding a new unit means adding one function and one call.
#
# Sub-item lines follow one repeating pattern for easy machine parsing:
#   User <category> '<item>' <action> <result>
# where <result> is always the last word (succeeded or failed).

if [[ -z "${DIR_1E4A9B7C3D6F:-}" ]]; then
    DIR_1E4A9B7C3D6F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1E4A9B7C3D6F
fi

# @description: Starts a user unit and reports the result.
# @param: $1 - unit name
start-user-unit() {
    local unit error
    unit="${1}"
    if error="$(systemctl --machine="300@.host" --user start "${unit}" 2>&1)"; then
        echo -e "\tUser service '${unit}' start succeeded"
    else
        print-step-warn "User service '${unit}' start failed"
        [[ -n "${error}" ]] && echo -e "\t  ${error}" >&2
    fi
}

# @description: Reloads the podshift user manager.
reload-user-manager() {
    if systemctl --machine="300@.host" --user daemon-reload >/dev/null 2>&1; then
        echo -e "\tUser manager 'user@300' reload succeeded"
    else
        print-step-warn "User manager 'user@300' reload failed"
    fi
}

# @description: Applies the user unit enablement preset.
apply-user-preset() {
    if systemctl --machine="300@.host" --user preset \
        systemd-tmpfiles-setup.service \
        podman.socket \
        podman-auto-update.timer \
        podshift-drop.path \
        podshift-drop-safety.timer >/dev/null 2>&1; then
        echo -e "\tUser presets '90-podshift.preset' apply succeeded"
    else
        print-step-warn "User presets '90-podshift.preset' apply failed"
    fi
}

# @description: Starts the user systemd-tmpfiles-setup service.
start-systemd-tmpfiles-setup() {
    start-user-unit "systemd-tmpfiles-setup.service"
}

# @description: Starts the rootless Podman socket.
start-podman-socket() {
    start-user-unit "podman.socket"
}

# @description: Starts the Podman auto-update timer.
start-podman-auto-update-timer() {
    start-user-unit "podman-auto-update.timer"
}

# @description: Starts the PodShift drop directory watcher.
start-podshift-drop-path() {
    start-user-unit "podshift-drop.path"
}

# @description: Starts the PodShift drop safety sweep timer.
start-podshift-drop-safety-timer() {
    start-user-unit "podshift-drop-safety.timer"
}

# @description: Enables and starts the PodShift user services.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
enable-start-user-services() {
    local -r step_tag="PS-PT-USR"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_1E4A9B7C3D6F}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Enabling and starting user services..."

    if ! id podshift >/dev/null 2>&1; then
        print-step-skip "User 'podshift' does not exist"
        return 0
    fi

    reload-user-manager
    apply-user-preset
    start-systemd-tmpfiles-setup
    start-podman-socket
    start-podshift-drop-path
    start-podshift-drop-safety-timer
    start-podman-auto-update-timer

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && enable-start-user-services
fi
