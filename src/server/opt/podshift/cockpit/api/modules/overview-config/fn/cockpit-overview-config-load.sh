#!/usr/bin/env bash
# @file: cockpit-overview-config-load.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-config/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-config/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Loads TSV_ENV from the runtime config and derives TSV_NW1 to TSV_NW8.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_C9969C55723F:-}" ]]; then
    DIR_C9969C55723F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C9969C55723F
fi

# @description: Loads TSV_ENV from the runtime config and derives TSV_NW1 to TSV_NW8.
# @details:
#   Reuses the existing loaders. A failure leaves the variables unset so the row value is null.
# @exitcode: 0 always.
cockpit-overview-config-load() {
    # shellcheck source=../../../../../fn/load-podshift-conf-runtime.sh
    declare -F load-podshift-conf-runtime >/dev/null || source "${DIR_C9969C55723F}/../../../../../fn/load-podshift-conf-runtime.sh"
    load-podshift-conf-runtime >/dev/null 2>&1 || true
    # Prefer a tree-relative loader when this is a source checkout; fall back to the install path.
    if ! declare -F load-podshift-conf-nw >/dev/null; then
        if [[ -f "${DIR_C9969C55723F}/../../../../../fn/load-podshift-conf-nw.sh" ]]; then
            # shellcheck source=../../../../../fn/load-podshift-conf-nw.sh
            source "${DIR_C9969C55723F}/../../../../../fn/load-podshift-conf-nw.sh"
        elif [[ -f /opt/podshift/fn/load-podshift-conf-nw.sh ]]; then
            # shellcheck source=../../../../../fn/load-podshift-conf-nw.sh
            source /opt/podshift/fn/load-podshift-conf-nw.sh
        fi
    fi
    if declare -F load-podshift-conf-nw >/dev/null; then
        load-podshift-conf-nw >/dev/null 2>&1 || true
    fi
}
