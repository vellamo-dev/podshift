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

# @description: Empties the validation queue: valid quadlets go to source, invalid ones to rejected, bad bundles to trash.
# @details:
#   Files are handled in name order, so a plain name comes before its collision copies, oldest
#   first.
# @exitcode: 0 always (non-fatal).
podshift-qdl-validate() {
    local queue_dir source_dir rejected_dir trash_dir accepted_extensions
    local file name extension reason
    local -a files

    # Load and export the PodShift configuration.
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_8F4C2E6A1D9B}/../load-podshift-conf-main.sh"
    load-podshift-conf-main

    queue_dir="${PODSHIFT_QUADLET_VALIDATION_QUEUE_DIR:-}"
    source_dir="${PODSHIFT_QUADLET_SOURCE_DIR:-}"
    rejected_dir="${PODSHIFT_QUADLET_REJECTED_DIR:-}"
    trash_dir="${PODSHIFT_TRASH_DIR:-}"
    accepted_extensions="${PODSHIFT_DROP_QUADLET_EXTENSIONS:-}"

    if [[ -z "${queue_dir}" || -z "${source_dir}" || -z "${rejected_dir}" || -z "${trash_dir}" ]]; then
        logger -t podshift-qdl-validate -p err "queue, source, rejected, or trash directory is not configured"
        return 0
    fi

    if [[ ! -d "${queue_dir}" ]]; then
        logger -t podshift-qdl-validate -p warn "validation queue missing: ${queue_dir}"
        return 0
    fi

    # Scan for regular, non-hidden files only. Byte order puts app.container
    # before app.container.<nanoseconds>, and the suffixes sort oldest first.
    mapfile -t files < <(find "${queue_dir}" -maxdepth 1 -type f ! -name '.*' | LC_ALL=C sort)

    for file in "${files[@]}"; do
        # Drop the collision suffix added by drop-process (app.container.1698400000123456789).
        name="$(basename "${file}")"
        [[ "${name}" =~ ^(.+)\.[0-9]+$ ]] && name="${BASH_REMATCH[1]}"
        extension=".${name##*.}"

        if [[ "${extension}" == ".zip" ]]; then
            # shellcheck source=../quadlet/process-bundle.sh
            declare -F process-bundle >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/process-bundle.sh"
            process-bundle "${file}" "${source_dir}" "${rejected_dir}" "${trash_dir}"
        elif [[ ",${accepted_extensions}," == *",${extension},"* ]]; then
            # shellcheck source=../quadlet/check-quadlet.sh
            declare -F check-quadlet >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/check-quadlet.sh"
            if reason="$(check-quadlet "${file}")"; then
                # shellcheck source=../quadlet/install-file.sh
                declare -F install-file >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/install-file.sh"
                install-file "${file}" "${source_dir}" "${name}"
            else
                logger -t podshift-qdl-validate -p warn "${reason}"
                # shellcheck source=../quadlet/move-file.sh
                declare -F move-file >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/move-file.sh"
                move-file "${file}" "${rejected_dir}"
            fi
        else
            # shellcheck source=../quadlet/move-file.sh
            declare -F move-file >/dev/null || source "${DIR_8F4C2E6A1D9B}/../quadlet/move-file.sh"
            move-file "${file}" "${trash_dir}"
        fi
    done

    return 0
}

# Executes only when run directly (systemd ExecStart)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && podshift-qdl-validate
