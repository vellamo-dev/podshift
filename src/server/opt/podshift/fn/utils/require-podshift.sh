#!/usr/bin/env bash
# @file: require-podshift.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Stops if the current user is not the dedicated podshift user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_D72988F37ECD:-}" ]]; then
    DIR_D72988F37ECD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_D72988F37ECD
fi

# @description: Returns 0 if podshift user; otherwise prints an error and returns 1.
# @exitcode: 0 if podshift user, 1 otherwise.
require-podshift() {
    # shellcheck source=./is-podshift.sh
    declare -F is-podshift >/dev/null || source "${DIR_D72988F37ECD}/is-podshift.sh"
    if ! is-podshift; then
        echo "Unauthorised. Must be the podshift user (root: sudo -u podshift -i)." >&2
        return 1
    fi
}
