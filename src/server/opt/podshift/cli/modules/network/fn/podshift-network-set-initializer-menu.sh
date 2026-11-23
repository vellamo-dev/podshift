#!/usr/bin/env bash
# @file: podshift-network-set-initializer-menu.sh
# @source-dir: src/server/opt/podshift/cli/modules/network/fn
# @dest-dir: /opt/podshift/cli/modules/network/fn
# @host-edit: no
# @group: network
# @category: helper
# @description: Interactive menu to select a network initializer, detected from the system.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_85DBE3318EE5:-}" ]]; then
    DIR_85DBE3318EE5="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_85DBE3318EE5
fi

# @description: Interactive menu to select a network initializer, detected from the system.
podshift-network-set-initializer-menu() {
    local -a values labels
    local i choice backend
    # shellcheck source=../../../../fn/network/nw-backend.sh
    declare -F nw-backend >/dev/null || source "${DIR_85DBE3318EE5}/../../../../fn/network/nw-backend.sh"
    backend="$(nw-backend)"

    # shellcheck source=../../../../fn/network/is-cloud-init-present.sh
    declare -F is-cloud-init-present >/dev/null || source "${DIR_85DBE3318EE5}/../../../../fn/network/is-cloud-init-present.sh"
    if is-cloud-init-present; then
        values+=("cloud-init")
        labels+=("cloud-init (cloud images, e.g. Hetzner)")
    fi
    case "${backend}" in
        NetworkManager)
            values+=("NetworkManager")
            labels+=("NetworkManager (active)")
            ;;
        systemd-networkd)
            values+=("systemd-networkd")
            labels+=("systemd-networkd (active)")
            ;;
    esac

    if [[ ${#values[@]} -eq 0 ]]; then
        echo "No network initializer detected." >&2
        return 1
    fi

    echo "Detected initializers:"
    for i in "${!values[@]}"; do
        echo "  $((i + 1)). ${labels[$i]}"
    done
    echo

    read -r -p "Select [1-${#values[@]}] or [c]ancel: " choice
    case "${choice}" in
        c|C|"") echo "Cancelled."; return 0 ;;
    esac
    if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#values[@]} )); then
        # shellcheck source=./podshift-network-set-write.sh
        declare -F podshift-network-set-write >/dev/null || source "${DIR_85DBE3318EE5}/podshift-network-set-write.sh"
        podshift-network-set-write "PODSHIFT_NW_INITIALIZER" "${values[$((choice - 1))]}" 0 1
    else
        echo "Invalid selection." >&2
        return 1
    fi
}
