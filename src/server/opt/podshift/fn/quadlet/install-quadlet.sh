#!/usr/bin/env bash
# @file: install-quadlet.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Installs a staged quadlet file or bundle folder with podman quadlet install.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_4E9C17A2D6B8:-}" ]]; then
    DIR_4E9C17A2D6B8="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4E9C17A2D6B8
fi

# @description: Installs a staged file or bundle folder with podman quadlet install, adding --replace when needed.
# @details:
#   Installs a single file with "podman quadlet install <file>", or a bundle folder with "podman
#   quadlet install --application <name> <folder>", where the name comes from get-app-name (the zip
#   name). The option --replace is added only if the file, or the application folder, is already in
#   the quadlets directory; without it Podman refuses to overwrite. On a failure the output of
#   Podman is logged. The exit code tells the caller whether the item was replaced.
# @arg: $1 - staged quadlet file or bundle folder, named by its original name.
# @arg: $2 - directory where Podman installs quadlets.
# @exitcode: 0 if installed as new, 2 if installed over an existing one (--replace was used), 1 if the install failed.
install-quadlet() {
    local item quadlets_dir name application output replaced
    local -a args
    item="${1}"
    quadlets_dir="${2}"
    name="$(basename "${item}")"
    args=(quadlet install)
    replaced=0

    if [[ -d "${item}" ]]; then
        # shellcheck source=./get-app-name.sh
        declare -F get-app-name >/dev/null || source "${DIR_4E9C17A2D6B8}/get-app-name.sh"
        application="$(get-app-name "${item}")"
        if [[ -d "${quadlets_dir}/${application}" ]]; then
            args+=(--replace)
            replaced=1
        fi
        args+=(--application "${application}" "${item}")
    else
        if [[ -e "${quadlets_dir}/${name}" ]]; then
            args+=(--replace)
            replaced=1
        fi
        args+=("${item}")
    fi

    if output="$(podman "${args[@]}" 2>&1)"; then
        logger -t podshift-qdl-install -p info "installed ${name}"
        (( replaced == 1 )) && return 2
        return 0
    fi
    logger -t podshift-qdl-install -p err "podman quadlet install failed for ${name}"
    printf '%s\n' "${output}" | logger -t podshift-qdl-install -p err
    return 1
}
