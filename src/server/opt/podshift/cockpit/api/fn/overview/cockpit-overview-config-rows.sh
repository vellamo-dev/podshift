#!/usr/bin/env bash
# @file: cockpit-overview-config-rows.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the ordered Overview config rows from built-in values and user rows.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Overview config card as a rows object, built-ins first, with editable flags and tag suggestions.
# @details:
#   TSV_ENV is always included; a missing or empty value becomes null. Unset or empty
#   TSV_NW1 to TSV_NW8 rows are omitted. Optional user rows with a value are appended
#   after the network rows, in the given order. Each row gets editable: TSV_ENV only while it is
#   unset (the UI sets it once), TSV_NW* never, user rows unless their name starts with
#   TSV_NW or TSV_ENV (saved before those prefixes were reserved). envSuggestions lists the
#   suggested environment tags from the comma-separated list, empty items left out.
# @arg: $1 - a JSON object mapping built-in row ids to string values or null.
# @arg: $2 - optional JSON array of user {id, label, value} rows.
# @arg: $3 - optional comma-separated suggested environment tags (PODSHIFT_ENV_TYPES).
# @stdout: one JSON object with a rows array and an envSuggestions array.
# @exitcode: 0 when the rows were written, 1 when an argument is not the expected JSON type.
cockpit-overview-config-rows() {
    local values extra tags
    values="${1-}"
    extra="${2-[]}"
    tags="${3-}"
    [[ -n "${extra}" ]] || extra="[]"
    jq -n -c --argjson values "${values}" --argjson extra "${extra}" --arg tags "${tags}" '
        if ($values | type) != "object" then halt_error(1) else . end
        | if ($extra | type) != "array" then halt_error(1) else . end
        | def v($k): if ($values | has($k)) then $values[$k] else null end;
        def is_set($x): $x != null and $x != "";
        {rows: (
            [{id: "tsv_env", label: "TSV_ENV", value: (if is_set(v("tsv_env")) then v("tsv_env") else null end)}
                | . + {editable: (.value == null)}]
            + ([
                {id: "tsv_nw1", label: "TSV_NW1", value: v("tsv_nw1")},
                {id: "tsv_nw2", label: "TSV_NW2", value: v("tsv_nw2")},
                {id: "tsv_nw3", label: "TSV_NW3", value: v("tsv_nw3")},
                {id: "tsv_nw4", label: "TSV_NW4", value: v("tsv_nw4")},
                {id: "tsv_nw5", label: "TSV_NW5", value: v("tsv_nw5")},
                {id: "tsv_nw6", label: "TSV_NW6", value: v("tsv_nw6")},
                {id: "tsv_nw7", label: "TSV_NW7", value: v("tsv_nw7")},
                {id: "tsv_nw8", label: "TSV_NW8", value: v("tsv_nw8")}
            ] | map(select(is_set(.value)) | . + {editable: false}))
            + ($extra | map(select(is_set(.value)) | {id, label, value, editable: ((.label | startswith("TSV_NW") or startswith("TSV_ENV")) | not)}))
        ),
        envSuggestions: ($tags | split(",") | map(select(length > 0)))}
    '
}
