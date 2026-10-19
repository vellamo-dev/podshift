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
# Creating prerequisites for configuring podman authorization.

# Establishes the necessary authentication infrastructure for the podshift
# user so that registry logins and automated container updates can
# function correctly in a rootless Podman environment.

if [[ -z "${DIR_86D4F73B62E0:-}" ]]; then
    DIR_86D4F73B62E0="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_86D4F73B62E0
fi

install-rootless-podman-auth-file() {
    # Reserved step identity (matches @prefix and @id in the header).
    local -r step_prefix="PS-PT"
    local -r step_id="PAF"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_86D4F73B62E0}/../../fn/utils/print-step.sh"
    local dir_config auth_file auth_file_dir override_file dir_podman_aus
    # shellcheck source=../../fn/rootless/set-owner-rootless.sh
    source "${DIR_86D4F73B62E0}/../../fn/rootless/set-owner-rootless.sh"

    dir_config="/home/podshift/.config"
    auth_file="${dir_config}/containers/auth.json"
    auth_file_dir="$(dirname "${auth_file}")"
    dir_podman_aus="${dir_config}/systemd/user/podman-auto-update.service.d"
    override_file="${dir_podman_aus}/override.conf"

    print-step-header "Creating prerequisites for podman authorization..."

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

    set-owner-rootless "${dir_config}"

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && install-rootless-podman-auth-file
fi
