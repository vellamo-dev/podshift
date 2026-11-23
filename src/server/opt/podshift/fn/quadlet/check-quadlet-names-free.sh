#!/usr/bin/env bash
# @file: check-quadlet-names-free.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Checks that no Podman object already has the name a dropped quadlet would create.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E6D4D21CDF68:-}" ]]; then
    DIR_E6D4D21CDF68="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E6D4D21CDF68
fi

# @description: Asks Podman whether the container, network, volume or pod name of the file is taken, and prints the reason.
# @details:
#   The name is the file base name (check-quadlet-name makes the name key equal to it). Each type
#   has its own names: a .container is checked with podman container exists, a .network with
#   podman network exists, a .volume with podman volume exists, a .pod with podman pod exists. A
#   pod also needs the container name <pod>-infra for its infra container (not verified on Fedora:
#   the name Quadlet gives it), so a .pod is refused when that container exists or a
#   <pod>-infra.container is installed or in the same bundle, and a .container named <pod>-infra is
#   refused when that pod exists, is installed or is in the same bundle. Other types are not
#   checked.
#   The pod branches wait for pod support (docs/roadmap.md); a .pod file or Pod= key is refused for now.
# @arg: $1 - dropped quadlet file.
# @arg: $2 - directory where Podman installs quadlets.
# @arg: $3 - folder with the other files of the same bundle, or empty for a single file.
# @stdout: the reason when a name is taken, one line.
# @exitcode: 0 if the names are free, 1 otherwise.
check-quadlet-names-free() {
    local file quadlets_dir own_dir name stem extension pod
    file="${1-}"
    quadlets_dir="${2-}"
    own_dir="${3-}"

    # shellcheck source=./get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_E6D4D21CDF68}/get-original-name.sh"
    # shellcheck source=./find-installed-quadlet.sh
    declare -F find-installed-quadlet >/dev/null || source "${DIR_E6D4D21CDF68}/find-installed-quadlet.sh"
    name="$(get-original-name "${file}")"
    stem="${name%.*}"
    extension="${name##*.}"

    case "${extension}" in
        container|network|volume|pod)
            if podman "${extension}" exists "${stem}" >/dev/null 2>&1; then
                echo "${name}: a Podman ${extension} named ${stem} already exists"
                return 1
            fi
            ;;
        *)
            return 0
            ;;
    esac

    if [[ "${extension}" == "pod" ]]; then
        if podman container exists "${stem}-infra" >/dev/null 2>&1 \
            || find-installed-quadlet "${stem}-infra.container" "${quadlets_dir}" >/dev/null \
            || [[ -n "${own_dir}" && -f "${own_dir}/${stem}-infra.container" ]]; then
            echo "${name}: the container name ${stem}-infra, used by the pod for its infra container, is taken"
            return 1
        fi
    elif [[ "${extension}" == "container" && "${stem}" == ?*-infra ]]; then
        pod="${stem%-infra}"
        if podman pod exists "${pod}" >/dev/null 2>&1 \
            || find-installed-quadlet "${pod}.pod" "${quadlets_dir}" >/dev/null \
            || [[ -n "${own_dir}" && -f "${own_dir}/${pod}.pod" ]]; then
            echo "${name}: ${stem} is the infra container name of the pod ${pod}"
            return 1
        fi
    fi
    return 0
}
