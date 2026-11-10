#!/usr/bin/env bash
# @file: install-file.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Installs a validated file out of the validation queue.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Installs a file into a directory with normalized permissions and ownership, renaming on collision, and logs.
# @arg: $1 - source file
# @arg: $2 - destination directory
# @arg: $3 - target file name (optional, defaults to the source file name)
# @exitcode: 0 if installed, 1 otherwise.
install-file() {
    local src dest_dir target_name target
    src="${1}"
    dest_dir="${2}"
    target_name="${3:-$(basename "${src}")}"
    target="${dest_dir}/${target_name}"
    # Rename on a name clash instead of overwriting: a file already being
    # processed must not be clobbered by a concurrently dropped newer version.
    if [[ -e "${target}" ]]; then
        target="${target}.$(date +%s%N)"
    fi
    if install -m 0644 "${src}" "${target}" 2>/dev/null && rm -f "${src}"; then
        logger -t podshift-qdl-validate -p info "installed $(basename "${src}") into $(basename "${dest_dir}")"
        return 0
    fi
    logger -t podshift-qdl-validate -p err "failed to install $(basename "${src}") into $(basename "${dest_dir}")"
    return 1
}
