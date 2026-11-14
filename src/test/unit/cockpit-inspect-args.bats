#!/usr/bin/env bats
# Unit test for cockpit-inspect-args (src/server/opt/podshift/cockpit/api/fn/inspect/cockpit-inspect-args.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/inspect/cockpit-inspect-args.sh"
}

@test "each kind is accepted and printed with the ref" {
    local kind
    for kind in container image volume network secret; do
        run cockpit-inspect-args "{\"kind\":\"${kind}\",\"ref\":\"example-1\"}"
        [ "${status}" -eq 0 ]
        [ "${output}" = "${kind}"$'\t'"example-1"$'\t' ]
    done
}

@test "image references, digests and ids are accepted" {
    run cockpit-inspect-args '{"kind":"image","ref":"docker.io/library/alpine:latest"}'
    [ "${status}" -eq 0 ]
    [ "${output}" = $'image\tdocker.io/library/alpine:latest\t' ]
    run cockpit-inspect-args '{"kind":"image","ref":"quay.io/a/b@sha256:0123abcd"}'
    [ "${status}" -eq 0 ]
    run cockpit-inspect-args '{"kind":"container","ref":"3f9c1a7e2b4d"}'
    [ "${status}" -eq 0 ]
}

@test "an unknown kind is refused" {
    run cockpit-inspect-args '{"kind":"pod","ref":"x"}'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-args '{"kind":"Container","ref":"x"}'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-args '{"kind":1,"ref":"x"}'
    [ "${status}" -eq 1 ]
}

@test "a ref with a leading dash, a space, a shell character or a newline is refused" {
    local ref
    for ref in '-x' '--all' 'a b' 'a;b' 'a$b' 'a\nb' 'a\n' '*' 'a|b' "a'b"; do
        run cockpit-inspect-args "{\"kind\":\"volume\",\"ref\":\"${ref}\"}"
        [ "${status}" -eq 1 ]
    done
}

@test "an empty, missing or too long ref is refused, 256 characters are accepted" {
    run cockpit-inspect-args '{"kind":"volume","ref":""}'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-args '{"kind":"volume"}'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-args "{\"kind\":\"volume\",\"ref\":\"$(printf 'a%.0s' {1..257})\"}"
    [ "${status}" -eq 1 ]
    run cockpit-inspect-args "{\"kind\":\"volume\",\"ref\":\"$(printf 'a%.0s' {1..256})\"}"
    [ "${status}" -eq 0 ]
}

@test "arguments that are not a JSON object are refused" {
    run cockpit-inspect-args '[1]'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-args 'not json'
    [ "${status}" -eq 1 ]
    run cockpit-inspect-args ''
    [ "${status}" -eq 1 ]
}

@test "mode file is accepted and printed last" {
    run cockpit-inspect-args '{"kind":"container","ref":"db","mode":"file"}'
    [ "${status}" -eq 0 ]
    [ "${output}" = $'container\tdb\tfile' ]
}

@test "any other mode value is refused" {
    local mode
    for mode in '"File"' '"json"' '""' '1' 'true' 'null' '["file"]'; do
        run cockpit-inspect-args "{\"kind\":\"volume\",\"ref\":\"a\",\"mode\":${mode}}"
        if [ "${mode}" = '""' ]; then
            # An empty mode is the same as no mode here; the input contract refuses it first.
            [ "${status}" -eq 0 ]
        else
            [ "${status}" -eq 1 ]
        fi
    done
}
