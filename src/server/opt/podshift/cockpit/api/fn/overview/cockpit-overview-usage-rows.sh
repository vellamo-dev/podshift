#!/usr/bin/env bash
# @file: cockpit-overview-usage-rows.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the ordered Overview usage rows from a values object.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Overview usage card as a rows object, in a fixed order.
# @details:
#   Missing keys become null. Each value is already a string such as "3 / 5" or "0", or null.
# @arg: $1 - a JSON object mapping row ids to string values or null.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 when the argument is not a JSON object.
cockpit-overview-usage-rows() {
    local values
    values="${1-}"
    jq -n -c --argjson values "${values}" '
        if ($values | type) != "object" then halt_error(1) else . end
        | def v($k): if ($values | has($k)) then $values[$k] else null end;
        {rows: [
            {id: "services", label: "Services", value: v("services")},
            {id: "networks", label: "Networks", value: v("networks")},
            {id: "containers", label: "Containers", value: v("containers")},
            {id: "volumes", label: "Volumes", value: v("volumes")},
            {id: "images", label: "Images", value: v("images")},
            {id: "quadlets", label: "Quadlets", value: v("quadlets")},
            {id: "secrets", label: "Secrets", value: v("secrets")}
        ]}
    '
}
