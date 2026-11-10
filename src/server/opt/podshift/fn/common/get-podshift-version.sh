#!/usr/bin/env bash
# @file: get-podshift-version.sh
# @source-dir: src/server/opt/podshift/fn/common
# @dest-dir: /opt/podshift/fn/common
# @host-edit: no
# @group: common
# @category: helper
# @description: Prints the installed PodShift version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_B1E5A9C2D7F3:-}" ]]; then
    DIR_B1E5A9C2D7F3="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_B1E5A9C2D7F3
fi

# @description: Prints the PodShift version, or 0.0.0-local-dev for development code.
# @stdout: the version string.
# @exitcode: 0 always.
get-podshift-version() {
    # shellcheck source=../utils/is-podshift-rpm-install.sh
    declare -F is-podshift-rpm-install >/dev/null || source "${DIR_B1E5A9C2D7F3}/../utils/is-podshift-rpm-install.sh"
    if is-podshift-rpm-install; then
        printf '%s\n' "$(rpm -q podshift --qf '%{VERSION}' 2>/dev/null)"
    else
        printf '0.0.0-local-dev\n'
    fi
    return 0
}
