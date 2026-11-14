#!/usr/bin/env bash
# @file: cockpit-networks-unit-networks.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Lists the Podman networks that a systemd service file creates with podman network create.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints each network name passed to podman network create in the service text.
# @details:
#   Only Exec lines (ExecStart=, ExecStartPre= and so on) are read. The name is the first word
#   after create that is not an option or an option value. Options that take a separate value,
#   such as --subnet 10.0.0.0/24, skip that value. Quotes around words are removed. Each name is
#   printed once, in file order.
# @arg: $1 - the service file text.
# @stdout: one network name per line, or nothing.
# @exitcode: 0 always.
cockpit-networks-unit-networks() {
    local text line cmd word i n found skip name
    local -a words seen
    text="${1-}"
    seen=()
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line%$'\r'}"
        line="${line#"${line%%[![:space:]]*}"}"
        [[ "${line}" == Exec*=* ]] || continue
        cmd="${line#*=}"
        read -r -a words <<< "${cmd}"
        n="${#words[@]}"
        found=-1
        for ((i = 0; i + 2 < n; i++)); do
            word="${words[i]}"
            word="${word#[-@:+!]}"
            word="${word#[-@:+!]}"
            if [[ "${word##*/}" == "podman" && "${words[i+1]}" == "network" && "${words[i+2]}" == "create" ]]; then
                found=$((i + 3))
                break
            fi
        done
        [[ "${found}" -ge 0 ]] || continue
        skip=0
        name=""
        for ((i = found; i < n; i++)); do
            word="${words[i]}"
            if [[ "${skip}" -eq 1 ]]; then
                skip=0
                continue
            fi
            case "${word}" in
                --*=*) continue ;;
                --subnet|--gateway|--ip-range|--driver|--opt|--label|--ipam-driver|--interface-name|--dns|--route|--network-dns-server|-d|-o)
                    skip=1
                    continue
                    ;;
                -*) continue ;;
            esac
            word="${word#\"}"
            word="${word%\"}"
            word="${word#\'}"
            word="${word%\'}"
            name="${word}"
            break
        done
        [[ -n "${name}" ]] || continue
        if [[ " ${seen[*]-} " != *" ${name} "* ]]; then
            seen+=("${name}")
            printf '%s\n' "${name}"
        fi
    done <<< "${text}"
    return 0
}
