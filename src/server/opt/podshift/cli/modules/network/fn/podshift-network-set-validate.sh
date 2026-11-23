#!/usr/bin/env bash
# @file: podshift-network-set-validate.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Validates that a device or initializer was detected.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3F70C9EB7FF9:-}" ]]; then
    DIR_3F70C9EB7FF9="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3F70C9EB7FF9
fi

# @description: Validates that a device or initializer was detected.
# @arg: $1 - key, $2 - value.
# @exitcode: 0 if detected, 1 if unknown.
podshift-network-set-validate() {
    local key value
    key="${1}"
    value="${2}"
    # shellcheck source=../../../../fn/network/nw-backend.sh
    declare -F nw-backend >/dev/null || source "${DIR_3F70C9EB7FF9}/../../../../fn/network/nw-backend.sh"
    case "${key}" in
        PODSHIFT_NW_DEVICE)
            [[ -d "/sys/class/net/${value}" ]]
            return
            ;;
        PODSHIFT_NW_INITIALIZER)
            case "${value}" in
                cloud-init)
                    # shellcheck source=../../../../fn/network/is-cloud-init-present.sh
                    declare -F is-cloud-init-present >/dev/null || source "${DIR_3F70C9EB7FF9}/../../../../fn/network/is-cloud-init-present.sh"
                    is-cloud-init-present
                    return
                    ;;
                NetworkManager)   [[ "$(nw-backend)" == "NetworkManager" ]]; return ;;
                systemd-networkd) [[ "$(nw-backend)" == "systemd-networkd" ]]; return ;;
            esac
            ;;
    esac
    return 1
}
