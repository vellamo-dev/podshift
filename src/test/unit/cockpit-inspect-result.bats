#!/usr/bin/env bats
# Unit test for cockpit-inspect-result (src/server/opt/podshift/cockpit/api/fn/inspect/cockpit-inspect-result.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/inspect/cockpit-inspect-result.sh"
    FIX="${BATS_TEST_DIRNAME}/fixtures/cockpit-inspect"
}

@test "a container is returned as the first object, unchanged" {
    run cockpit-inspect-result container db "$(cat "${FIX}/container.json")" 131072
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e --argjson want "$(jq -c '.[0]' "${FIX}/container.json")" '
        .kind == "container" and .ref == "db" and .found == true and .object == $want
        and (.object.Config.Env | index("TZ=Europe/Helsinki")) != null
    '
}

@test "an image, a volume and a network keep their own top-level keys" {
    run cockpit-inspect-result image alpine "$(cat "${FIX}/image.json")" 131072
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.found == true and .object.RepoTags == ["docker.io/library/alpine:latest"]'
    run cockpit-inspect-result volume pgdata "$(cat "${FIX}/volume.json")" 131072
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.kind == "volume" and .object.Name == "pgdata" and .object.Driver == "local"'
    run cockpit-inspect-result network podman "$(cat "${FIX}/network.json")" 131072
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.kind == "network" and .object.name == "podman" and .object.subnets[0].subnet == "10.88.0.0/16"'
}

@test "an empty array means not found and has no object" {
    run cockpit-inspect-result volume missing '[]' 131072
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"kind":"volume","ref":"missing","found":false}' ]
}

@test "only the first of several objects is returned" {
    run cockpit-inspect-result volume a '[{"Name":"a"},{"Name":"b"}]' 131072
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.object == {"Name":"a"}'
}

@test "input that is not an array of objects fails" {
    run cockpit-inspect-result volume a '{"Name":"a"}' 131072
    [ "${status}" -eq 1 ]
    run cockpit-inspect-result volume a '[1]' 131072
    [ "${status}" -eq 1 ]
    run cockpit-inspect-result volume a 'Error: no such volume' 131072
    [ "${status}" -eq 1 ]
    run cockpit-inspect-result volume a '' 131072
    [ "${status}" -eq 1 ]
}

# Builds a podman inspect array whose compact result line for volume "a", newline included, is $1 bytes.
inspect_of_result_size() {
    local want base pad
    want="${1}"
    base="$(printf '%s\n' '{"kind":"volume","ref":"a","found":true,"object":{"Name":""}}' | wc -c | tr -d '[:space:]')"
    pad=$((want - base))
    jq -n -c --argjson n "${pad}" '[{Name: ("x" * $n)}]'
}

@test "a result of exactly 131072 bytes is returned in full" {
    run cockpit-inspect-result volume a "$(inspect_of_result_size 131072)" 131072
    [ "${status}" -eq 0 ]
    [ "$(printf '%s\n' "${output}" | wc -c | tr -d '[:space:]')" -eq 131072 ]
    printf '%s' "${output}" | jq -e '.found == true and (.object.Name | length) > 0 and has("tooLarge") == false'
}

@test "a result of 131073 bytes is too large and gives the pretty JSON size" {
    local raw want
    raw="$(inspect_of_result_size 131073)"
    want="$(printf '%s' "${raw}" | jq --indent 4 '.[0]' | wc -c | tr -d '[:space:]')"
    run cockpit-inspect-result volume a "${raw}" 131072
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e --argjson want "${want}" '
        . == {kind: "volume", ref: "a", found: true, tooLarge: true, size: $want}
    '
}

@test "a missing or non-numeric limit fails" {
    run cockpit-inspect-result volume a '[{"Name":"a"}]'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-result volume a '[{"Name":"a"}]' 12k
    [ "${status}" -eq 1 ]
}
