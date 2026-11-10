#!/usr/bin/env bash
# @file: enable-nw-manager.sh
# @source-dir: src/server/opt/podshift/rpm/post
# @dest-dir: /opt/podshift/rpm/post
# @host-edit: no
# @group: post
# @category: step
# @step: PS-PO-ENM
# @description: Enables and starts NetworkManager.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# NetworkManager provides automatic network detection and configuration for the system.

if [[ -z "${DIR_7E317E9021FA:-}" ]]; then
    DIR_7E317E9021FA="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7E317E9021FA
fi

# @description: Enables and starts NetworkManager.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
enable-nw-manager() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PO-ENM"
    # shellcheck source=../../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_7E317E9021FA}/../../fn/utils/print-step.sh"

    print-step-header "${step_tag}" "Enabling and starting Network Manager..."

    if systemctl is-enabled --quiet NetworkManager 2>/dev/null; then
        echo -e "\tAlready enabled"
    else
        echo -e "\tEnabling..."
        systemctl enable NetworkManager 2>/dev/null \
            || print-step-warn "failed to enable NetworkManager."
    fi

    if systemctl is-active --quiet NetworkManager 2>/dev/null; then
        echo -e "\tAlready started"
    else
        echo -e "\tStarting..."
        systemctl start NetworkManager 2>/dev/null \
            || print-step-warn "failed to start NetworkManager."
    fi

    print-step-ok
}
