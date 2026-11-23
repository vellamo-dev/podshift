#!/usr/bin/env bash
# @file: cockpit-networks-list-quadlet-dir.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/networks-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/networks-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_25D4D035E67B:-}" ]]; then
    DIR_25D4D035E67B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_25D4D035E67B
fi

# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @stdout: the directory path, or nothing when it is not known.
# @exitcode: 0 always.
cockpit-networks-list-quadlet-dir() {
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_25D4D035E67B}/../../../../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main
    fi
    if [[ -n "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        printf '%s\n' "${PODSHIFT_PODMAN_QUADLETS_DIR}"
    fi
}
