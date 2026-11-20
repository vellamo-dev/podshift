#!/usr/bin/env bats
# Unit test for cockpit-overview-config-rows (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-config-rows.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-config-rows.sh"
}

@test "TSV_ENV is always present and unset NW rows are omitted" {
    run cockpit-overview-config-rows '{}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.rows | length) == 1
        and .rows[0].id == "tsv_env"
        and .rows[0].label == "TSV_ENV"
        and .rows[0].value == null
        and (.rows[0].id | test("^[a-z0-9_]+$"))
    '
}

@test "provided values are used and missing or empty NW keys are omitted" {
    run cockpit-overview-config-rows '{"tsv_env":"dev","tsv_nw1":"192.0.2.10","tsv_nw2":null,"tsv_nw4":""}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.rows | length) == 2
        and .rows[0].id == "tsv_env" and .rows[0].value == "dev"
        and .rows[1].id == "tsv_nw1" and .rows[1].value == "192.0.2.10"
    '
}

@test "only some NW vars are listed, in numeric order" {
    run cockpit-overview-config-rows '{"tsv_env":"dev","tsv_nw3":"192.0.2.30","tsv_nw1":"192.0.2.10"}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.rows[].id] == ["tsv_env","tsv_nw1","tsv_nw3"]
        and [.rows[].label] == ["TSV_ENV","TSV_NW1","TSV_NW3"]
        and .rows[1].value == "192.0.2.10"
        and .rows[2].value == "192.0.2.30"
    '
}

@test "an empty TSV_ENV stays as a null row" {
    run cockpit-overview-config-rows '{"tsv_env":""}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '(.rows | length) == 1 and .rows[0].id == "tsv_env" and .rows[0].value == null'
}

@test "user rows with a value are appended after the built-ins" {
    run cockpit-overview-config-rows '{"tsv_env":"dev"}' '[{"id":"tsv_app","label":"TSV_APP","value":"ok"},{"id":"tsv_empty","label":"TSV_EMPTY","value":null}]'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.rows | length) == 2
        and .rows[0].value == "dev"
        and .rows[1].id == "tsv_app"
        and .rows[1].label == "TSV_APP"
        and .rows[1].value == "ok"
    '
}

@test "TSV_ENV is editable only while it is unset" {
    run cockpit-overview-config-rows '{}'
    printf '%s' "${output}" | jq -e '.rows[0].editable == true'
    run cockpit-overview-config-rows '{"tsv_env":""}'
    printf '%s' "${output}" | jq -e '.rows[0].editable == true'
    run cockpit-overview-config-rows '{"tsv_env":"dev"}'
    printf '%s' "${output}" | jq -e '.rows[0].editable == false'
}

@test "NW rows are never editable and user rows are" {
    run cockpit-overview-config-rows '{"tsv_env":"dev","tsv_nw1":"192.0.2.10","tsv_nw8":"192.0.2.80"}' '[{"id":"tsv_app","label":"TSV_APP","value":"ok"}]'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.rows[] | [.id, .editable]] == [["tsv_env",false],["tsv_nw1",false],["tsv_nw8",false],["tsv_app",true]]
        and all(.rows[]; (keys | sort) == ["editable","id","label","value"])
    '
}

@test "old user rows with a reserved prefix are not editable" {
    run cockpit-overview-config-rows '{}' '[{"id":"tsv_nworder","label":"TSV_NWORDER","value":"1"},{"id":"tsv_env2","label":"TSV_ENV2","value":"x"},{"id":"tsv_new","label":"TSV_NEW","value":"y"}]'
    printf '%s' "${output}" | jq -e '[.rows[] | [.label, .editable]] == [["TSV_ENV",true],["TSV_NWORDER",false],["TSV_ENV2",false],["TSV_NEW",true]]'
}

@test "envSuggestions lists the comma-separated tags without empty items" {
    run cockpit-overview-config-rows '{}' '[]' 'development,dev,,test,'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.envSuggestions == ["development","dev","test"]'
}

@test "envSuggestions is empty without tags" {
    run cockpit-overview-config-rows '{}'
    printf '%s' "${output}" | jq -e '.envSuggestions == []'
}

@test "a non-object values argument fails" {
    run cockpit-overview-config-rows '[]'
    [ "${status}" -ne 0 ]
}
