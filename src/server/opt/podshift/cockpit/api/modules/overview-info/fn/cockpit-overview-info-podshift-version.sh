#!/usr/bin/env bash
# @file: cockpit-overview-info-podshift-version.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-info/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-info/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the installed PodShift version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_A980AA463F2D:-}" ]]; then
    DIR_A980AA463F2D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A980AA463F2D
fi

# @description: Prints the installed PodShift version.
# @stdout: a version string, or nothing when it cannot be read.
# @exitcode: 0 always.
cockpit-overview-info-podshift-version() {
    local version
    # shellcheck source=../../../../../fn/common/get-podshift-version.sh
    declare -F get-podshift-version >/dev/null || source "${DIR_A980AA463F2D}/../../../../../fn/common/get-podshift-version.sh"
    version="$(get-podshift-version 2>/dev/null || true)"
    [[ -n "${version}" ]] || return 0
    printf '%s\n' "${version}"
}
