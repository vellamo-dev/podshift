#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/secrets-list
# @dest-dir: /opt/podshift/cockpit/api/modules/secrets-list
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Secrets list module: lists the podshift user's Podman secrets as resource cards, never their values.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_7D3E91C2A5F4:-}" ]]; then
    DIR_7D3E91C2A5F4="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7D3E91C2A5F4
fi

# shellcheck source=../../fn/resources/cockpit-secrets-items.sh
declare -F cockpit-secrets-items >/dev/null || source "${DIR_7D3E91C2A5F4}/../../fn/resources/cockpit-secrets-items.sh"

# @description: Runs podman in the current (podshift) session.
# @arg: $@ - podman arguments.
# @stdout: podman stdout.
# @exitcode: the podman exit code, or 1 when podman is missing.
cockpit-secrets-list-podman() {
    podman "$@"
}

# @description: Prints podman secret inspect JSON for every secret of the current (podshift) user, without secret values.
# @details:
#   IDs come from podman secret ls --quiet (podman secret ls has no JSON format: --format json
#   is a Go template that prints the word json), then one podman secret inspect reads them all.
#   --showsecret is never used, so podman prints no SecretData. Only ID, CreatedAt, UpdatedAt,
#   Spec.Name and Spec.Driver.Name are kept, so driver options and any SecretData are dropped.
#   With no secrets the output is [].
# @stdout: one JSON array.
# @exitcode: 0 when the array was written, 1 when podman or jq fails.
cockpit-secrets-list-secrets() {
    local raw ins
    local -a ids
    raw="$(cockpit-secrets-list-podman secret ls --quiet --noheading 2>/dev/null)" || return 1
    mapfile -t ids < <(printf '%s\n' "${raw}" | grep -E '^[A-Za-z0-9]+$' | LC_ALL=C sort -u)
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    ins="$(cockpit-secrets-list-podman secret inspect -- "${ids[@]}" 2>/dev/null)" || return 1
    [[ -n "${ins}" ]] || ins='[]'
    printf '%s' "${ins}" | jq -c 'if type != "array" then error("not an array") else . end
        | [.[] | objects | {ID, CreatedAt, UpdatedAt, Spec: {Name: (.Spec.Name? // null), Driver: {Name: (.Spec.Driver.Name? // null)}}}]' 2>/dev/null
}

# @description: Prints the secret references of every container, stopped ones included.
# @details:
#   IDs come from podman ps -a --format json, then one podman container inspect reads them all.
#   Only Id, Name, State, Config.CreateCommand and Config.Secrets are kept, so Config.Env (which
#   older podman versions print with env secret values) is dropped right away.
# @stdout: one JSON array, [] when there are no containers.
# @exitcode: 0 when the array was written, 1 when podman or jq fails.
cockpit-secrets-list-containers() {
    local raw ins
    local -a ids
    raw="$(cockpit-secrets-list-podman ps -a --format json 2>/dev/null)" || return 1
    [[ -n "${raw}" ]] || raw='[]'
    mapfile -t ids < <(printf '%s' "${raw}" | jq -r '[.[]? | (.Id // .ID // empty)] | unique | .[]')
    if [[ "${#ids[@]}" -eq 0 ]]; then
        printf '[]\n'
        return 0
    fi
    ins="$(cockpit-secrets-list-podman container inspect -- "${ids[@]}" 2>/dev/null)" || return 1
    [[ -n "${ins}" ]] || ins='[]'
    printf '%s' "${ins}" | jq -c '[.[]? | objects | {Id, Name, State,
        Config: {CreateCommand: (.Config.CreateCommand? // null), Secrets: (.Config.Secrets? // null)}}]' 2>/dev/null
}

# @description: Lists the podshift user's Podman secrets as resource cards, with the containers that use them.
# @details:
#   Reads podman secret ls and podman secret inspect, and only when there is a secret, podman ps -a and podman container
#   inspect. The items are built by cockpit-secrets-items and never hold a secret value. The
#   process runs in the podshift session, so podman already talks to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-secrets-list() {
    local secrets ctrs
    secrets="$(cockpit-secrets-list-secrets)" || return 1
    if [[ "$(printf '%s' "${secrets}" | jq -r 'if type == "array" then length else -1 end' 2>/dev/null)" == "0" ]]; then
        printf '{"items":[]}\n'
        return 0
    fi
    ctrs="$(cockpit-secrets-list-containers)" || return 1
    cockpit-secrets-items "${secrets}" "${ctrs}"
}
