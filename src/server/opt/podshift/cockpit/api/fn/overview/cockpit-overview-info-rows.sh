#!/usr/bin/env bash
# @file: cockpit-overview-info-rows.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the ordered Overview info rows from a values object.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Overview info card as a rows object, in a fixed order.
# @details:
#   Missing keys become null. Each value is already the display text, or null when missing.
# @arg: $1 - a JSON object mapping row ids to string values or null.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 when the argument is not a JSON object.
cockpit-overview-info-rows() {
    local values
    values="${1-}"
    jq -n -c --argjson values "${values}" '
        if ($values | type) != "object" then halt_error(1) else . end
        | def v($k): if ($values | has($k)) then $values[$k] else null end;
        {rows: [
            {id: "os", label: "OS", value: v("os")},
            {id: "podman", label: "Podman", value: v("podman")},
            {id: "podshift", label: "PodShift", value: v("podshift")},
            {id: "fail2ban", label: "Fail2Ban", value: v("fail2ban")}
        ]}
    '
}
