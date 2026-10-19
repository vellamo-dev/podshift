#!/usr/bin/env bash
# install-rootless-podman-auth-file.sh
# /usr/local/etc/podshift/rpm/posttrans
# Creating prerequisites for configuring podman authorization.

# Establishes the necessary authentication infrastructure for the podshift
# user so that registry logins and automated container updates can
# function correctly in a rootless Podman environment.

if [[ -z "${DIR_86D4F73B62E0:-}" ]]; then
    DIR_86D4F73B62E0="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_86D4F73B62E0
fi

install-rootless-podman-auth-file() {
    local dir_config auth_file auth_file_dir override_file dir_podman_aus
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_86D4F73B62E0}/../../fn/utils/print-warning.sh"
    # shellcheck source=../../fn/rootless/set-owner-rootless.sh
    source "${DIR_86D4F73B62E0}/../../fn/rootless/set-owner-rootless.sh"

    dir_config="/home/podshift/.config"
    auth_file="${dir_config}/containers/auth.json"
    auth_file_dir="$(dirname "${auth_file}")"
    dir_podman_aus="${dir_config}/systemd/user/podman-auto-update.service.d"
    override_file="${dir_podman_aus}/override.conf"

    echo -e "\nCreating prerequisites for podman authorization..."

    if [ ! -f "${auth_file}" ]; then
        echo -e "\tCreating authorization file for rootless podman..."
        if ! mkdir -p "${auth_file_dir}" || ! echo '{}' >"${auth_file}" || ! chmod 600 "${auth_file}"; then
            print-warning "failed to create the podman authorization file."
        fi
    fi

    if [ ! -f "${override_file}" ]; then
        echo -e "\tCreating configuration override file for rootless podman..."
        if ! mkdir -p "${dir_podman_aus}" || ! printf '%s\n' '[Service]' "Environment=REGISTRY_AUTH_FILE=${auth_file}" >"${override_file}"; then
            print-warning "failed to create the podman auto-update override."
        fi
    fi

    set-owner-rootless "${dir_config}"

    echo -e "\tDone"
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && install-rootless-podman-auth-file
fi
