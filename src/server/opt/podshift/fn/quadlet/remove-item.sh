#!/usr/bin/env bash
# @file: remove-item.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Removes one installed quadlet file or app: stops its units, removes its files, containers and networks.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_F1505F816CE7:-}" ]]; then
    DIR_F1505F816CE7="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_F1505F816CE7
fi

# @description: Removes a single quadlet file (web.container) or an app (shop) unless something still uses it.
# @details:
#   list-quadlet-item-files resolves the name: a name with a quadlet extension is a single file at
#   the top of the quadlets directory, any other valid app name an app folder. It is refused when another installed quadlet refers to
#   one of its files (find-quadlet-users), or when a container that is not its own uses one of its
#   networks or volumes (podman ps --filter). Otherwise the units are stopped in reverse install
#   order (containers, pods, images, volumes, networks), each with "timeout <seconds> systemctl
#   --user stop"; a stop that does not finish in time is logged and the removal goes on. Then the
#   files are removed with "podman quadlet rm --force" (with --recursive for an app), which also
#   reloads systemd (per the Podman docs). The failed state of each unit is reset with
#   "systemctl --user reset-failed" (errors ignored), so a unit killed on stop is not left listed
#   as failed. Leftover containers with the label
#   PODMAN_SYSTEMD_UNIT=<unit> and a leftover pod are removed with force, each network with
#   "podman network rm" (no force; a failure is only logged), and each volume only when asked.
#   Images are kept. Each step is logged with the podshift-qdl-remove tag, "stopping <unit>" for
#   each unit, which the install log shows together with the systemd and Podman lines of these
#   units; a removal is not a drop, so nothing goes to the drop history.
#   The pod branches wait for pod support (docs/roadmap.md); a .pod file or Pod= key is refused for now.
# @arg: $1 - quadlet file name or app name.
# @arg: $2 - directory where Podman installs quadlets.
# @arg: $3 - 1 to remove the Podman volumes of the .volume files too, 0 to keep them.
# @arg: $4 - seconds to wait for each unit to stop.
# @stdout: the reason when the removal was refused or failed, one line.
# @exitcode: 0 if removed, 1 if the removal failed, 2 if it is not installed, 3 if something still uses it.
remove-item() {
    local target quadlets_dir volumes stop_timeout path file name stem unit users line extension output listed
    local -a files names units args ids
    target="${1-}"
    quadlets_dir="${2-}"
    volumes="${3:-0}"
    stop_timeout="${4-}"
    quadlets_dir="${quadlets_dir%/}"

    # shellcheck source=./list-quadlet-item-files.sh
    declare -F list-quadlet-item-files >/dev/null || source "${DIR_F1505F816CE7}/list-quadlet-item-files.sh"
    # shellcheck source=./get-quadlet-unit-name.sh
    declare -F get-quadlet-unit-name >/dev/null || source "${DIR_F1505F816CE7}/get-quadlet-unit-name.sh"
    # shellcheck source=./find-quadlet-users.sh
    declare -F find-quadlet-users >/dev/null || source "${DIR_F1505F816CE7}/find-quadlet-users.sh"

    # Find what to remove.
    path="${quadlets_dir}/${target}"
    if ! listed="$(list-quadlet-item-files "${quadlets_dir}" "${target}")"; then
        echo "${target} is not installed"
        return 2
    fi
    files=()
    [[ -z "${listed}" ]] || mapfile -t files <<<"${listed}"
    names=()
    units=()
    for file in "${files[@]}"; do
        names+=("${file##*/}")
        unit="$(get-quadlet-unit-name "${file}")" && units+=("${unit}")
    done

    # Refuse while something else uses it.
    if users="$(find-quadlet-users "${quadlets_dir}" "${path}" "${names[@]}")"; then
        line="used by $(printf '%s' "${users}" | tr '\n' ' ')"
        line="${line% }"
        logger -t podshift-qdl-remove -p warn "${target}: ${line}"
        echo "${line}"
        return 3
    fi
    for file in "${files[@]}"; do
        name="${file##*/}"
        stem="${name%.*}"
        extension="${name##*.}"
        [[ "${extension}" == "network" || "${extension}" == "volume" ]] || continue
        while IFS=$'\t' read -r name unit; do
            [[ -n "${name}" ]] || continue
            [[ " ${units[*]} " == *" ${unit} "* ]] && continue
            line="used by container ${name}"
            logger -t podshift-qdl-remove -p warn "${target}: ${line}"
            echo "${line}"
            return 3
        done < <(podman ps -a --filter "${extension}=${stem}" --format '{{.Names}}{{"\t"}}{{index .Labels "PODMAN_SYSTEMD_UNIT"}}' 2>/dev/null)
    done

    logger -t podshift-qdl-remove -p info "removing ${target}"

    # Stop the units, the users first.
    for extension in container kube pod image build volume network; do
        for file in "${files[@]}"; do
            [[ "${file}" == *".${extension}" ]] || continue
            unit="$(get-quadlet-unit-name "${file}")" || continue
            logger -t podshift-qdl-remove -p info "stopping ${unit}"
            if ! output="$(timeout "${stop_timeout}" systemctl --user stop "${unit}" 2>&1)"; then
                logger -t podshift-qdl-remove -p warn "${unit} did not stop cleanly within ${stop_timeout} s, going on"
                [[ -z "${output}" ]] || printf '%s\n' "${output}" | logger -t podshift-qdl-remove -p warn
            fi
        done
    done

    # Remove the files; Podman reloads systemd.
    args=(quadlet rm --force)
    [[ -d "${path}" ]] && args+=(--recursive)
    if ! output="$(podman "${args[@]}" "${target}" 2>&1)"; then
        logger -t podshift-qdl-remove -p err "podman quadlet rm failed for ${target}"
        printf '%s\n' "${output}" | logger -t podshift-qdl-remove -p err
        line="podman quadlet rm failed: $(printf '%s\n' "${output}" | grep -m 1 -v '^[[:space:]]*$')"
        echo "${line}"
        return 1
    fi
    if [[ -d "${path}" ]]; then
        rmdir -- "${path}" 2>/dev/null || logger -t podshift-qdl-remove -p warn "the folder ${path} was not empty, kept"
    fi

    # A unit killed on stop stays listed as failed (not-found) until its failed state is reset.
    for unit in "${units[@]}"; do
        systemctl --user reset-failed "${unit}" >/dev/null 2>&1 || :
    done

    # Leftovers: containers of the units, pods, networks, and volumes when asked.
    for unit in "${units[@]}"; do
        mapfile -t ids < <(podman ps -a -q --filter "label=PODMAN_SYSTEMD_UNIT=${unit}" 2>/dev/null)
        (( ${#ids[@]} > 0 )) || continue
        if podman rm -f "${ids[@]}" >/dev/null 2>&1; then
            logger -t podshift-qdl-remove -p info "removed ${#ids[@]} leftover container(s) of ${unit}"
        else
            logger -t podshift-qdl-remove -p warn "failed to remove leftover containers of ${unit}"
        fi
    done
    for file in "${files[@]}"; do
        name="${file##*/}"
        stem="${name%.*}"
        extension="${name##*.}"
        case "${extension}" in
            pod|network|volume) ;;
            *) continue ;;
        esac
        podman "${extension}" exists "${stem}" >/dev/null 2>&1 || continue
        if [[ "${extension}" == "volume" && "${volumes}" != "1" ]]; then
            logger -t podshift-qdl-remove -p info "kept the volume ${stem}"
            continue
        fi
        args=("${extension}" rm)
        [[ "${extension}" == "pod" ]] && args+=(--force)
        if output="$(podman "${args[@]}" "${stem}" 2>&1)"; then
            logger -t podshift-qdl-remove -p info "removed the ${extension} ${stem}"
        else
            logger -t podshift-qdl-remove -p warn "failed to remove the ${extension} ${stem}"
            printf '%s\n' "${output}" | logger -t podshift-qdl-remove -p warn
        fi
    done

    logger -t podshift-qdl-remove -p info "removed ${target}"
    return 0
}
