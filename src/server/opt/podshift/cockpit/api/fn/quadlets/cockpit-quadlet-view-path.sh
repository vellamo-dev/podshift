#!/usr/bin/env bash
# @file: cockpit-quadlet-view-path.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/quadlets
# @dest-dir: /opt/podshift/cockpit/api/fn/quadlets
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Checks the SourcePath of a generated unit for quadlet-view and prints the Quadlet file kind.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Quadlet kind of a unit's SourcePath, and checks that it is in the Quadlet folder.
# @details:
#   Only the text of the paths is checked; nothing is read from the system. The path is a Quadlet
#   file when its name ends in .container, .pod, .kube, .network, .volume, .image or .build (the
#   same kinds as services-list); else, or when it is empty, the exit code is 1. The folder must
#   be absolute; a trailing slash is ignored. The path must be absolute, start with the folder and
#   a slash, and have no empty, . or .. segment; else the kind is still printed and the exit code
#   is 2. The caller still checks symlinks and the real folders.
# @arg: $1 - SourcePath of the unit, for example /home/podshift/.config/containers/systemd/web.container.
# @arg: $2 - Quadlet folder, for example /home/podshift/.config/containers/systemd.
# @stdout: the kind, for example container, when the exit code is 0 or 2.
# @exitcode: 0 when the file is a Quadlet file in the folder, 1 when it is not a Quadlet file, 2 when it is outside the folder.
cockpit-quadlet-view-path() {
    local path dir name kind rest segment
    local -a segments
    path="${1-}"
    dir="${2-}"
    name="${path##*/}"
    case "${name}" in
        ?*.container) kind=container ;;
        ?*.pod) kind=pod ;;
        ?*.kube) kind=kube ;;
        ?*.network) kind=network ;;
        ?*.volume) kind=volume ;;
        ?*.image) kind=image ;;
        ?*.build) kind=build ;;
        *) return 1 ;;
    esac
    printf '%s\n' "${kind}"
    while [[ "${dir}" == */ && "${dir}" != "/" ]]; do
        dir="${dir%/}"
    done
    [[ "${dir}" == /?* && "${path}" == /* ]] || return 2
    [[ "${path}" == "${dir}/"?* ]] || return 2
    rest="${path:1}"
    IFS='/' read -r -a segments <<< "${rest}"
    [[ "${rest}" != */ ]] || return 2
    for segment in "${segments[@]}"; do
        case "${segment}" in
            ""|.|..) return 2 ;;
        esac
    done
    return 0
}
