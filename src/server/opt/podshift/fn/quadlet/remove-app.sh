#!/usr/bin/env bash
# @file: remove-app.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Removes an installed application, for example one that is only partly installed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes an installed application with podman quadlet rm, and only logs a failure.
# @details:
#   Does nothing if the application folder is not in the quadlets directory. Otherwise it runs
#   "podman quadlet rm --force --recursive <app>", which removes every file of the application and
#   its folder, and reloads systemd. Podman does not see an empty folder as an application, so an
#   empty folder is removed with rmdir. A failure is only logged, never returned: the caller is
#   already handling a failed install.
# @arg: $1 - application name.
# @arg: $2 - directory where Podman installs quadlets.
# @exitcode: 0 always.
remove-app() {
    local app quadlets_dir app_dir output
    app="${1-}"
    quadlets_dir="${2-}"
    app_dir="${quadlets_dir}/${app}"
    [[ -n "${app}" && -n "${quadlets_dir}" && -d "${app_dir}" ]] || return 0

    if [[ -n "$(ls -A -- "${app_dir}")" ]]; then
        if ! output="$(podman quadlet rm --force --recursive "${app}" 2>&1)"; then
            logger -t podshift-qdl-install -p err "podman quadlet rm failed for ${app}"
            printf '%s\n' "${output}" | logger -t podshift-qdl-install -p err
            return 0
        fi
    fi
    if [[ -d "${app_dir}" ]] && ! rmdir -- "${app_dir}" 2>/dev/null; then
        logger -t podshift-qdl-install -p err "failed to remove the folder of ${app}"
        return 0
    fi
    logger -t podshift-qdl-install -p info "removed partially installed app ${app}"
    return 0
}
