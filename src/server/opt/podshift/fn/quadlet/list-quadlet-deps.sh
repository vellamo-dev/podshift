#!/usr/bin/env bash
# @file: list-quadlet-deps.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Prints the other quadlet files and the Podman secrets that a quadlet file refers to.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints each quadlet file name and each secret:<name> that the file refers to, sorted, once each.
# @details:
#   Reads Network=, Pod=, Image= and Volume= (the part before the first colon), Mount= (the
#   source= or src= field) and Secret= (the part before the first comma) in any section. A value
#   ending in .container, .network, .volume, .pod, .image or .build is a quadlet reference (per
#   the Podman quadlet docs). A plain name is printed as plain:<name>.network for Network= (not
#   host, none, bridge, private, slirp4netns, pasta, container: or ns:) and as
#   plain:<name>.volume for a Volume= source before a colon or a Mount= type=volume source,
#   because the name rule makes <name>.network and <name>.volume create the Podman objects named
#   <name>. Paths, anonymous volumes, plain Pod= and plain Image= (registry images) are not
#   references. [Unit] keys such as Requires= and After= are not read. Comment lines and
#   continuation lines are skipped.
# @arg: $1 - quadlet file.
# @stdout: one reference per line, for example web.network, plain:data.volume or secret:db-password.
# @exitcode: 0 if the file was read, 1 if it cannot be read.
list-quadlet-deps() {
    local file line key value ref field continued plain mount_type
    local -a refs fields
    file="${1-}"
    [[ -f "${file}" && -r "${file}" ]] || return 1
    refs=()
    continued=""
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        if [[ -n "${continued}" ]]; then
            [[ "${line}" == *"\\" ]] || continued=""
            continue
        fi
        [[ -z "${line}" || "${line}" == "#"* || "${line}" == ";"* || "${line}" == "["* || "${line}" != *=* ]] && continue
        [[ "${line}" == *"\\" ]] && continued="yes"
        key="${line%%=*}"
        key="${key%"${key##*[![:space:]]}"}"
        value="${line#*=}"
        value="${value#"${value%%[![:space:]]*}"}"
        ref=""
        plain=""
        case "${key}" in
            Network)
                ref="${value%%:*}"
                case "${ref}" in
                    host|none|bridge|private|slirp4netns|pasta|container|ns) ;;
                    *) plain="network" ;;
                esac
                ;;
            Pod|Image)
                ref="${value%%:*}"
                ;;
            Volume)
                ref="${value%%:*}"
                [[ "${value}" == *:* ]] && plain="volume"
                ;;
            Mount)
                mount_type=""
                IFS=',' read -r -a fields <<< "${value}"
                for field in "${fields[@]}"; do
                    case "${field}" in
                        source=*|src=*) ref="${field#*=}" ;;
                        type=*) mount_type="${field#*=}" ;;
                    esac
                done
                [[ "${mount_type}" == "volume" ]] && plain="volume"
                ;;
            Secret)
                [[ -n "${value%%,*}" ]] && refs+=("secret:${value%%,*}")
                ;;
        esac
        case "${ref}" in
            ?*.container|?*.network|?*.volume|?*.pod|?*.image|?*.build) refs+=("${ref}") ;;
            ""|[!A-Za-z0-9]*|*[!A-Za-z0-9_.-]*) ;;
            *) [[ -n "${plain}" ]] && refs+=("plain:${ref}.${plain}") ;;
        esac
    done < "${file}"
    (( ${#refs[@]} > 0 )) || return 0
    printf '%s\n' "${refs[@]}" | LC_ALL=C sort -u
    return 0
}
