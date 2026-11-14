#!/usr/bin/env bats
# Unit test for cockpit-networks-items (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-networks-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-networks-items.sh"
    FIX="${BATS_TEST_DIRNAME}/fixtures/cockpit-networks"
    INSPECT="$(cat "${FIX}/inspect.json")"
    SOURCES="$(cat "${FIX}/sources.json")"
}

@test "items are sorted by name and have the card fields" {
    run cockpit-networks-items "${INSPECT}" "${SOURCES}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.items[].id] == ["example-unit","podman","systemd-legacy","tsv-nw1"]
        and all(.items[]; (keys | sort) == ["groups","id","rows","source","status","subtitle","title"])
        and .items[3].title == "tsv-nw1"
        and .items[3].subtitle == "3f1c2b8e9d0a"
    '
}

@test "rows: values are display text and empty values are left out" {
    run cockpit-networks-items "${INSPECT}" "${SOURCES}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.id == "tsv-nw1") | .rows) == [
            {"id":"driver","label":"Driver","value":"bridge"},
            {"id":"subnet","label":"Subnet","value":"10.89.0.0/24"},
            {"id":"gateway","label":"Gateway","value":"10.89.0.1"},
            {"id":"interface","label":"Interface","value":"podman1"},
            {"id":"ipv6","label":"IPv6","value":"Disabled"},
            {"id":"internal","label":"Internal","value":"No"},
            {"id":"dns","label":"DNS","value":"Enabled"}
        ]
        and ([.items[] | select(.id == "systemd-legacy") | .rows[].id] == ["driver","interface","ipv6","internal","dns"])
        and (.items[] | select(.id == "example-unit") | .rows[] | select(.id == "internal") | .value) == "Yes"
    '
}

@test "source: builtin wins, then the map, then the systemd label, else unmanaged" {
    run cockpit-networks-items "${INSPECT}" "${SOURCES}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.id): .source}] | add) == {
            "example-unit": "unit",
            "podman": "builtin",
            "systemd-legacy": "quadlet",
            "tsv-nw1": "quadlet"
        }
    '
    run cockpit-networks-items '[{"name":"loose","id":"x"}]' '{}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items[0].source == "unmanaged" and .items[0].groups == []'
}

@test "status is In use only with containers" {
    run cockpit-networks-items "${INSPECT}" "${SOURCES}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.id): .status}] | add) == {
            "example-unit": "Unused",
            "podman": "Unused",
            "systemd-legacy": "In use",
            "tsv-nw1": "In use"
        }
    '
}

@test "groups: systemd, containers and labels, empty ones left out" {
    run cockpit-networks-items "${INSPECT}" "${SOURCES}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.id == "tsv-nw1") | .groups) == [
            {"id":"systemd","label":"Systemd","rows":[
                {"id":"unit","label":"Unit name","value":"tsv-nw1-network.service"},
                {"id":"unit_state","label":"Unit state","value":"active"},
                {"id":"file","label":"File","value":"~/.config/containers/systemd/shop.qdl-bundle/tsv-nw1.network"},
                {"id":"app","label":"App","value":"shop"}
            ]},
            {"id":"containers","label":"Containers","rows":[
                {"id":"shop","label":"shop","value":"10.89.0.10"},
                {"id":"shop-redis","label":"shop-redis","value":"10.89.0.11"}
            ]},
            {"id":"labels","label":"Labels","rows":[
                {"id":"env","label":"env","value":"dev"},
                {"id":"podshift.app","label":"podshift.app","value":"shop"}
            ]}
        ]
        and ([.items[] | select(.id == "podman") | .groups[]] | length) == 0
        and ([.items[] | select(.id == "example-unit") | .groups[].id] == ["systemd","labels"])
    '
}

@test "a quadlet from the label gets its unit name, a container without IP says so" {
    run cockpit-networks-items "${INSPECT}" "${SOURCES}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.id == "systemd-legacy") | .groups) as $g
        | ($g[0].id == "systemd" and $g[0].rows == [{"id":"unit","label":"Unit name","value":"legacy-network.service"}])
        and ($g[1].rows == [{"id":"noip","label":"noip","value":"No IP"}])
    '
}

@test "an empty list gives no items, bad JSON fails" {
    run cockpit-networks-items '[]' '{}'
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
    run cockpit-networks-items '{}' '{}'
    [ "${status}" -ne 0 ]
    run cockpit-networks-items 'not json' '{}'
    [ "${status}" -ne 0 ]
}
