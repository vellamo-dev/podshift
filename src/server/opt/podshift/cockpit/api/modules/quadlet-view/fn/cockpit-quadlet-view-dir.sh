#!/usr/bin/env bash
# @file: cockpit-quadlet-view-dir.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-view/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-view/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_8B3B63F3D6C3:-}" ]]; then
    DIR_8B3B63F3D6C3="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_8B3B63F3D6C3
fi

# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @details:
#   Uses PODSHIFT_PODMAN_QUADLETS_DIR, usually /home/podshift/.config/containers/systemd, where
#   podman quadlet install puts the files. When main.conf does not set it, the default
#   ~/.config/containers/systemd of the current (podshift) user is used.
# @stdout: the directory path, or nothing when it is not known.
# @exitcode: 0 always.
cockpit-quadlet-view-dir() {
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_8B3B63F3D6C3}/../../../../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main 2>/dev/null || true
    fi
    if [[ -n "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        printf '%s\n' "${PODSHIFT_PODMAN_QUADLETS_DIR}"
    elif [[ -n "${HOME:-}" ]]; then
        printf '%s\n' "${HOME}/.config/containers/systemd"
    fi
    return 0
}
