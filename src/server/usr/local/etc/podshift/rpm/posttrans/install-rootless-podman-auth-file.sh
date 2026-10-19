#!/usr/bin/env bash
# @file: install-rootless-podman-auth-file.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: PAF
# @description: Creates the Podman auth file and auto-update override
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Creating prerequisites for configuring podman authorization.
#
# Establishes the necessary authentication infrastructure for the podshift
# user so that registry logins and automated container updates can
# function correctly in a rootless Podman environment.

if [[ -z "${DIR_86D4F73B62E0:-}" ]]; then
    DIR_86D4F73B62E0="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_86D4F73B62E0
fi

# @description: Creates the Podman auth file and auto-update override.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
install-rootless-podman-auth-file() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-PAF"
    local dir_config auth_file auth_file_dir override_file dir_podman_aus
    dir_config="/home/podshift/.config"
    auth_file="${dir_config}/containers/auth.json"
    dir_podman_aus="${dir_config}/systemd/user/podman-auto-update.service.d"
    override_file="${dir_podman_aus}/override.conf"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_86D4F73B62E0}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Creating prerequisites for podman authorization..."
    auth_file_dir="$(dirname "${auth_file}")"

    if [ ! -f "${auth_file}" ]; then
        echo -e "\tCreating authorization file for rootless podman..."
        if ! mkdir -p "${auth_file_dir}" || ! echo '{}' >"${auth_file}" || ! chmod 600 "${auth_file}"; then
            print-step-warn "failed to create the podman authorization file."
        fi
    fi

    if [ ! -f "${override_file}" ]; then
        echo -e "\tCreating configuration override file for rootless podman..."
        if ! mkdir -p "${dir_podman_aus}" || ! printf '%s\n' '[Service]' "Environment=REGISTRY_AUTH_FILE=${auth_file}" >"${override_file}"; then
            print-step-warn "failed to create the podman auto-update override."
        fi
    fi

    # shellcheck source=../../fn/rootless/set-owner-rootless.sh
    source "${DIR_86D4F73B62E0}/../../fn/rootless/set-owner-rootless.sh"
    set-owner-rootless "${dir_config}"

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && install-rootless-podman-auth-file
fi
