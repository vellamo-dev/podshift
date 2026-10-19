#!/usr/bin/env bash
# @file: install-rootless-profile.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: PRF
# @description: Creates the shell profiles for the podshift user
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Configures the shell initialisation files for the dedicated podshift user.

if [[ -z "${DIR_A8B677A69011:-}" ]]; then
    DIR_A8B677A69011="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A8B677A69011
fi

# @description: Creates the shell profiles for the podshift user.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
install-rootless-profile() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-PRF"
    local file_bashrc file_profile tpl_profile tpl_bashrc bashrc_skeleton
    bashrc_skeleton="/etc/skel/.bashrc"
    file_bashrc="/home/podshift/.bashrc"
    file_profile="/home/podshift/.bash_profile"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_A8B677A69011}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Creating bash profile for podshift..."
    # Load main config for PODSHIFT_RUNTIME_CONF_TEMPLATES
    # shellcheck source=../../fn/load-podshift-conf-main.sh
    source "${DIR_A8B677A69011}/../../fn/load-podshift-conf-main.sh" --now

    tpl_bashrc="${PODSHIFT_RUNTIME_CONF_TEMPLATES}/tpl.bashrc"
    tpl_profile="${PODSHIFT_RUNTIME_CONF_TEMPLATES}/tpl.bash_profile"

    # .bashrc: create if missing, then ensure the rootless config is sourced.
    if [ ! -f "${file_bashrc}" ]; then
        if [ -f "${bashrc_skeleton}" ]; then
            echo -e "\tCloning .bashrc"
            install -m 0644 "${bashrc_skeleton}" "${file_bashrc}"
        else
            echo -e "\tCreating .bashrc"
            : >"${file_bashrc}"
            chmod 644 "${file_bashrc}"
        fi
    fi
    if ! grep -qF 'load-rootless-conf.sh' "${file_bashrc}"; then
        echo -e "\tUpdating .bashrc"
        [ -s "${file_bashrc}" ] && [ -n "$(tail -c1 "${file_bashrc}")" ] && echo >>"${file_bashrc}"
        cat "${tpl_bashrc}" >>"${file_bashrc}"
    fi
    # shellcheck source=../../fn/rootless/set-owner-rootless.sh
    source "${DIR_A8B677A69011}/../../fn/rootless/set-owner-rootless.sh"
    set-owner-rootless "${file_bashrc}"

    # .bash_profile: create if missing, otherwise ensure ~/.bashrc is sourced.
    if [ ! -f "${file_profile}" ]; then
        echo -e "\tCreating .bash_profile"
        cat "${tpl_profile}" >"${file_profile}"
    elif ! grep -qF '~/.bashrc' "${file_profile}"; then
        echo -e "\tUpdating .bash_profile"
        [ -s "${file_profile}" ] && [ -n "$(tail -c1 "${file_profile}")" ] && echo >>"${file_profile}"
        cat "${tpl_profile}" >>"${file_profile}"
    fi
    set-owner-rootless "${file_profile}"

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && install-rootless-profile
fi
