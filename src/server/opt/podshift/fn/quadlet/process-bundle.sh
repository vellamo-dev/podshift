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

# @description: Unpacks a .zip bundle and checks every entry with check-quadlet.
# @details:
#   A valid bundle goes to a bundle directory in source, an invalid one to rejected, and a corrupt
#   one to trash.
# @arg: $1 - .zip file
# @arg: $2 - source directory
# @arg: $3 - rejected directory
# @arg: $4 - trash directory
# @exitcode: 0 always (non-fatal).
process-bundle() {
    local file source_dir rejected_dir trash_dir zip_name bundle_dir tmp_dir
    local entry reason
    file="${1}"
    source_dir="${2}"
    rejected_dir="${3}"
    trash_dir="${4}"
    zip_name="$(basename "${file}")"
    [[ "${zip_name}" =~ ^(.+)\.[0-9]+$ ]] && zip_name="${BASH_REMATCH[1]}"
    zip_name="${zip_name%.zip}"
    bundle_dir="${source_dir}/${zip_name}.qdl-bundle"

    # shellcheck source=./move-file.sh
    declare -F move-file >/dev/null || source "${DIR_80FAA91926EE}/move-file.sh"

    tmp_dir="$(mktemp -d)" || {
        logger -t podshift-qdl-validate -p err "failed to create temp directory"
        return 0
    }

    # unzip the bundle but ensure that a malicious bundle cannot write outside the temp dir
    if ! unzip -jqo "${file}" -d "${tmp_dir}" 2>/dev/null; then
        logger -t podshift-qdl-validate -p warn "corrupt bundle, discarding: ${zip_name}.zip"
        rm -rf "${tmp_dir}"
        move-file "${file}" "${trash_dir}"
        return 0
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
    rm -rf "${tmp_dir}"
    return 0
}
