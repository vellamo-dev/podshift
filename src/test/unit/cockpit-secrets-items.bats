#!/usr/bin/env bats
# Unit test for cockpit-secrets-items (src/server/opt/podshift/cockpit/api/fn/resources/cockpit-secrets-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/resources/cockpit-secrets-items.sh"
    FIX="${BATS_TEST_DIRNAME}/fixtures/cockpit-secrets"
    SECRETS="$(cat "${FIX}/secrets.json")"
    CONTAINERS="$(cat "${FIX}/containers.json")"
}

@test "items are sorted by title and have the card fields" {
    run cockpit-secrets-items "${SECRETS}" "${CONTAINERS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.items[].title] == ["api-token","db-password","registry-auth","smtp-password"]
        and all(.items[]; (keys | sort) == ["created","driver","id","inUse","name","rows","running","status","subtitle","title","updated","usedBy"])
        and (.items[] | select(.name == "db-password") | [.id, .subtitle, .driver, .created, .updated])
            == ["3c8e1f0a9b7d6c5e4f3a2b1c0","3c8e1f0a9b7d","file","2026-10-02T08:15:00Z","2026-10-02T08:15:00Z"]
    '
}

@test "no secret value, SecretData, env value or driver option reaches the output" {
    run cockpit-secrets-items "${SECRETS}" "${CONTAINERS}"
    [ "${status}" -eq 0 ]
    [[ "${output}" != *must-never-leak* ]]
    [[ "${output}" != *SecretData* ]]
    [[ "${output}" != *password-store* ]]
    [[ "${output}" != *filedriver* ]]
}

@test "rows: driver, created, updated and used by" {
    run cockpit-secrets-items "${SECRETS}" "${CONTAINERS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.name == "api-token") | .rows) == [
            {"id":"driver","label":"Driver","value":"file"},
            {"id":"created","label":"Created","value":"2026-10-18T14:22:00Z"},
            {"id":"updated","label":"Updated","value":"2026-11-01T09:30:00Z"},
            {"id":"used-by","label":"Used by","value":"shop-db (file at /etc/shop/token)"}
        ]
        and (.items[] | select(.name == "db-password") | .rows[3].value)
            == "db-backup (file at /run/secrets/db-password), shop-db (env DB_PASSWORD)"
        and (.items[] | select(.name == "registry-auth") | .rows[3].value) == "Unused"
    '
}

@test "usedBy: env target, file target, default targets and Config.Secrets without a --secret option" {
    run cockpit-secrets-items "${SECRETS}" "${CONTAINERS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.name): [.usedBy[] | [.container, .type, .target]]}] | add) == {
            "api-token": [["shop-db","file","/etc/shop/token"]],
            "db-password": [["db-backup","file","/run/secrets/db-password"],["shop-db","env","DB_PASSWORD"]],
            "registry-auth": [],
            "smtp-password": [["mailer","file","/run/secrets/smtp-password"],["web","env","smtp-password"]]
        }
        and (.items[] | select(.name == "api-token") | .usedBy[0].containerId)
            == "a1a1a1a1a1a1b2b2b2b2b2b2c3c3c3c3c3c3d4d4d4d4d4d4e5e5e5e5e5e5f6f6"
    '
}

@test "a stopped container counts as in use; running follows running containers" {
    run cockpit-secrets-items "${SECRETS}" "${CONTAINERS}"
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        ([.items[] | {(.name): [.status, .inUse, .running]}] | add) == {
            "api-token": ["In use", true, true],
            "db-password": ["In use", true, true],
            "registry-auth": ["Unused", false, false],
            "smtp-password": ["In use", true, true]
        }
    '
    run cockpit-secrets-items "${SECRETS}" '[{"Id":"x1","Name":"old","State":{"Status":"exited"},"Config":{"CreateCommand":["podman","run","--secret=registry-auth,type=env,target=AUTH","img"]}}]'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        (.items[] | select(.name == "registry-auth") | [.status, .inUse, .running, .usedBy])
            == ["In use", true, false, [{"container":"old","containerId":"x1","state":"exited","type":"env","target":"AUTH"}]]
    '
}

@test "a reference by secret ID matches, a relative target goes under /run/secrets" {
    run cockpit-secrets-items '[{"ID":"abc123","Spec":{"Name":"k","Driver":{"Name":"file"}}}]' \
        '[{"Id":"c1","Name":"/app","State":"running","Config":{"CreateCommand":["podman","run","--secret","abc123,target=key.pem","img"]}}]'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .items[0].usedBy == [{"container":"app","containerId":"c1","state":"running","type":"file","target":"/run/secrets/key.pem"}]
        and .items[0].created == "" and ([.items[0].rows[].id] == ["driver","used-by"])
    '
}

@test "empty input gives no items" {
    run cockpit-secrets-items '[]' ''
    [ "${status}" -eq 0 ]
    [ "${output}" = '{"items":[]}' ]
}

@test "arguments that are not the expected JSON return 1" {
    run cockpit-secrets-items 'not json' '[]'
    [ "${status}" -eq 1 ]
    run cockpit-secrets-items '{}' '[]'
    [ "${status}" -eq 1 ]
    run cockpit-secrets-items '[]' '{}'
    [ "${status}" -eq 1 ]
}
