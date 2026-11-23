#!/usr/bin/env bash
# @file: check-quadlet-deps.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Checks that every quadlet file and Podman secret a dropped quadlet refers to is there.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_74273C5D6132:-}" ]]; then
    DIR_74273C5D6132="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_74273C5D6132
fi

# @description: Checks the references from list-quadlet-deps and prints the first one that is missing.
# @details:
#   A referenced quadlet file is there when it is in the same bundle folder, installed
#   (find-installed-quadlet), or already validated and waiting in the source directory (a single
#   file, a collision copy or a file of a bundle folder), so files dropped together install in rank
#   order. A secret is there when "podman secret exists" says so.
#   A plain:<name> reference is skipped: a matching quadlet satisfies it, and a plain name with
#   none, such as a network made outside Quadlet, was never refused, so install is unchanged.
#   Pods are not supported yet, so a file with a Pod= key is refused before any reference is checked.
# @arg: $1 - dropped quadlet file.
# @arg: $2 - directory where Podman installs quadlets.
# @arg: $3 - quadlet source directory.
# @arg: $4 - folder with the other files of the same bundle, or empty for a single file.
# @stdout: the reason when a reference is missing or Pod= is set, one line.
# @exitcode: 0 if every reference is there, 1 otherwise.
check-quadlet-deps() {
    local file quadlets_dir source_dir own_dir name ref secret
    file="${1-}"
    quadlets_dir="${2-}"
    source_dir="${3-}"
    own_dir="${4-}"

    # shellcheck source=./get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_74273C5D6132}/get-original-name.sh"
    # shellcheck source=./list-quadlet-deps.sh
    declare -F list-quadlet-deps >/dev/null || source "${DIR_74273C5D6132}/list-quadlet-deps.sh"
    # shellcheck source=./find-installed-quadlet.sh
    declare -F find-installed-quadlet >/dev/null || source "${DIR_74273C5D6132}/find-installed-quadlet.sh"
    name="$(get-original-name "${file}")"
    if grep -qE '^[[:space:]]*Pod[[:space:]]*=' "${file}" 2>/dev/null; then
        echo "${name}: Pod= is not supported yet"
        return 1
    fi

    while IFS= read -r ref; do
        [[ -n "${ref}" ]] || continue
        [[ "${ref}" == plain:* ]] && continue
        if [[ "${ref}" == secret:* ]]; then
            secret="${ref#secret:}"
            if ! podman secret exists "${secret}" >/dev/null 2>&1; then
                echo "${name} needs the Podman secret ${secret}, which does not exist"
                return 1
            fi
            continue
        fi
        [[ -n "${own_dir}" && -f "${own_dir}/${ref}" ]] && continue
        find-installed-quadlet "${ref}" "${quadlets_dir}" >/dev/null && continue
        if [[ -d "${source_dir}" && -n "$(find "${source_dir}" -mindepth 1 -maxdepth 2 -type f \( -name "${ref}" -o -name "${ref}.[0-9]*" \) 2>/dev/null)" ]]; then
            continue
        fi
        echo "${name} needs ${ref}, which is not installed"
        return 1
    done < <(list-quadlet-deps "${file}")
    return 0
}
