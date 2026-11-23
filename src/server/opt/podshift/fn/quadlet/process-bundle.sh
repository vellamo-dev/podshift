#!/usr/bin/env bash
# @file: process-bundle.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Unpacks and validates a .zip bundle from the validation queue.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_80FAA91926EE:-}" ]]; then
    DIR_80FAA91926EE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_80FAA91926EE
fi

# @description: Unpacks a .zip bundle and checks every entry with check-quadlet and the install rules.
# @details:
#   The entry list is read first (unzip -Z1): two files with the same name in different folders
#   are refused, since the bundle is unpacked flat (unzip -j) and one would replace the other. Each
#   entry must pass check-quadlet. An installed app is never replaced: the same app already
#   installed is logged as unchanged and goes to trash, another one, or a file name installed
#   elsewhere, is refused (check-installed-item). Each new file must have free Podman names and
#   its references in the bundle or installed (check-quadlet-install). A valid bundle goes to a
#   bundle directory in source, a refused or invalid one to rejected, and a corrupt one to trash.
#   The drop ID comes from the caller, else from the queued name shop.zip.<uuid> (get-drop-id),
#   else it is new. Every unpacked file gets that ID as its first line (set-drop-id), so all files
#   of one bundle share it. Each result is also logged to the drop history under that ID
#   (log-drop-history).
#   Before the unpack, the file count and the total unpacked size from the bundle list are checked
#   against PODSHIFT_DROP_MAX_BUNDLE_FILES and PODSHIFT_DROP_MAX_BUNDLE_UNPACKED (KB) from main.conf,
#   so a small zip cannot unpack to a huge size. A bundle over a limit is refused; when a limit is
#   not a whole number, the bundle is refused and an error is logged.
# @arg: $1 - .zip file
# @arg: $2 - source directory
# @arg: $3 - rejected directory
# @arg: $4 - trash directory
# @arg: $5 - directory where Podman installs quadlets
# @arg: $6 - optional drop ID.
# @exitcode: 0 always (non-fatal).
process-bundle() {
    local file source_dir rejected_dir trash_dir quadlets_dir zip_name bundle_dir tmp_dir
    local entry reason status duplicate id max_files max_kb files bytes
    local -a entries
    file="${1}"
    source_dir="${2}"
    rejected_dir="${3}"
    trash_dir="${4}"
    quadlets_dir="${5-}"
    id="${6-}"

    # shellcheck source=./get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_80FAA91926EE}/get-original-name.sh"
    # shellcheck source=./get-drop-id.sh
    declare -F get-drop-id >/dev/null || source "${DIR_80FAA91926EE}/get-drop-id.sh"
    # shellcheck source=./set-drop-id.sh
    declare -F set-drop-id >/dev/null || source "${DIR_80FAA91926EE}/set-drop-id.sh"
    # shellcheck source=../utils/new-uuid7.sh
    declare -F new-uuid7 >/dev/null || source "${DIR_80FAA91926EE}/../utils/new-uuid7.sh"
    zip_name="$(get-original-name "${file}")"
    zip_name="${zip_name%.zip}"
    [[ -n "${id}" ]] || id="$(get-drop-id "${file}")" || id="$(new-uuid7)" || id=""
    bundle_dir="${source_dir}/${zip_name}.qdl-bundle"

    # shellcheck source=./move-file.sh
    declare -F move-file >/dev/null || source "${DIR_80FAA91926EE}/move-file.sh"
    # shellcheck source=./log-drop-history.sh
    declare -F log-drop-history >/dev/null || source "${DIR_80FAA91926EE}/log-drop-history.sh"

    tmp_dir="$(mktemp -d)" || {
        logger -t podshift-qdl-validate -p err "failed to create temp directory"
        return 0
    }

    # Two entries with the same file name would end up as one file in the flat unpack.
    if ! entry="$(unzip -Z1 "${file}" 2>/dev/null)"; then
        logger -t podshift-qdl-validate -p warn "corrupt bundle, discarding: ${zip_name}.zip"
        log-drop-history "${id}" "${zip_name}.zip" refused "corrupt bundle"
        rm -rf "${tmp_dir}"
        move-file "${file}" "${trash_dir}"
        return 0
    fi
    duplicate="$(printf '%s\n' "${entry}" | grep -v '/$' | sed 's#.*/##' | LC_ALL=C sort | uniq -d | head -n 1)"
    if [[ -n "${duplicate}" ]]; then
        reason="the bundle has more than one file named ${duplicate}"
        logger -t podshift-qdl-validate -p warn "${zip_name}.zip: ${reason}"
        log-drop-history "${id}" "${zip_name}.zip" refused "${reason}"
        rm -rf "${tmp_dir}"
        move-file "${file}" "${rejected_dir}"
        return 0
    fi

    # The list gives the size before anything is unpacked.
    max_files="${PODSHIFT_DROP_MAX_BUNDLE_FILES:-}"
    max_kb="${PODSHIFT_DROP_MAX_BUNDLE_UNPACKED:-}"
    files="$(printf '%s\n' "${entry}" | grep -cv '/$')"
    bytes="$(unzip -l "${file}" 2>/dev/null | awk 'END { print $1 }')"
    reason=""
    if [[ ! "${max_files}" =~ ^[0-9]+$ || ! "${max_kb}" =~ ^[0-9]+$ ]]; then
        logger -t podshift-qdl-validate -p err "PODSHIFT_DROP_MAX_BUNDLE_FILES or PODSHIFT_DROP_MAX_BUNDLE_UNPACKED is not set to a whole number"
        reason="the bundle limits are not set"
    elif [[ ! "${bytes}" =~ ^[0-9]+$ ]]; then
        reason="the bundle size could not be read"
    elif (( files > max_files )); then
        reason="the bundle has ${files} files, more than ${max_files}"
    elif (( bytes > max_kb * 1024 )); then
        reason="the bundle unpacks to $(( (bytes + 1023) / 1024 )) KB, more than ${max_kb} KB"
    fi
    if [[ -n "${reason}" ]]; then
        logger -t podshift-qdl-validate -p warn "${zip_name}.zip: ${reason}"
        log-drop-history "${id}" "${zip_name}.zip" refused "${reason}"
        rm -rf "${tmp_dir}"
        move-file "${file}" "${rejected_dir}"
        return 0
    fi

    # unzip the bundle flat, never overwriting, so a malicious bundle cannot write outside the temp dir
    if ! unzip -jqn "${file}" -d "${tmp_dir}" 2>/dev/null; then
        logger -t podshift-qdl-validate -p warn "corrupt bundle, discarding: ${zip_name}.zip"
        log-drop-history "${id}" "${zip_name}.zip" refused "corrupt bundle"
        rm -rf "${tmp_dir}"
        move-file "${file}" "${trash_dir}"
        return 0
    fi

    # Every file of the bundle gets the drop ID of the bundle.
    if [[ -n "${id}" ]]; then
        mapfile -d "" -t entries < <(find "${tmp_dir}" -type f -print0)
        for entry in "${entries[@]}"; do
            set-drop-id "${entry}" "${id}" || logger -t podshift-qdl-validate -p warn "${zip_name}.zip: could not set the drop ID on $(basename "${entry}")"
        done
    fi

    # Verify every entry is a valid quadlet.
    # shellcheck source=./check-quadlet.sh
    declare -F check-quadlet >/dev/null || source "${DIR_80FAA91926EE}/check-quadlet.sh"
    reason=""
    while IFS= read -r -d '' entry; do
        if ! reason="$(check-quadlet "${entry}")"; then
            break
        fi
        reason=""
    done < <(find "${tmp_dir}" -type f -print0 | LC_ALL=C sort -z)

    if [[ -n "${reason}" ]]; then
        logger -t podshift-qdl-validate -p warn "${zip_name}.zip: ${reason}"
        log-drop-history "${id}" "${zip_name}.zip" failed "${reason}"
        rm -rf "${tmp_dir}"
        move-file "${file}" "${rejected_dir}"
        return 0
    fi

    # An installed app is never replaced.
    # shellcheck source=./check-installed-item.sh
    declare -F check-installed-item >/dev/null || source "${DIR_80FAA91926EE}/check-installed-item.sh"
    reason="$(check-installed-item "${tmp_dir}" "${quadlets_dir}" "${zip_name}")" && status=0 || status=$?
    if (( status == 2 )); then
        logger -t podshift-qdl-validate -p info "${zip_name}.zip is already installed with the same content"
        log-drop-history "${id}" "${zip_name}.zip" unchanged
        rm -rf "${tmp_dir}"
        move-file "${file}" "${trash_dir}"
        return 0
    fi
    if (( status == 0 )); then
        # shellcheck source=./check-quadlet-install.sh
        declare -F check-quadlet-install >/dev/null || source "${DIR_80FAA91926EE}/check-quadlet-install.sh"
        while IFS= read -r -d '' entry; do
            if ! reason="$(check-quadlet-install "${entry}" "${quadlets_dir}" "${source_dir}" "${tmp_dir}")"; then
                status=1
                break
            fi
        done < <(find "${tmp_dir}" -type f -print0 | LC_ALL=C sort -z)
    fi
    if (( status != 0 )); then
        logger -t podshift-qdl-validate -p warn "${zip_name}.zip: ${reason}"
        log-drop-history "${id}" "${zip_name}.zip" refused "${reason}"
        rm -rf "${tmp_dir}"
        move-file "${file}" "${rejected_dir}"
        return 0
    fi

    # Create the bundle directory in the source.
    # Rename on a name clash instead of overwriting: a file already being
    # processed must not be clobbered by a concurrently dropped newer version.
    if [[ -e "${bundle_dir}" ]]; then
        bundle_dir="${bundle_dir}.$(date +%s%N)"
    fi
    if ! mkdir -p "${bundle_dir}"; then
        logger -t podshift-qdl-validate -p err "failed to create bundle directory: ${bundle_dir}"
        log-drop-history "${id}" "${zip_name}.zip" failed "the bundle folder could not be created"
        rm -rf "${tmp_dir}"
        move-file "${file}" "${trash_dir}"
        return 0
    fi

    # Install each extracted quadlet into the bundle directory (flattened).
    # shellcheck source=./install-file.sh
    declare -F install-file >/dev/null || source "${DIR_80FAA91926EE}/install-file.sh"
    while IFS= read -r -d '' entry; do
        install-file "${entry}" "${bundle_dir}"
    done < <(find "${tmp_dir}" -type f -print0)

    # Consume the bundle after a successful unpack.
    rm -f "${file}"
    logger -t podshift-qdl-validate -p info "unpacked ${zip_name}.zip into $(basename "${bundle_dir}")"
    log-drop-history "${id}" "${zip_name}.zip" validated
    rm -rf "${tmp_dir}"
    return 0
}
