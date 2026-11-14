#!/usr/bin/env bats
# Unit test for cockpit-overview-config-user-rows (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-config-user-rows.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-config-user-rows.sh"
}

@test "empty text yields no user rows" {
    run cockpit-overview-config-user-rows ""
    [ "${status}" -eq 0 ]
    [ "${output}" = "[]" ]
}

@test "comments and blank lines are ignored" {
    run cockpit-overview-config-user-rows $'# Custom TSV_* variables\n\n# TSV_SKIP=1\nTSV_APP=ok\n'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e 'length == 1 and .[0].id == "tsv_app" and .[0].value == "ok"'
}

@test "user keys are sorted by key" {
    run cockpit-overview-config-user-rows $'TSV_ZED=z\nTSV_APP=a\nTSV_MID=m\n'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '[.[].id] == ["tsv_app","tsv_mid","tsv_zed"] and [.[].label] == ["TSV_APP","TSV_MID","TSV_ZED"]'
}

@test "ids are lowercase and labels keep the exact key" {
    run cockpit-overview-config-user-rows 'TSV_DB_HOST=db.example.com'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.[0].id == "tsv_db_host" and .[0].label == "TSV_DB_HOST" and .[0].value == "db.example.com" and (.[0].id | test("^[a-z0-9_]+$"))'
}

@test "invalid keys are skipped" {
    run cockpit-overview-config-user-rows $'FOO=1\nTSV_bad=x\ntsv_LOWER=1\nexport TSV_X=1\nTSV_OK=yes\n'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e 'length == 1 and .[0].id == "tsv_ok" and .[0].value == "yes"'
}

@test "built-in names in the file are skipped" {
    run cockpit-overview-config-user-rows $'TSV_ENV=dev\nTSV_NW1=1.2.3.4\nTSV_NW8=8.8.8.8\nTSV_APP=ok\n'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e 'length == 1 and .[0].id == "tsv_app"'
}

@test "a repeated key keeps the last value" {
    run cockpit-overview-config-user-rows $'TSV_APP=one\nTSV_APP=two\n'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e 'length == 1 and .[0].value == "two"'
}

@test "empty values are omitted" {
    local text
    text="TSV_EMPTY=
TSV_QUOTED=''
TSV_APP=ok
"
    run cockpit-overview-config-user-rows "${text}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e 'length == 1 and .[0].id == "tsv_app" and .[0].value == "ok"'
}

@test "single-quoted values from update-tsv-conf are unquoted" {
    run cockpit-overview-config-user-rows "TSV_NAME='it'\\''s'"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.[0].value == "it'\''s"'
}
