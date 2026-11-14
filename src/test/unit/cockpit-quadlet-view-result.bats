#!/usr/bin/env bats
# Unit test for cockpit-quadlet-view-result (src/server/opt/podshift/cockpit/api/fn/quadlets/cockpit-quadlet-view-result.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/quadlets/cockpit-quadlet-view-result.sh"
    QFILE=/home/podshift/.config/containers/systemd/web.container
}

@test "ok: name, path, kind and the text as is, trailing newline included" {
    run cockpit-quadlet-view-result web.service ok "${QFILE}" container 131072 <<< $'[Container]\nImage=nginx'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e --arg path "${QFILE}" '. == {"unit":"web.service","found":true,"quadlet":true,"name":"web.container","path":$path,"kind":"container","text":"[Container]\nImage=nginx\n"}'
}

@test "missing: found false and stdin is not read" {
    run cockpit-quadlet-view-result web.service missing "" "" 131072 < /dev/null
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"unit":"web.service","found":false}' ]
}

@test "NOT_QUADLET: quadlet false and no path" {
    run cockpit-quadlet-view-result web.service NOT_QUADLET "" "" 131072 < /dev/null
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"unit":"web.service","found":true,"quadlet":false,"error":"NOT_QUADLET"}' ]
}

@test "file errors keep name, path and kind but no text" {
    for state in FILE_NOT_FOUND OUTSIDE_QUADLET_DIR FILE_UNREADABLE; do
        run cockpit-quadlet-view-result web.service "${state}" "${QFILE}" container 131072 < /dev/null
        [ "${status}" -eq 0 ]
        printf '%s' "${output}" | jq -e --arg state "${state}" '.error == $state and .quadlet == true and .name == "web.container" and .kind == "container" and (has("text") | not)'
    done
}

@test "too large: tooLarge and the text size instead of the text" {
    run cockpit-quadlet-view-result web.service ok "${QFILE}" container 120 <<< "$(printf 'x%.0s' {1..100})"
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"unit":"web.service","found":true,"quadlet":true,"name":"web.container","path":"/home/podshift/.config/containers/systemd/web.container","kind":"container","tooLarge":true,"size":101}' ]
}

@test "missing arguments, an unknown state or a bad limit are refused" {
    run cockpit-quadlet-view-result "" missing "" "" 10 < /dev/null
    [ "${status}" -eq 1 ]
    run cockpit-quadlet-view-result web.service other "${QFILE}" container 10 < /dev/null
    [ "${status}" -eq 1 ]
    run cockpit-quadlet-view-result web.service ok "" container 10 < /dev/null
    [ "${status}" -eq 1 ]
    run cockpit-quadlet-view-result web.service missing "" "" ten < /dev/null
    [ "${status}" -eq 1 ]
}
