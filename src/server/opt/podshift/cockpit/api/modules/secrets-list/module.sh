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

# @description: Lists the podshift user's Podman secrets as resource cards, with the containers that use them.
# @details:
#   Reads podman secret ls and podman secret inspect, and only when there is a secret, podman ps -a and podman container
#   inspect. The items are built by cockpit-secrets-items and never hold a secret value. The
#   process runs in the podshift session, so podman already talks to that user.
# @stdout: one JSON object with an items array.
# @exitcode: 0 when the items were written, 1 otherwise.
cockpit-module-secrets-list() {
    local secrets ctrs
    # shellcheck source=./fn/cockpit-secrets-list-secrets.sh
    declare -F cockpit-secrets-list-secrets >/dev/null || source "${DIR_7D3E91C2A5F4}/fn/cockpit-secrets-list-secrets.sh"
    # shellcheck source=./fn/cockpit-secrets-list-containers.sh
    declare -F cockpit-secrets-list-containers >/dev/null || source "${DIR_7D3E91C2A5F4}/fn/cockpit-secrets-list-containers.sh"
    # shellcheck source=../../fn/resources/cockpit-secrets-items.sh
    declare -F cockpit-secrets-items >/dev/null || source "${DIR_7D3E91C2A5F4}/../../fn/resources/cockpit-secrets-items.sh"
    secrets="$(cockpit-secrets-list-secrets)" || return 1
    if [[ "$(printf '%s' "${secrets}" | jq -r 'if type == "array" then length else -1 end' 2>/dev/null)" == "0" ]]; then
        printf '{"items":[]}\n'
        return 0
    fi
    ctrs="$(cockpit-secrets-list-containers)" || return 1
    cockpit-secrets-items "${secrets}" "${ctrs}"
}
