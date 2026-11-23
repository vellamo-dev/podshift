#!/usr/bin/env bash
# @file: 140-secrets.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: secrets-list: SecretData and env values never leak.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# secrets-list: podman is stubbed. A SecretData field and env values in the stub must never leak.
sec_calls="${WORK}/secrets.calls"
: > "${sec_calls}"
cockpit-secrets-list-podman() {
    printf '%s\n' "${*}" >> "${sec_calls}"
    case "${1-} ${2-}" in
        "secret ls")
            printf '%s\n' 3c8e1f0a9b7d6c5e4f3a2b1c0 7a1b2c3d4e5f60718293a4b5c 9f8e7d6c5b4a39281706f5e4d 3c8e1f0a9b7d6c5e4f3a2b1c0
            ;;
        "secret inspect")
            [[ "${*}" == "secret inspect -- 3c8e1f0a9b7d6c5e4f3a2b1c0 7a1b2c3d4e5f60718293a4b5c 9f8e7d6c5b4a39281706f5e4d" ]] || return 125
            printf '%s\n' '[
                {"ID":"3c8e1f0a9b7d6c5e4f3a2b1c0","CreatedAt":"2026-10-02T10:15:00.1+02:00","UpdatedAt":"2026-10-02T10:15:00.1+02:00","Spec":{"Name":"db-password","Driver":{"Name":"file","Options":{"path":"/x/filedriver"}},"Labels":{}},"SecretData":"must-never-leak"},
                {"ID":"7a1b2c3d4e5f60718293a4b5c","CreatedAt":"2026-10-18T14:22:00Z","UpdatedAt":"2026-11-01T09:30:00Z","Spec":{"Name":"api-token","Driver":{"Name":"file","Options":{}},"Labels":{}}},
                {"ID":"9f8e7d6c5b4a39281706f5e4d","CreatedAt":"2026-09-20T11:00:00Z","UpdatedAt":"2026-09-20T11:00:00Z","Spec":{"Name":"registry-auth","Driver":{"Name":"pass","Options":{}},"Labels":{}}}
            ]'
            ;;
        "ps -a")
            printf '%s\n' '[{"Id":"c1"},{"Id":"c2"},{"Id":"c1"}]'
            ;;
        "container inspect")
            printf '%s\n' '[
                {"Id":"c1","Name":"shop-db","State":{"Status":"running"},"Config":{"Env":["DB_PASSWORD=must-never-leak"],"CreateCommand":["podman","run","--secret","db-password,type=env,target=DB_PASSWORD","img"]}},
                {"Id":"c2","Name":"db-backup","State":{"Status":"exited"},"Config":{"CreateCommand":["podman","run","--secret=api-token,target=/etc/token","img"],"Secrets":[{"Name":"api-token","ID":"7a1b2c3d4e5f60718293a4b5c"}]}}
            ]'
            ;;
        *)
            return 1
            ;;
    esac
}
secrets_out="$(cockpit-module-secrets-list)"
secrets_contract="$(jq -c '.output' "${API}/modules/secrets-list/capability.json")"
if printf '%s' "${secrets_out}" | jq -e '
    ([.items[].title] == ["api-token","db-password","registry-auth"])
    and ([.items[] | {(.name): [.status, .inUse, .running]}] | add) == {
        "api-token":["In use",true,false],"db-password":["In use",true,true],"registry-auth":["Unused",false,false]}
    and ((.items[] | select(.name == "db-password") | .usedBy) == [
        {"container":"shop-db","containerId":"c1","state":"running","type":"env","target":"DB_PASSWORD"}])
    and ((.items[] | select(.name == "api-token") | .usedBy) == [
        {"container":"db-backup","containerId":"c2","state":"exited","type":"file","target":"/etc/token"}])
    and ((.items[] | select(.name == "db-password") | .rows) == [
        {"id":"driver","label":"Driver","value":"file"},
        {"id":"created","label":"Created","value":"2026-10-02T08:15:00Z"},
        {"id":"updated","label":"Updated","value":"2026-10-02T08:15:00Z"},
        {"id":"used-by","label":"Used by","value":"shop-db (env DB_PASSWORD)"}])
' >/dev/null && cockpit-validate-contract "${secrets_contract}" "${secrets_out}" \
    && [[ "${secrets_out}" != *must-never-leak* && "${secrets_out}" != *SecretData* && "${secrets_out}" != *filedriver* ]] \
    && ! grep -q -- '--showsecret' "${sec_calls}" && grep -qx 'secret ls --quiet --noheading' "${sec_calls}"; then
    ok "secrets-list-stubbed"
else
    bad "secrets-list-stubbed" "${secrets_out}"
fi

# The output contract refuses an item with an extra field such as SecretData.
if cockpit-validate-contract "${secrets_contract}" '{"items":[{"id":"a","title":"a","subtitle":"a","name":"a","driver":"file","created":"","updated":"","status":"Unused","inUse":false,"running":false,"usedBy":[],"rows":[],"SecretData":"x"}]}'; then
    bad "secrets-list-contract-refuses-secret-data" "accepted"
else
    ok "secrets-list-contract-refuses-secret-data"
fi

: > "${sec_calls}"
cockpit-secrets-list-podman() {
    printf '%s\n' "${*}" >> "${sec_calls}"
    case "${1-} ${2-}" in
        "secret ls") printf '' ;;
        *) return 1 ;;
    esac
}
secrets_out="$(cockpit-module-secrets-list)"
[[ "${secrets_out}" == '{"items":[]}' ]] && ! grep -q '^ps' "${sec_calls}"
expect_status "secrets-list-empty" $? "${secrets_out}"

cockpit-secrets-list-podman() {
    case "${1-} ${2-}" in
        "secret ls") printf 'a1\n' ;;
        "secret inspect") printf '[{"ID":"a1","Spec":{"Name":"a","Driver":{"Name":"file"}}}]\n' ;;
        "ps -a") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
secrets_out="$(cockpit-module-secrets-list)"
printf '%s' "${secrets_out}" | jq -e '.items | length == 1 and .[0].status == "Unused" and .[0].usedBy == []' >/dev/null \
    && cockpit-validate-contract "${secrets_contract}" "${secrets_out}"
expect_status "secrets-list-no-containers" $? "${secrets_out}"

cockpit-secrets-list-podman() {
    case "${1-} ${2-}" in
        "secret ls") printf 'a1\n' ;;
        "secret inspect") printf '[{"ID":"a1","Spec":{"Name":"a","Driver":{"Name":"file"}}}]\n' ;;
        "ps -a") printf '[{"Id":"c1"}]\n' ;;
        *) return 1 ;;
    esac
}
logger() { :; }
# A failed container inspect no longer fails the list: the secret is shown as not used.
secrets_out="$(cockpit-module-secrets-list 2>/dev/null)" \
    && printf '%s' "${secrets_out}" | jq -e '.items[0].name == "a" and .items[0].status == "Unused"' >/dev/null
expect_status "secrets-list-inspect-fallback" $? "${secrets_out}"
unset -f logger

cockpit-secrets-list-podman() {
    return 1
}
if secrets_out="$(cockpit-module-secrets-list 2>/dev/null)"; then
    bad "secrets-list-podman-fails" "${secrets_out}"
else
    ok "secrets-list-podman-fails"
fi

cockpit-secrets-list-podman() {
    case "${1-} ${2-}" in
        "secret ls") printf 'a1\n' ;;
        *) return 1 ;;
    esac
}
if secrets_out="$(cockpit-module-secrets-list 2>/dev/null)"; then
    bad "secrets-list-secret-inspect-fails" "${secrets_out}"
else
    ok "secrets-list-secret-inspect-fails"
fi

