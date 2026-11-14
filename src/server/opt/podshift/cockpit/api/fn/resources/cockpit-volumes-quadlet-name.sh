#!/usr/bin/env bash
# @file: cockpit-volumes-quadlet-name.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Gives the Podman volume name that a Quadlet .volume file creates.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the volume name from VolumeName= in the [Volume] section, or systemd-<base>.
# @details:
#   The last VolumeName= in the [Volume] section wins. Without one, Quadlet names the volume
#   systemd-<file name without .volume>. Spaces around the key, the equal sign and the value are
#   ignored, and surrounding quotes are removed.
# @arg: $1 - the file name or path, for example pgdata.volume.
# @arg: $2 - the file text.
# @stdout: the volume name.
# @exitcode: 0 when a name was printed, 1 when the file name is empty.
cockpit-volumes-quadlet-name() {
    local base text line section key value name
    base="${1-}"
    text="${2-}"
    base="${base##*/}"
    base="${base%.volume}"
    [[ -n "${base}" ]] || return 1
    section=""
    name=""
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%$'\r'}"
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "${line}" && "${line}" != \#* && "${line}" != \;* ]] || continue
        if [[ "${line}" =~ ^\[(.*)\]$ ]]; then
            section="${BASH_REMATCH[1]}"
            continue
        fi
        [[ "${section}" == "Volume" && "${line}" == *=* ]] || continue
        key="${line%%=*}"
        key="${key%"${key##*[![:space:]]}"}"
        [[ "${key}" == "VolumeName" ]] || continue
        value="${line#*=}"
        value="${value#"${value%%[![:space:]]*}"}"
        value="${value#\"}"
        value="${value%\"}"
        value="${value#\'}"
        value="${value%\'}"
        [[ -n "${value}" ]] && name="${value}"
    done <<< "${text}"
    printf '%s\n' "${name:-systemd-${base}}"
    return 0
}
