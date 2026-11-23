#!/usr/bin/env bash
# @file: install-quadlet.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Installs a staged quadlet file or bundle folder with podman quadlet install, never with --replace.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_4E9C17A2D6B8:-}" ]]; then
    DIR_4E9C17A2D6B8="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4E9C17A2D6B8
fi

# @description: Installs a staged file or bundle folder with podman quadlet install, never over an installed one.
# @details:
#   Installs a single file with "podman quadlet install <file>", or a bundle folder with "podman
#   quadlet install --application <name> <folder>", where the name comes from get-app-name (the zip
#   name). --replace is never used: an installed quadlet is never replaced. Without it Podman
#   refuses an existing name (per the Podman docs, not verified on Fedora). On a failure the output of Podman is logged.
# @arg: $1 - staged quadlet file or bundle folder, named by its original name.
# @exitcode: 0 if installed, 1 if the install failed.
install-quadlet() {
    local item name application output
    local -a args
    item="${1}"
    name="$(basename "${item}")"
    args=(quadlet install)

    if [[ -d "${item}" ]]; then
        # shellcheck source=./get-app-name.sh
        declare -F get-app-name >/dev/null || source "${DIR_4E9C17A2D6B8}/get-app-name.sh"
        application="$(get-app-name "${item}")"
        args+=(--application "${application}" "${item}")
    else
        args+=("${item}")
    fi

    if output="$(podman "${args[@]}" 2>&1)"; then
        logger -t podshift-qdl-install -p info "installed ${name}"
        return 0
    fi
    logger -t podshift-qdl-install -p err "podman quadlet install failed for ${name}"
    printf '%s\n' "${output}" | logger -t podshift-qdl-install -p err
    return 1
}
