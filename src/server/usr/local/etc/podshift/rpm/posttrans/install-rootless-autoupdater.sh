#!/usr/bin/env bash
# install-rootless-autoupdater.sh
# /usr/local/etc/podshift/rpm/posttrans
# Adds and enables the podman auto-update timer for rootless if not already present

DIR_E8A110D64653="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly DIR_E8A110D64653

install-rootless-autoupdater() {
    local timer_conf timer_file path_conf_dir
    # Load main config for PODSHIFT_RUNTIME_CONF_TEMPLATES
    # shellcheck source=../../conf/main.conf
    # shellcheck source=../../fn/load-podshift-conf-main.sh
    source "${DIR_E8A110D64653}/../../fn/load-podshift-conf-main.sh" --now
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_E8A110D64653}/../../fn/utils/print-warning.sh"

    path_conf_dir="${PODSHIFT_RUNTIME_CONF_TEMPLATES}"
    timer_conf='podman-auto-update.timer.d/override.conf'
    timer_file="/home/podshift/.config/systemd/user/${timer_conf}"

    if [ -f "${timer_file}" ]; then
        echo -e "\tAlready installed"
        return 0
    fi

    echo -e "\nInstalling PodShift auto-update timer..."

    # Precondition: the template must actually exist (also catches an empty
    # PODSHIFT_RUNTIME_CONF_TEMPLATES if main.conf failed to load).
    if [ -z "${path_conf_dir}" ] || [ ! -f "${path_conf_dir}/${timer_conf}" ]; then
        print-warning "auto-update timer template is missing, skipping."
        return 0
    fi

    source "${DIR_E8A110D64653}/../../fn/rootless/set-owner-rootless.sh"

    if ! install -m 0644 "${path_conf_dir}/${timer_conf}" "${timer_file}"; then
        print-warning "failed to install the auto-update timer override."
        return 0
    fi

    set-owner-rootless "${timer_file}" \
        || print-warning "failed to set ownership of the auto-update timer override."

    systemctl --machine="300@.host" --user enable --now podman-auto-update.timer >/dev/null 2>&1 \
        || print-warning "failed to enable the auto-update timer."

    echo -e "\tDone"
    return 0
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && install-rootless-autoupdater
fi
