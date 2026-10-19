#!/usr/bin/env bash
# @file: install-rootless-autoupdater.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: AUT
# @description: Installs and enables the Podman auto-update timer
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
# Adds and enables the podman auto-update timer for rootless if not already present

if [[ -z "${DIR_E8A110D64653:-}" ]]; then
    DIR_E8A110D64653="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E8A110D64653
fi

install-rootless-autoupdater() {
    # Reserved step identity (matches @prefix and @id in the header).
    local -r step_prefix="PS-PT"
    local -r step_id="AUT"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_E8A110D64653}/../../fn/utils/print-step.sh"
    local timer_conf timer_file path_conf_dir
    # Load main config for PODSHIFT_RUNTIME_CONF_TEMPLATES
    # shellcheck source=../../conf/main.conf
    # shellcheck source=../../fn/load-podshift-conf-main.sh
    source "${DIR_E8A110D64653}/../../fn/load-podshift-conf-main.sh" --now

    path_conf_dir="${PODSHIFT_RUNTIME_CONF_TEMPLATES}"
    timer_conf='podman-auto-update.timer.d/override.conf'
    timer_file="/home/podshift/.config/systemd/user/${timer_conf}"

    if [ -f "${timer_file}" ]; then
        echo -e "\tAlready installed"
        return 0
    fi

    print-step-header "Installing PodShift auto-update timer..."

    # Precondition: the template must actually exist (also catches an empty
    # PODSHIFT_RUNTIME_CONF_TEMPLATES if main.conf failed to load).
    if [ -z "${path_conf_dir}" ] || [ ! -f "${path_conf_dir}/${timer_conf}" ]; then
        print-step-warn "auto-update timer template is missing, skipping."
        return 0
    fi

    source "${DIR_E8A110D64653}/../../fn/rootless/set-owner-rootless.sh"

    if ! install -m 0644 "${path_conf_dir}/${timer_conf}" "${timer_file}"; then
        print-step-warn "failed to install the auto-update timer override."
        return 0
    fi

    set-owner-rootless "${timer_file}" \
        || print-step-warn "failed to set ownership of the auto-update timer override."

    systemctl --machine="300@.host" --user enable --now podman-auto-update.timer >/dev/null 2>&1 \
        || print-step-warn "failed to enable the auto-update timer."

    print-step-ok
    return 0
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && install-rootless-autoupdater
fi
