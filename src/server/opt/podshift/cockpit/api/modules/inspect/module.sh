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
    # shellcheck source=./fn/cockpit-inspect-podman.sh
    declare -F cockpit-inspect-podman >/dev/null || source "${DIR_1AA607775854}/fn/cockpit-inspect-podman.sh"
    # shellcheck source=./fn/cockpit-inspect-image-fallback.sh
    declare -F cockpit-inspect-image-fallback >/dev/null || source "${DIR_1AA607775854}/fn/cockpit-inspect-image-fallback.sh"
    # shellcheck source=./fn/cockpit-inspect-write-file.sh
    declare -F cockpit-inspect-write-file >/dev/null || source "${DIR_1AA607775854}/fn/cockpit-inspect-write-file.sh"
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
