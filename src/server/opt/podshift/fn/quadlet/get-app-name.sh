#!/usr/bin/env bash
# @file: get-app-name.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Gives the application name of a bundle folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_B7E2D40F6A19:-}" ]]; then
    DIR_B7E2D40F6A19="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_B7E2D40F6A19
fi

# @description: Turns a bundle folder name into its application name.
# @details:
#   Takes the original name of the item (the collision suffix removed) and removes the .qdl-bundle
#   ending. The folder name in source is the zip name plus .qdl-bundle, so the result is the zip
#   name. This is the only place that turns a bundle folder into an application name.
# @arg: $1 - bundle folder name, or path.
# @stdout: the application name.
# @exitcode: 0 always.
get-app-name() {
    local name
    # shellcheck source=./get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_B7E2D40F6A19}/get-original-name.sh"
    name="$(get-original-name "${1-}")"
    printf '%s\n' "${name%.qdl-bundle}"
    return 0
}
