#!/usr/bin/env bash
# @file: podshift-version.sh
# @source-dir: src/server/opt/podshift/fn/common
# @dest-dir: /opt/podshift/fn/common
# @host-edit: no
# @group: common
# @category: helper
# @description: Prints the PodShift, Podman and host version details.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E55364727DBB:-}" ]]; then
    DIR_E55364727DBB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E55364727DBB
fi

# @description: Prints the PodShift, Podman, and host version details.
# @stdout: the PodShift version, the host system and the Podman version.
# @stderr: a warning when this is development code.
# @exitcode: 0 always.
podshift-version() {
    local podman_version
    # shellcheck source=./get-podshift-version.sh
    declare -F get-podshift-version >/dev/null || source "${DIR_E55364727DBB}/get-podshift-version.sh"
    # shellcheck source=./get-host-info.sh
    declare -F get-host-info >/dev/null || source "${DIR_E55364727DBB}/get-host-info.sh"
    # shellcheck source=./get-podman-version.sh
    declare -F get-podman-version >/dev/null || source "${DIR_E55364727DBB}/get-podman-version.sh"
    # shellcheck source=../utils/is-podshift-rpm-install.sh
    declare -F is-podshift-rpm-install >/dev/null || source "${DIR_E55364727DBB}/../utils/is-podshift-rpm-install.sh"

    printf 'PodShift v%s\n' "$(get-podshift-version)"
    printf '%s\n' "$(get-host-info)"
    podman_version="$(get-podman-version)"
    [[ -n "${podman_version}" ]] && printf 'Podman v%s\n' "${podman_version}"

    if ! is-podshift-rpm-install; then
        # shellcheck source=../utils/is-interactive-output.sh
        declare -F is-interactive-output >/dev/null || source "${DIR_E55364727DBB}/../utils/is-interactive-output.sh"
        if is-interactive-output 2; then
            printf '\033[1;33mWarning: this is development code, not a working application.\033[0m\n' >&2
        else
            printf 'Warning: this is development code, not a working application.\n' >&2
        fi
    fi
    return 0
}
