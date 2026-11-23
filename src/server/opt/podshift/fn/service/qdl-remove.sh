#!/usr/bin/env bash
# @file: qdl-remove.sh
# @source-dir: src/server/opt/podshift/fn/service
# @dest-dir: /opt/podshift/fn/service
# @host-edit: no
# @group: service
# @category: entry
# @description: Removes the quadlets queued in the PodShift remove queue.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# shellcheck source=../../../../usr/lib/systemd/user/podshift-qdl-remove.service

if [[ -z "${DIR_78921DCB7A73:-}" ]]; then
    DIR_78921DCB7A73="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_78921DCB7A73
fi

# @description: Empties the remove queue: each request file names one quadlet file or app, removed with remove-item.
# @details:
#   The Cockpit quadlet-remove action writes one file per request: its name is the quadlet file
#   name or app name, and its content is volumes=1 when the volumes are removed too. Hidden files
#   are skipped. Requests are handled oldest first. Each request file is renamed to a hidden
#   .removing.<name> marker before the removal, so every request gets one try, and deleted once
#   remove-item returns, also on a failure. The quadlet-remove busy check sees the marker, so the
#   same removal cannot be queued again meanwhile. Markers left by a stopped run are deleted first.
#   The result goes to the journal (podshift-qdl-remove), not to the drop history.
# @exitcode: 0 always (non-fatal).
podshift-qdl-remove() {
    local queue_dir quadlets_dir stop_timeout file target volumes marker
    local -a files

    # Load and export the PodShift configuration.
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_78921DCB7A73}/../load-podshift-conf-main.sh"
    load-podshift-conf-main

    queue_dir="${PODSHIFT_QUADLET_REMOVE_QUEUE_DIR:-}"
    quadlets_dir="${PODSHIFT_PODMAN_QUADLETS_DIR:-}"
    stop_timeout="${PODSHIFT_QUADLET_STOP_TIMEOUT:-}"
    if [[ -z "${queue_dir}" || -z "${quadlets_dir}" || -z "${stop_timeout}" ]]; then
        logger -t podshift-qdl-remove -p err "remove queue, quadlets directory or stop timeout is not configured"
        return 0
    fi
    if [[ ! -d "${queue_dir}" ]]; then
        logger -t podshift-qdl-remove -p warn "remove queue missing: ${queue_dir}"
        return 0
    fi

    # A marker left by a run that was stopped mid-removal has no removal behind it any more.
    rm -f -- "${queue_dir}"/.removing.* 2>/dev/null || true

    # Oldest first: ls -tr sorts by modification time, the names never hold a newline.
    mapfile -t files < <(cd "${queue_dir}" && ls -1tr 2>/dev/null | grep -v '^\.')

    # shellcheck source=../quadlet/remove-item.sh
    declare -F remove-item >/dev/null || source "${DIR_78921DCB7A73}/../quadlet/remove-item.sh"
    for target in "${files[@]}"; do
        file="${queue_dir}/${target}"
        marker="${queue_dir}/.removing.${target}"
        [[ -f "${file}" ]] || continue
        volumes=0
        grep -qx 'volumes=1' "${file}" 2>/dev/null && volumes=1
        if ! mv -f -- "${file}" "${marker}"; then
            logger -t podshift-qdl-remove -p err "failed to take the request ${target}"
            continue
        fi
        remove-item "${target}" "${quadlets_dir}" "${volumes}" "${stop_timeout}" >/dev/null
        rm -f -- "${marker}" || logger -t podshift-qdl-remove -p err "failed to delete the marker of ${target}"
    done
    return 0
}

# Executes only when run directly (systemd ExecStart)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && podshift-qdl-remove
