#!/usr/bin/env bash
# @file: enable-pcp.sh
# @source-dir: src/server/opt/podshift/rpm/posttrans
# @dest-dir: /opt/podshift/rpm/posttrans
# @host-edit: no
# @group: posttrans
# @category: step
# @step: PS-PT-PCP
# @description: Enables and starts PCP metrics (pmcd and pmlogger) and Cockpit (cockpit.socket).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Enables and starts Performance Co-Pilot (PCP) so system metrics are
# collected from the first boot on, and Cockpit so its web console is
# reachable right after the install.
#
# pmcd is the PCP collector daemon and pmlogger records its metrics to disk.
# cockpit.socket starts the Cockpit web console on demand.
# The system preset only enables them, it does not start them, so without
# this step they stay inactive until the next reboot.
#
# See more: https://pcp.io

if [[ -z "${DIR_336F791ABB4F:-}" ]]; then
    DIR_336F791ABB4F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_336F791ABB4F
fi

# @description: Enables and starts pmcd, pmlogger and cockpit.socket.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
enable-pcp() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-PCP"
    local service
    # shellcheck source=../../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_336F791ABB4F}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Enabling and starting PCP metrics and Cockpit..."

    for service in pmcd pmlogger cockpit.socket; do
        if systemctl is-enabled --quiet "${service}" 2>/dev/null; then
            echo -e "\t${service}: already enabled"
        else
            echo -e "\t${service}: enabling..."
            systemctl enable "${service}" 2>/dev/null \
                || print-step-warn "failed to enable ${service}."
        fi

        if systemctl is-active --quiet "${service}" 2>/dev/null; then
            echo -e "\t${service}: already started"
        else
            echo -e "\t${service}: starting..."
            systemctl start "${service}" 2>/dev/null \
                || print-step-warn "failed to start ${service}."
        fi
    done

    print-step-ok
}
