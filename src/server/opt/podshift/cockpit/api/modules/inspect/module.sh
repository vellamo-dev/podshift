#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/inspect
# @dest-dir: /opt/podshift/cockpit/api/modules/inspect
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Inspect module: prints the podman inspect object of one container, image, volume, network or secret.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1AA607775854:-}" ]]; then
    DIR_1AA607775854="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1AA607775854
fi

# @description: Runs podman in the current (podshift) session.
# @arg: $@ - podman arguments.
# @stdout: podman stdout.
# @exitcode: the podman exit code, or 1 when podman is missing.
cockpit-inspect-podman() {
    podman "$@"
}

# @description: Prints the folder for inspect files in the user's runtime directory, creating it.
# @details:
#   The folder is $XDG_RUNTIME_DIR/podshift, or /run/user/<uid>/podshift when XDG_RUNTIME_DIR is
#   not set. It is created with mode 0700 and must be a real folder owned by this user.
# @stdout: the folder path.
# @exitcode: 0 when the folder is usable, 1 otherwise.
cockpit-inspect-file-dir() {
    local base dir
    base="${XDG_RUNTIME_DIR:-/run/user/${EUID}}"
    [[ "${base}" == /* && -d "${base}" ]] || return 1
    dir="${base}/podshift"
    if [[ ! -e "${dir}" ]]; then
        mkdir -m 0700 -- "${dir}" 2>/dev/null || return 1
    fi
    [[ -d "${dir}" && ! -L "${dir}" && -O "${dir}" ]] || return 1
    printf '%s\n' "${dir}"
}

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

# @description: Retries an image that podman did not find by its ref, through the image list.
# @details:
#   podman image inspect does not always find an image by a short ID. podman image ls --format
#   json is searched for the one image whose ID starts with the ref (cockpit-inspect-image-ref),
#   which is then inspected by its full ID and, if that fails too, by its first tag. Only these
#   two read-only podman calls are made.
# @arg: $1 - ref as requested, already checked by cockpit-inspect-args.
# @stdout: JSON array from podman image inspect.
# @exitcode: 0 when the image was found, 1 when no image matched, 2 when podman image ls failed.
cockpit-inspect-image-fallback() {
    local ref list resolved id tag candidate raw
    ref="${1-}"
    # shellcheck source=../../fn/inspect/cockpit-inspect-image-ref.sh
    declare -F cockpit-inspect-image-ref >/dev/null || source "${DIR_1AA607775854}/../../fn/inspect/cockpit-inspect-image-ref.sh"
    list="$(cockpit-inspect-podman image ls --format json 2>/dev/null)" || return 2
    [[ -n "${list}" ]] || list='[]'
    resolved="$(cockpit-inspect-image-ref "${list}" "${ref}")" || return 1
    id="${resolved%%$'\t'*}"
    tag="${resolved#*$'\t'}"
    for candidate in "${id}" "${tag}"; do
        [[ -n "${candidate}" && "${candidate}" != "${ref}" ]] || continue
        if raw="$(cockpit-inspect-podman image inspect -- "${candidate}" 2>/dev/null)"; then
            printf '%s\n' "${raw}"
            return 0
        fi
    done
    return 1
}

# @description: Prints the podman inspect object of one resource of the podshift user.
# @details:
#   Runs podman <kind> inspect -- <ref>, read-only. For a secret, --showsecret is never passed
#   and SecretData is removed as well (cockpit-inspect-redact), so no secret value is returned or
#   written. An image that is not found is retried once
#   through the image list (cockpit-inspect-image-fallback), so a short image ID works. When that
#   fails too, podman <kind> exists tells a missing resource (exit 1, data with found false) from a
#   podman error (the action fails). The result keeps the ref as requested. A
#   result over 131072 bytes, the module output bound, has tooLarge and size instead of object.
#   With mode file, the object is written to a private file in the runtime directory and only its
#   path and size are returned. The process runs in the podshift session, so podman already talks
#   to that user.
# @arg: $1 - action arguments as one JSON object with kind, ref and optional mode.
# @stdout: one JSON object {kind, ref, found} plus object, tooLarge and size, or file.
# @exitcode: 0 when the object was written, 1 when the arguments are refused, podman fails or the file cannot be written.
cockpit-module-inspect() {
    local parsed kind ref mode raw rc
    # shellcheck source=../../fn/inspect/cockpit-inspect-args.sh
    declare -F cockpit-inspect-args >/dev/null || source "${DIR_1AA607775854}/../../fn/inspect/cockpit-inspect-args.sh"
    # shellcheck source=../../fn/inspect/cockpit-inspect-result.sh
    declare -F cockpit-inspect-result >/dev/null || source "${DIR_1AA607775854}/../../fn/inspect/cockpit-inspect-result.sh"
    # shellcheck source=../../fn/inspect/cockpit-inspect-redact.sh
    declare -F cockpit-inspect-redact >/dev/null || source "${DIR_1AA607775854}/../../fn/inspect/cockpit-inspect-redact.sh"
    parsed="$(cockpit-inspect-args "${1-}")" || return 1
    kind="${parsed%%$'\t'*}"
    parsed="${parsed#*$'\t'}"
    ref="${parsed%%$'\t'*}"
    mode="${parsed#*$'\t'}"
    raw="$(cockpit-inspect-podman "${kind}" inspect -- "${ref}" 2>/dev/null)" && rc=0 || rc=$?
    if [[ "${rc}" -ne 0 && "${kind}" == "image" ]]; then
        raw="$(cockpit-inspect-image-fallback "${ref}")" && rc=0 || rc=$?
    fi
    if [[ "${rc}" -ne 0 ]]; then
        cockpit-inspect-podman "${kind}" exists -- "${ref}" >/dev/null 2>&1 && rc=0 || rc=$?
        if [[ "${rc}" -eq 1 ]]; then
            cockpit-inspect-result "${kind}" "${ref}" '[]' 131072
            return
        fi
        return 1
    fi
    # --showsecret is never passed; SecretData is still removed in case podman prints it.
    raw="$(cockpit-inspect-redact "${kind}" "${raw}")" || return 1
    if [[ "${mode}" == "file" ]]; then
        if [[ "$(printf '%s' "${raw}" | jq -r 'if type == "array" then length else -1 end' 2>/dev/null)" == "0" ]]; then
            cockpit-inspect-result "${kind}" "${ref}" '[]' 131072
            return
        fi
        cockpit-inspect-write-file "${kind}" "${ref}" "${raw}"
        return
    fi
    # The module output bound of cockpit-run-module.
    cockpit-inspect-result "${kind}" "${ref}" "${raw}" 131072
}
