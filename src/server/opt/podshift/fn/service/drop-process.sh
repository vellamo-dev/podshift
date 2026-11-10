#!/usr/bin/env bash
# @file: drop-process.sh
# @source-dir: src/server/opt/podshift/fn/service
# @dest-dir: /opt/podshift/fn/service
# @host-edit: no
# @group: service
# @category: entry
# @description: Processes the PodShift drop directory.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# shellcheck source=../../../../usr/lib/systemd/user/podshift-drop-process.service

if [[ -z "${DIR_3B7F1A9C4E2D:-}" ]]; then
    DIR_3B7F1A9C4E2D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3B7F1A9C4E2D
fi

# @description: Moves stable, accepted files from the drop directory to the validation queue, and the rest to trash.
# @details:
#   Trash also gets a hidden file, a zip with an invalid name, and a zip that is too big.
# @exitcode: 0 always (non-fatal).
podshift-drop-process() {
    local drop_dir trash_dir queue_dir max_bundle_size accepted_extensions
    local settle_seconds file_age file extension size destination target
    local -a files

    # Load and export the PodShift configuration.
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_3B7F1A9C4E2D}/../load-podshift-conf-main.sh"
    load-podshift-conf-main

    drop_dir="${PODSHIFT_DROP_DIR:-}"
    trash_dir="${PODSHIFT_TRASH_DIR:-}"
    queue_dir="${PODSHIFT_QUADLET_VALIDATION_QUEUE_DIR:-}"
    max_bundle_size="${PODSHIFT_DROP_MAX_BUNDLE_SIZE:-0}"
    accepted_extensions="${PODSHIFT_DROP_QUADLET_EXTENSIONS:-}"
    settle_seconds="${PODSHIFT_DROP_SETTLE:-2}"

    if [[ -z "${drop_dir}" || -z "${trash_dir}" || -z "${queue_dir}" ]]; then
        logger -t podshift-drop-process -p err "drop, trash, or validation queue directory is not configured"
        return 0
    fi

    if [[ ! -d "${drop_dir}" ]]; then
        logger -t podshift-drop-process -p warn "drop directory missing: ${drop_dir}"
        return 0
    fi

    # Scan for regular files and folders, hidden ones too. Folders are not accepted.
    mapfile -t files < <(find "${drop_dir}" -mindepth 1 -maxdepth 1 \( -type f -o -type d \) | sort)

    for file in "${files[@]}"; do
        # Stability check: skip files modified within the settle window.
        file_age=$(( $(date +%s) - $(stat -c %Y "${file}") ))
        if (( file_age < settle_seconds )); then
            logger -t podshift-drop-process -p debug "skipping $(basename "${file}"), still settling"
            continue
        fi

        extension=".${file##*.}"

        if [[ "$(basename "${file}")" == .* ]]; then
            destination="${trash_dir}"
            logger -t podshift-drop-process -p warn "hidden file: $(basename "${file}")"
        elif [[ -d "${file}" ]]; then
            destination="${trash_dir}"
            logger -t podshift-drop-process -p warn "$(basename "${file}"): folders not accepted"
        elif [[ "${extension}" == ".zip" ]]; then
            # The zip name without .zip is the name of the bundle folder and of the application.
            # shellcheck source=../quadlet/is-valid-app-name.sh
            declare -F is-valid-app-name >/dev/null || source "${DIR_3B7F1A9C4E2D}/../quadlet/is-valid-app-name.sh"
            size=$(stat -c %s "${file}")
            if ! is-valid-app-name "$(basename "${file}" .zip)"; then
                destination="${trash_dir}"
                logger -t podshift-drop-process -p warn "invalid bundle name: $(basename "${file}")"
            elif (( size <= max_bundle_size * 1024 )); then
                destination="${queue_dir}"
            else
                destination="${trash_dir}"
                logger -t podshift-drop-process -p warn "oversized bundle: $(basename "${file}")"
            fi
        elif [[ ",${accepted_extensions}," == *",${extension},"* ]]; then
            destination="${queue_dir}"
        else
            destination="${trash_dir}"
        fi

        # Move to the chosen destination, renaming on collision.
        # Rename on a name clash instead of overwriting: a file already being
        # processed must not be clobbered by a concurrently dropped newer version.
        target="${destination}/$(basename "${file}")"
        if [[ -e "${target}" ]]; then
            target="${target}.$(date +%s%N)"
        fi

        if [[ "${destination}" == "${queue_dir}" ]]; then
            # Accepted: normalize permissions, ownership, and mtime.
            if install -m 0644 "${file}" "${target}" 2>/dev/null && rm -f "${file}"; then
                logger -t podshift-drop-process -p info "accepted $(basename "${file}") into $(basename "${destination}")"
            else
                logger -t podshift-drop-process -p err "failed to accept $(basename "${file}")"
            fi
        else
            # Unaccepted: plain move to trash.
            if mv -f "${file}" "${target}" 2>/dev/null; then
                logger -t podshift-drop-process -p info "moved $(basename "${file}") to $(basename "${destination}")"
            else
                logger -t podshift-drop-process -p err "failed to move $(basename "${file}")"
            fi
        fi
    done

    return 0
}

# Executes only when run directly (systemd ExecStart)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && podshift-drop-process
