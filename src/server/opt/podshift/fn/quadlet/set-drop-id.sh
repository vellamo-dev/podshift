#!/usr/bin/env bash
# @file: set-drop-id.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Writes a Quadlet file with its drop ID as line 1, replacing any older drop ID line.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_C2F3FE66C742:-}" ]]; then
    DIR_C2F3FE66C742="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C2F3FE66C742
fi

# @description: Writes "# podshift-drop-id: <uuid>" and the file without its older drop ID lines to the target.
# @details:
#   The new content goes to a hidden temp file (.drop-id.XXXXXX) in the folder of the target, gets
#   mode 0644 and is renamed to the target, so a watcher never sees half a file and hidden files
#   are skipped by the pipeline. The target is the file itself unless one is given; the source file
#   is then kept, and the caller removes it. Podman reads the line as a comment.
# @arg: $1 - Quadlet file.
# @arg: $2 - drop ID, a UUIDv7.
# @arg: $3 - optional target file, the file itself by default.
# @exitcode: 0 when it was written, 1 when the file cannot be read, the ID is not valid or a write fails.
set-drop-id() {
    local file id target tmp
    file="${1-}"
    id="${2-}"
    target="${3:-${file}}"
    [[ -f "${file}" && -r "${file}" ]] || return 1
    # shellcheck source=../utils/is-valid-uuid7.sh
    declare -F is-valid-uuid7 >/dev/null || source "${DIR_C2F3FE66C742}/../utils/is-valid-uuid7.sh"
    is-valid-uuid7 "${id}" || return 1
    tmp="$(mktemp "$(dirname -- "${target}")/.drop-id.XXXXXX" 2>/dev/null)" || return 1
    if { printf '# podshift-drop-id: %s\n' "${id}" && sed '/^# podshift-drop-id: /d' "${file}"; } > "${tmp}" \
        && chmod 0644 "${tmp}" && mv -f "${tmp}" "${target}"; then
        return 0
    fi
    rm -f "${tmp}"
    return 1
}
