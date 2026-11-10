#!/usr/bin/env bash
# @file: is-install-type-desktop.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Detects whether PodShift is installed as a desktop install (the desktop flag file exists).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_312C2A3B7636:-}" ]]; then
    DIR_312C2A3B7636="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_312C2A3B7636
fi

# @description: Returns 0 if the desktop flag file (PODSHIFT_DESKTOP_FLAG) exists, so the install type is desktop.
# @exitcode: 0 if desktop, 1 otherwise (server).
is-install-type-desktop() {
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_312C2A3B7636}/../load-podshift-conf-main.sh"
    load-podshift-conf-main
    [[ -n "${PODSHIFT_DESKTOP_FLAG:-}" && -e "${PODSHIFT_DESKTOP_FLAG}" ]]
}
