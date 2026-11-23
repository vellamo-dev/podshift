#!/usr/bin/env bash
# @file: cockpit-secrets-list-secrets.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/secrets-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/secrets-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints podman secret inspect JSON for every secret of the current (podshift) user, without secret values.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_D32F228EA1FA:-}" ]]; then
    DIR_D32F228EA1FA="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_D32F228EA1FA
fi

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
    # shellcheck source=./cockpit-secrets-list-podman.sh
    declare -F cockpit-secrets-list-podman >/dev/null || source "${DIR_D32F228EA1FA}/cockpit-secrets-list-podman.sh"
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
