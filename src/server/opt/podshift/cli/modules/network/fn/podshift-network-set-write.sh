#!/usr/bin/env bash
# @file: podshift-network-set-write.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Writes the network override with confirmation.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_CDCD78BC3F06:-}" ]]; then
    DIR_CDCD78BC3F06="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_CDCD78BC3F06
fi

# @description: Writes the network override with confirmation.
# @arg: $1 - key, $2 - value, $3 - force (0/1), $4 - known (0/1).
podshift-network-set-write() {
    local key value force known answer prompt label b n
    key="${1}"
    value="${2}"
    force="${3}"
    known="${4:-1}"
    b=""
    n=""
    # shellcheck source=../../../../fn/utils/is-interactive-output.sh
    declare -F is-interactive-output >/dev/null || source "${DIR_CDCD78BC3F06}/../../../../fn/utils/is-interactive-output.sh"
    if is-interactive-output 2; then
        b=$'\033[1m'
        n=$'\033[0m'
    fi
    case "${key}" in
        PODSHIFT_NW_DEVICE)      label="Device" ;;
        PODSHIFT_NW_INITIALIZER) label="Initializer" ;;
    esac
    if [[ "${known}" -eq 1 ]]; then
        prompt="Set ${key}=${value}. Continue? [${b}y${n}es/${b}c${n}ancel] "
    else
        prompt="${label} '${value}' does not exist in the system. Are you sure you want to set it? [${b}y${n}es/${b}c${n}ancel] "
    fi
    if [[ "${force}" -eq 1 ]]; then
        answer="yes"
    else
        read -r -p "${prompt}" answer
    fi
    case "${answer}" in
        yes|y|Y)
            # shellcheck source=../../../../fn/utils/update-podshift-conf.sh
            declare -F update-podshift-conf >/dev/null || source "${DIR_CDCD78BC3F06}/../../../../fn/utils/update-podshift-conf.sh"
            update-podshift-conf "${key}" "${value}"
            ;;
        *)
            echo "Cancelled."
            ;;
    esac
}
