#!/usr/bin/env bash
# @file: cockpit-images-quadlet-ref.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Gives the image reference that a Quadlet .image file pulls.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the image reference from ImageTag= or Image= in the [Image] section.
# @details:
#   ImageTag= wins over Image=, because Quadlet stores the pulled image under that name. The last
#   value of each key in the [Image] section wins. Spaces around the key, the equal sign and the
#   value are ignored, and surrounding quotes are removed. A reference with no tag and no digest
#   gets :latest, like podman pull.
# @arg: $1 - the file text.
# @stdout: the image reference, for example docker.io/library/busybox:latest.
# @exitcode: 0 when a reference was printed, 1 when the file has no Image= or ImageTag=.
cockpit-images-quadlet-ref() {
    local text line section key value image tag ref
    text="${1-}"
    section=""
    image=""
    tag=""
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%$'\r'}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "${line}" && "${line}" != \#* && "${line}" != \;* ]] || continue
        if [[ "${line}" =~ ^\[(.*)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi
        [[ "${section}" == "Image" && "${line}" == *=* ]] || continue
        key="${line%%=*}"
        key="${key%"${key##*[![:space:]]}"}"
        [[ "${key}" == "Image" || "${key}" == "ImageTag" ]] || continue
        value="${line#*=}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"
        [[ -n "${value}" ]] || continue
        if [[ "${key}" == "Image" ]]; then
            image="${value}"
        else
            tag="${value}"
        fi
    done <<< "${text}"
    ref="${tag:-${image}}"
    [[ -n "${ref}" ]] || return 1
    if [[ "${ref}" != *@* && "${ref##*/}" != *:* ]]; then
        ref="${ref}:latest"
    fi
    printf '%s\n' "${ref}"
    return 0
}
