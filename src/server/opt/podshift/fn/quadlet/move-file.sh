#!/usr/bin/env bash
# @file: move-file.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Moves a file out of the validation queue.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Moves a file into a directory, renaming on collision, and logs.
# @arg: $1 - source file
# @arg: $2 - destination directory
# @arg: $3 - log tag (optional, default podshift-qdl-validate)
# @exitcode: 0 if moved, 1 otherwise.
move-file() {
    local src dest_dir target tag
    src="${1}"
    dest_dir="${2}"
    tag="${3:-podshift-qdl-validate}"
    target="${dest_dir}/$(basename "${src}")"
    # Rename on a name clash instead of overwriting: a file already being
    # processed must not be clobbered by a concurrently dropped newer version.
    if [[ -e "${target}" ]]; then
        target="${target}.$(date +%s%N)"
    fi
    if mv -f "${src}" "${target}" 2>/dev/null; then
        logger -t "${tag}" -p info "moved $(basename "${src}") to $(basename "${dest_dir}")"
        return 0
    fi
    logger -t "${tag}" -p err "failed to move $(basename "${src}") to $(basename "${dest_dir}")"
    return 1
}
