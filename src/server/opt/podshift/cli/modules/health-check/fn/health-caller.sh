#!/usr/bin/env bash
# @file: health-caller.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @description: Tells who is running the health check.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_D6BD04203098:-}" ]]; then
    DIR_D6BD04203098="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_D6BD04203098
fi

# @description: Prints who is running the health check.
# @stdout: root, podshift, or other.
# @exitcode: 0 always.
health-caller() {
    # shellcheck source=../../../../fn/utils/is-podshift.sh
    declare -F is-podshift >/dev/null || source "${DIR_D6BD04203098}/../../../../fn/utils/is-podshift.sh"
    if [[ "${EUID}" -eq 0 ]]; then
        echo "root"
    elif is-podshift; then
        echo "podshift"
    else
        echo "other"
    fi
    return 0
}
