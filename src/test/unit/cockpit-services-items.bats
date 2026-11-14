#!/usr/bin/env bats
# Unit test for cockpit-services-items (src/server/opt/podshift/cockpit/api/fn/services/cockpit-services-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/services/cockpit-services-items.sh"
    SHOW="${BATS_TEST_DIRNAME}/fixtures/cockpit-services/show.txt"
}

@test "loaded services only, sorted by unit name" {
    run cockpit-services-items < "${SHOW}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.items[].id] == ["example-app.service","example-quadlet-container.service","example-quadlet-network.service","example-unit-network.service","podman-auto-update.service"]
    '
}

@test "a running Quadlet container has its source, file, PID, memory and time" {
    run cockpit-services-items < "${SHOW}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.id == "example-quadlet-container.service")) == {
            "id": "example-quadlet-container.service",
            "title": "example-quadlet-container.service",
            "subtitle": "PodShift example Quadlet container with auto-update",
            "source": "quadlet",
            "activeState": "active",
            "subState": "running",
            "since": "2026-11-12T09:02:14Z",
            "unitFileState": "generated",
            "path": "/run/user/300/systemd/generator/example-quadlet-container.service",
            "preset": "enabled",
            "quadletFile": "/home/podshift/.config/containers/systemd/example-quadlet-container.container",
            "quadletKind": "container",
            "mainPid": 2214,
            "memory": 1468006
        }
    '
}

@test "the Quadlet kind follows the source file extension" {
    run cockpit-services-items < "${SHOW}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.id): [.source, (.quadletKind // null)]}] | add) == {
            "example-app.service": ["quadlet","kube"],
            "example-quadlet-container.service": ["quadlet","container"],
            "example-quadlet-network.service": ["quadlet","network"],
            "example-unit-network.service": ["unit",null],
            "podman-auto-update.service": ["unit",null]
        }
    '
}

@test "a failed unit has its result; a text time in UTC is converted; unset memory and PID 0 are left out" {
    run cockpit-services-items < "${SHOW}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.id == "example-app.service"))
        | .result == "exit-code" and .since == "2026-11-12T11:47:31Z"
            and (has("memory") | not) and (has("mainPid") | not) and (has("preset") | not)
    '
}

@test "an inactive unit with a timer: triggeredBy, preset, empty since, no result" {
    run cockpit-services-items < "${SHOW}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.id == "podman-auto-update.service"))
        | .triggeredBy == "podman-auto-update.timer" and .preset == "disabled" and .since == ""
            and .unitFileState == "disabled" and (has("result") | not) and (has("memory") | not)
    '
}

@test "an empty description falls back to the unit name, and empty input gives no items" {
    run cockpit-services-items <<< $'Id=x.service\nDescription=\nLoadState=loaded\nActiveState=inactive\nSubState=dead\n'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '.items[0].subtitle == "x.service" and .items[0].path == "" and .items[0].unitFileState == ""'
    run cockpit-services-items < /dev/null
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
}
