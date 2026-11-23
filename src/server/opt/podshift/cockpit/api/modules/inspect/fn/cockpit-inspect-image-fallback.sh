#!/usr/bin/env bash
# @file: cockpit-inspect-image-fallback.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/inspect/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/inspect/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Retries an image that podman did not find by its ref, through the image list.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_D44F671318EB:-}" ]]; then
    DIR_D44F671318EB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_D44F671318EB
fi

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
    # shellcheck source=./cockpit-inspect-podman.sh
    declare -F cockpit-inspect-podman >/dev/null || source "${DIR_D44F671318EB}/cockpit-inspect-podman.sh"
    ref="${1-}"
    # shellcheck source=../../../fn/inspect/cockpit-inspect-image-ref.sh
    declare -F cockpit-inspect-image-ref >/dev/null || source "${DIR_D44F671318EB}/../../../fn/inspect/cockpit-inspect-image-ref.sh"
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
