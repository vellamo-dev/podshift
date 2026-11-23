#!/usr/bin/env bash
# @file: qdl-validate.sh
# @source-dir: src/server/opt/podshift/fn/service
# @dest-dir: /opt/podshift/fn/service
# @host-edit: no
# @group: service
# @category: entry
# @description: Validates quadlets in the PodShift validation queue.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# shellcheck source=../../../../usr/lib/systemd/user/podshift-qdl-validate.service

if [[ -z "${DIR_8F4C2E6A1D9B:-}" ]]; then
    DIR_8F4C2E6A1D9B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_8F4C2E6A1D9B
fi

# @description: Empties the validation queue: new valid quadlets go to source, refused ones to rejected, the rest to trash.
# @details:
#   Files are handled in rank order (list-install-items), oldest first. A file must pass
#   check-quadlet (sections, keys and name rules). An installed quadlet is never replaced: the same
#   file already installed is logged as unchanged and goes to trash, another file with an installed
#   name is refused (check-installed-item). A new file must have free Podman names and every
#   reference in place (check-quadlet-install). The TSV values are loaded so the unchanged check
#   compares filled content. Each result is also logged to the drop history under the drop ID
#   (get-drop-id). A file put into the queue by hand without an ID gets a new one (set-drop-id).
# @exitcode: 0 always (non-fatal).
podshift-qdl-validate() {
    local queue_dir source_dir rejected_dir trash_dir accepted_extensions quadlets_dir
    local file name extension reason status id
    local -a files

    # Load and export the PodShift configuration.
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_8F4C2E6A1D9B}/../load-podshift-conf-main.sh"
    load-podshift-conf-main
    # The TSV values, for the unchanged check (as qdl-install loads them).
    # shellcheck source=../load-podshift-conf-nw.sh
    declare -F load-podshift-conf-nw >/dev/null || source "${DIR_8F4C2E6A1D9B}/../load-podshift-conf-nw.sh"
    load-podshift-conf-nw
    # shellcheck source=../quadlet/log-drop-history.sh
    declare -F log-drop-history >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/log-drop-history.sh"
    # shellcheck source=../quadlet/get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/get-original-name.sh"
    # shellcheck source=../quadlet/get-drop-id.sh
    declare -F get-drop-id >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/get-drop-id.sh"
    # shellcheck source=../quadlet/set-drop-id.sh
    declare -F set-drop-id >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/set-drop-id.sh"
    # shellcheck source=../utils/new-uuid7.sh
    declare -F new-uuid7 >/dev/null || source "${DIR_8F4C2E6A1D9B}/../utils/new-uuid7.sh"

    queue_dir="${PODSHIFT_QUADLET_VALIDATION_QUEUE_DIR:-}"
    source_dir="${PODSHIFT_QUADLET_SOURCE_DIR:-}"
    rejected_dir="${PODSHIFT_QUADLET_REJECTED_DIR:-}"
    trash_dir="${PODSHIFT_TRASH_DIR:-}"
    accepted_extensions="${PODSHIFT_DROP_QUADLET_EXTENSIONS:-}"
    quadlets_dir="${PODSHIFT_PODMAN_QUADLETS_DIR:-}"

    if [[ -z "${queue_dir}" || -z "${source_dir}" || -z "${rejected_dir}" || -z "${trash_dir}" || -z "${quadlets_dir}" ]]; then
        logger -t podshift-qdl-validate -p err "queue, source, rejected, trash or quadlets directory is not configured"
        return 0
    fi

    if [[ ! -d "${queue_dir}" ]]; then
        logger -t podshift-qdl-validate -p warn "validation queue missing: ${queue_dir}"
        return 0
    fi

    # Rank order (networks, volumes, images, pods, containers, then the rest), oldest first, so a
    # file is validated after the files it refers to when they are dropped together.
    # shellcheck source=../quadlet/list-install-items.sh
    declare -F list-install-items >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/list-install-items.sh"
    mapfile -t files < <(list-install-items "${queue_dir}")

    for file in "${files[@]}"; do
        [[ -f "${file}" ]] || continue
        # Drop the collision suffix (app.container.1698400000123456789) and the drop ID of a zip.
        name="$(get-original-name "${file}")"
        extension=".${name##*.}"
        id="$(get-drop-id "${file}")" || id=""

        # shellcheck source=../quadlet/move-file.sh
        declare -F move-file >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/move-file.sh"
        if [[ "${extension}" == ".zip" ]]; then
            # shellcheck source=../quadlet/process-bundle.sh
            declare -F process-bundle >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/process-bundle.sh"
            process-bundle "${file}" "${source_dir}" "${rejected_dir}" "${trash_dir}" "${quadlets_dir}" "${id}"
        elif [[ ",${accepted_extensions}," == *",${extension},"* ]]; then
            # A file put into the queue by hand has no drop ID yet: it gets a new one.
            [[ -n "${id}" ]] || { id="$(new-uuid7)" && set-drop-id "${file}" "${id}"; } || true
            # shellcheck source=../quadlet/check-quadlet.sh
            declare -F check-quadlet >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/check-quadlet.sh"
            # shellcheck source=../quadlet/check-installed-item.sh
            declare -F check-installed-item >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/check-installed-item.sh"
            # shellcheck source=../quadlet/check-quadlet-install.sh
            declare -F check-quadlet-install >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/check-quadlet-install.sh"
            if ! reason="$(check-quadlet "${file}")"; then
                logger -t podshift-qdl-validate -p warn "${reason}"
                log-drop-history "${id}" "${name}" failed "${reason}" "${file}"
                move-file "${file}" "${rejected_dir}"
                continue
            fi
            reason="$(check-installed-item "${file}" "${quadlets_dir}")" && status=0 || status=$?
            if (( status == 2 )); then
                logger -t podshift-qdl-validate -p info "${name} is already installed with the same content"
                log-drop-history "${id}" "${name}" unchanged "" "${file}"
                move-file "${file}" "${trash_dir}"
            elif (( status != 0 )) || ! reason="$(check-quadlet-install "${file}" "${quadlets_dir}" "${source_dir}" "")"; then
                logger -t podshift-qdl-validate -p warn "${reason}"
                log-drop-history "${id}" "${name}" refused "${reason}" "${file}"
                move-file "${file}" "${rejected_dir}"
            else
                log-drop-history "${id}" "${name}" validated "" "${file}"
                # shellcheck source=../quadlet/install-file.sh
                declare -F install-file >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/install-file.sh"
                install-file "${file}" "${source_dir}" "${name}"
            fi
        else
            log-drop-history "${id}" "${name}" refused "file type is not accepted"
            move-file "${file}" "${trash_dir}"
        fi
    done

    return 0
}

# Executes only when run directly (systemd ExecStart)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && podshift-qdl-validate
