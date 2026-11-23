#!/usr/bin/env bash
# @file: podshift-network-set-device-menu.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Interactive menu to select a network device.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_8116CD32AF9C:-}" ]]; then
    DIR_8116CD32AF9C="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_8116CD32AF9C
fi

# @description: Interactive menu to select a network device.
podshift-network-set-device-menu() {
    local detected dev i choice
    local -a devices
    # shellcheck source=../../../../fn/network/nw-device.sh
    declare -F nw-device >/dev/null || source "${DIR_8116CD32AF9C}/../../../../fn/network/nw-device.sh"
    detected="$(nw-device)"
    # shellcheck source=../../../../fn/network/nw-list-devices.sh
    declare -F nw-list-devices >/dev/null || source "${DIR_8116CD32AF9C}/../../../../fn/network/nw-list-devices.sh"
    while IFS= read -r dev; do
        devices+=("${dev}")
    done < <(nw-list-devices)

    if [[ ${#devices[@]} -eq 0 ]]; then
        echo "No devices found." >&2
        return 1
    fi

    echo "Available devices:"
    for i in "${!devices[@]}"; do
        dev="${devices[$i]}"
        if [[ "${dev}" == "${detected}" ]]; then
            echo "  $((i + 1)). ${dev}   (detected, current)"
        else
            echo "  $((i + 1)). ${dev}"
        fi
    done
    echo

    read -r -p "Select [1-${#devices[@]}] or [c]ancel: " choice
    case "${choice}" in
        c|C|"") echo "Cancelled."; return 0 ;;
    esac
    if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#devices[@]} )); then
        # shellcheck source=./podshift-network-set-write.sh
        declare -F podshift-network-set-write >/dev/null || source "${DIR_8116CD32AF9C}/podshift-network-set-write.sh"
        podshift-network-set-write "PODSHIFT_NW_DEVICE" "${devices[$((choice - 1))]}" 0 1
    else
        echo "Invalid selection." >&2
        return 1
    fi
}
