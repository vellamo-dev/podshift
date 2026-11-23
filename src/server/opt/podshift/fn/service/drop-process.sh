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
#   Trash also gets a hidden file, a zip with an invalid name, and a zip that is too big. Every
#   item gets a new drop ID (new-uuid7), whoever dropped it (Cockpit, a terminal, scp). An
#   accepted Quadlet file is written to the queue with "# podshift-drop-id: <uuid>" as line 1 and
#   any older drop ID line removed (set-drop-id); an accepted zip keeps its content and carries the
#   ID in its queued name, shop.zip.<uuid>. Each accepted or refused item is also logged to the
#   drop history under its ID (log-drop-history). A file that is gone before its time or size can
#   be read, for example taken by another process, is skipped and the others are still handled.
#   A file whose time is in the future gets the time now and waits for a later run (the safety timer).
#   The settle time, the bundle size limit and the folders come only from main.conf.
# @exitcode: 0 always (non-fatal).
podshift-drop-process() {
    local drop_dir trash_dir queue_dir max_bundle_size accepted_extensions now name
    local settle_seconds file_age mtime file extension size destination target reason id accepted
    local -a files

    # Load and export the PodShift configuration.
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_3B7F1A9C4E2D}/../load-podshift-conf-main.sh"
    load-podshift-conf-main
    # shellcheck source=../quadlet/log-drop-history.sh
    declare -F log-drop-history >/dev/null || source "${DIR_3B7F1A9C4E2D}/../quadlet/log-drop-history.sh"
    # shellcheck source=../utils/new-uuid7.sh
    declare -F new-uuid7 >/dev/null || source "${DIR_3B7F1A9C4E2D}/../utils/new-uuid7.sh"
    # shellcheck source=../quadlet/set-drop-id.sh
    declare -F set-drop-id >/dev/null || source "${DIR_3B7F1A9C4E2D}/../quadlet/set-drop-id.sh"

    drop_dir="${PODSHIFT_DROP_DIR:-}"
    trash_dir="${PODSHIFT_TRASH_DIR:-}"
    queue_dir="${PODSHIFT_QUADLET_VALIDATION_QUEUE_DIR:-}"
    max_bundle_size="${PODSHIFT_DROP_MAX_BUNDLE_SIZE:-}"
    accepted_extensions="${PODSHIFT_DROP_QUADLET_EXTENSIONS:-}"
    settle_seconds="${PODSHIFT_DROP_SETTLE:-}"

    if [[ -z "${drop_dir}" || -z "${trash_dir}" || -z "${queue_dir}" ]]; then
        logger -t podshift-drop-process -p err "drop, trash, or validation queue directory is not configured"
        return 0
    fi
    case "${max_bundle_size}:${settle_seconds}" in
        *[!0123456789:]*|:*|*:)
            logger -t podshift-drop-process -p err "PODSHIFT_DROP_MAX_BUNDLE_SIZE or PODSHIFT_DROP_SETTLE is not set to a whole number"
            return 0
            ;;
    esac

    if [[ ! -d "${drop_dir}" ]]; then
        logger -t podshift-drop-process -p warn "drop directory missing: ${drop_dir}"
        return 0
    fi

    # Scan for regular files and folders, hidden ones too. Folders are not accepted.
    mapfile -t files < <(find "${drop_dir}" -mindepth 1 -maxdepth 1 \( -type f -o -type d \) | sort)
    now="$(date +%s)"

    for file in "${files[@]}"; do
        name="${file##*/}"
        # A file can vanish between find and stat; skip it, the others still go on.
        mtime="$(stat -c %Y -- "${file}" 2>/dev/null)" || mtime=""
        case "${mtime}" in
            ''|*[!0123456789]*)
                logger -t podshift-drop-process -p debug "skipping ${name}, it is gone"
                continue
                ;;
        esac
        # Stability check: skip files modified within the settle window.
        file_age=$(( now - mtime ))
        # A time in the future, for example kept from a machine whose clock is ahead, would hold the
        # file back until the clock catches up. Reset it to now, so the settle time starts from here.
        if (( file_age < 0 )); then
            touch -- "${file}" 2>/dev/null
            logger -t podshift-drop-process -p debug "skipping ${name}, its time was in the future and is reset to now"
            continue
        fi
        if (( file_age < settle_seconds )); then
            logger -t podshift-drop-process -p debug "skipping ${name}, still settling"
            continue
        fi

        # Every drop gets its own ID, also a refused one.
        id="$(new-uuid7)" || id=""
        extension=".${file##*.}"
        reason=""

        if [[ "${name}" == .* ]]; then
            reason="hidden file"
            destination="${trash_dir}"
            logger -t podshift-drop-process -p warn "hidden file: ${name}"
        elif [[ -d "${file}" ]]; then
            reason="folders are not accepted"
            destination="${trash_dir}"
            logger -t podshift-drop-process -p warn "${name}: folders not accepted"
        elif [[ "${extension}" == ".zip" ]]; then
            # The zip name without .zip is the name of the bundle folder and of the application.
            # shellcheck source=../quadlet/is-valid-app-name.sh
            declare -F is-valid-app-name >/dev/null || source "${DIR_3B7F1A9C4E2D}/../quadlet/is-valid-app-name.sh"
            size="$(stat -c %s -- "${file}" 2>/dev/null)" || size=""
            case "${size}" in
                ''|*[!0123456789]*)
                    logger -t podshift-drop-process -p debug "skipping ${name}, it is gone"
                    continue
                    ;;
            esac
            if ! is-valid-app-name "${name%.zip}"; then
                reason="invalid bundle name"
                destination="${trash_dir}"
                logger -t podshift-drop-process -p warn "invalid bundle name: ${name}"
            elif (( size <= max_bundle_size * 1024 )); then
                destination="${queue_dir}"
            else
                reason="bundle is larger than ${max_bundle_size} KB"
                destination="${trash_dir}"
                logger -t podshift-drop-process -p warn "oversized bundle: ${name}"
            fi
        elif [[ ",${accepted_extensions}," == *",${extension},"* ]]; then
            destination="${queue_dir}"
        else
            reason="file type is not accepted"
            destination="${trash_dir}"
        fi

        # Move to the chosen destination, renaming on collision.
        # Rename on a name clash instead of overwriting: a file already being
        # processed must not be clobbered by a concurrently dropped newer version.
        target="${destination}/${name}"
        # A queued zip carries its drop ID in the name.
        [[ -n "${id}" && "${destination}" == "${queue_dir}" && "${extension}" == ".zip" ]] && target="${target}.${id}"
        if [[ -e "${target}" ]]; then
            target="${target}.$(date +%s%N)"
        fi

        if [[ "${destination}" == "${queue_dir}" ]]; then
            # Accepted: normalize permissions, ownership, and mtime. A Quadlet file gets the drop ID
            # line, written to a hidden temp file in the queue and renamed (set-drop-id). Without an
            # ID (no clock or /dev/urandom) the file is copied as before.
            accepted=0
            if [[ "${extension}" == ".zip" || -z "${id}" ]]; then
                if install -m 0644 "${file}" "${target}" 2>/dev/null && rm -f "${file}"; then
                    accepted=1
                fi
            elif set-drop-id "${file}" "${id}" "${target}" && rm -f "${file}"; then
                accepted=1
            fi
            if (( accepted == 1 )); then
                logger -t podshift-drop-process -p info "accepted ${name} into ${destination##*/} as drop ${id}"
                log-drop-history "${id}" "${name}" accepted "" "${target}"
            else
                logger -t podshift-drop-process -p err "failed to accept ${name}"
            fi
        else
            # Unaccepted: plain move to trash.
            if mv -f "${file}" "${target}" 2>/dev/null; then
                logger -t podshift-drop-process -p info "moved ${name} to ${destination##*/}"
                log-drop-history "${id}" "${name}" refused "${reason}"
            else
                logger -t podshift-drop-process -p err "failed to move ${name}"
            fi
        fi
    done

    return 0
}

# Executes only when run directly (systemd ExecStart)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && podshift-drop-process
