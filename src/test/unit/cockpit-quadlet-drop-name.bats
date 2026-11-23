#!/usr/bin/env bats
# Unit test for cockpit-quadlet-drop-name (src/server/opt/podshift/cockpit/api/fn/drop/cockpit-quadlet-drop-name.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/drop/cockpit-quadlet-drop-name.sh"
    EXT=".container,.volume,.network,.image"
}

@test "accepted Quadlet files and a zip pass" {
    local n
    for n in web.container data.volume app-net.network base.image shop_api.zip v1.2.container; do
        run cockpit-quadlet-drop-name "${n}" "${EXT}"
        [ "${status}" -eq 0 ]
        [ -z "${output}" ]
    done
}

@test "a folder part is refused" {
    run cockpit-quadlet-drop-name "../web.container" "${EXT}"
    [ "${status}" -eq 1 ]
    [ "${output%%$'\t'*}" = "INVALID_NAME" ]
    run cockpit-quadlet-drop-name 'a\web.container' "${EXT}"
    [ "${output%%$'\t'*}" = "INVALID_NAME" ]
    run cockpit-quadlet-drop-name "" "${EXT}"
    [ "${output%%$'\t'*}" = "INVALID_NAME" ]
}

@test "a hidden name is refused" {
    run cockpit-quadlet-drop-name ".web.container" "${EXT}"
    [ "${status}" -eq 1 ]
    [ "${output}" = $'INVALID_NAME\tHidden files are not accepted.' ]
}

@test "other extensions are refused with the accepted list" {
    local n
    for n in web.pod web.kube notes.txt web README web.container.1761612345; do
        run cockpit-quadlet-drop-name "${n}" "${EXT}"
        [ "${status}" -eq 1 ]
        [ "${output}" = $'UNSUPPORTED_TYPE\tOnly .container, .volume, .network, .image and .zip files are accepted.' ]
    done
}

@test "a bad stem is refused" {
    local n
    for n in "-web.container" "_web.volume" "my web.container" "web.container.zip" 'we$b.image' $'we\x01b.container' $'w\u00e9b.container'; do
        run cockpit-quadlet-drop-name "${n}" "${EXT}"
        [ "${status}" -eq 1 ]
        [ "${output%%$'\t'*}" = "INVALID_NAME" ]
    done
}

@test "the extension list comes from the argument" {
    run cockpit-quadlet-drop-name "web.container" ".volume"
    [ "${status}" -eq 1 ]
    [ "${output}" = $'UNSUPPORTED_TYPE\tOnly .volume and .zip files are accepted.' ]
    run cockpit-quadlet-drop-name "shop.zip" ""
    [ "${status}" -eq 0 ]
}
