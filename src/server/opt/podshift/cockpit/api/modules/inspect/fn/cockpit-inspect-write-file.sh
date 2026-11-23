#!/usr/bin/env bash
# @file: cockpit-inspect-write-file.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/inspect/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/inspect/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Writes the inspect object as pretty JSON to a new private file and prints its path and size.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_5C92BFA2569F:-}" ]]; then
    DIR_5C92BFA2569F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_5C92BFA2569F
fi

# @description: Writes the inspect object as pretty JSON to a new private file and prints its path and size.
# @details:
#   Inspect files older than 10 minutes in the same folder are removed first, so files that the UI
#   did not remove do not pile up. The new file is inspect-<random>.json with mode 0600. The
#   caller reads it once and removes it.
# @arg: $1 - kind.
# @arg: $2 - ref as requested.
# @arg: $3 - JSON array from podman <kind> inspect with at least one object.
# @stdout: one JSON object {kind, ref, found: true, file: {path, size}}.
# @exitcode: 0 when the file was written, 1 otherwise.
cockpit-inspect-write-file() {
    local kind ref raw dir tmp file size
    # shellcheck source=./cockpit-inspect-file-dir.sh
    declare -F cockpit-inspect-file-dir >/dev/null || source "${DIR_5C92BFA2569F}/cockpit-inspect-file-dir.sh"
    kind="${1-}"
    ref="${2-}"
    raw="${3-}"
    dir="$(cockpit-inspect-file-dir)" || return 1
    find -P "${dir}" -maxdepth 1 -type f -name 'inspect-*.json' -mmin +10 -delete 2>/dev/null || true
    # mktemp makes the file 0600. The folder is private, so the rename to .json is safe.
    tmp="$(mktemp "${dir}/inspect-XXXXXXXXXX")" || return 1
    file="${tmp}.json"
    if ! mv -f -- "${tmp}" "${file}"; then
        rm -f -- "${tmp}"
        return 1
    fi
    # The path is absolute, so it cannot be taken for an option. BSD chmod refuses --.
    chmod 0600 "${file}" || { rm -f -- "${file}"; return 1; }
    if ! printf '%s' "${raw}" | jq -e --indent 4 'if type == "array" and length > 0 and (.[0] | type) == "object" then .[0] else error("no object") end' > "${file}" 2>/dev/null; then
        rm -f -- "${file}"
        return 1
    fi
    size="$(LC_ALL=C wc -c < "${file}" | tr -d '[:space:]')"
    jq -n -c --arg kind "${kind}" --arg ref "${ref}" --arg path "${file}" --argjson size "${size}" \
        '{kind: $kind, ref: $ref, found: true, file: {path: $path, size: $size}}'
}
