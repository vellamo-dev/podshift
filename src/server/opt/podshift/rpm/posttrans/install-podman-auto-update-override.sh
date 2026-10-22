#!/usr/bin/env bash
# @file: install-podman-auto-update-override.sh
# @dir: /opt/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: OVR
# @description: Installs the Podman auto-update timer override
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Installs the rootless podman-auto-update.timer.d/override.conf.
# Enablement and start are handled by enable-start-user-services.sh.

if [[ -z "${DIR_E8A110D64653:-}" ]]; then
    DIR_E8A110D64653="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E8A110D64653
fi

# @description: Installs the Podman auto-update timer override.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
install-podman-auto-update-override() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-OVR"
    local timer_conf timer_file template_dir
    timer_conf='podman-auto-update.timer.d/override.conf'
    timer_file="/home/podshift/.config/systemd/user/${timer_conf}"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_E8A110D64653}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Installing the Podman auto-update timer override..."
    # Load main config for PODSHIFT_RUNTIME_CONF_TEMPLATES
    # shellcheck source=../../fn/load-podshift-conf-main.sh
    source "${DIR_E8A110D64653}/../../fn/load-podshift-conf-main.sh" --now

    template_dir="${PODSHIFT_RUNTIME_CONF_TEMPLATES:-}"

    if [[ -f "${timer_file}" ]]; then
        echo -e "\tUser override '${timer_conf}' install succeeded"
    elif [[ -z "${template_dir}" || ! -f "${template_dir}/${timer_conf}" ]]; then
        print-step-warn "User override '${timer_conf}' install failed"
    else
        # shellcheck source=../../fn/rootless/set-owner-rootless.sh
        source "${DIR_E8A110D64653}/../../fn/rootless/set-owner-rootless.sh"
        if install -m 0644 "${template_dir}/${timer_conf}" "${timer_file}" \
            && set-owner-rootless "${timer_file}"; then
            echo -e "\tUser override '${timer_conf}' install succeeded"
        else
            print-step-warn "User override '${timer_conf}' install failed"
        fi
    fi

    print-step-ok
    return 0
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && install-podman-auto-update-override
fi
