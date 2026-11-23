#!/usr/bin/env bash
# @file: cockpit-overview-config-tsv-text.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-config/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-config/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the text of the podshift user's tsv.conf, if it can be read.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_5CD1612D967C:-}" ]]; then
    DIR_5CD1612D967C="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_5CD1612D967C
fi

# @description: Prints the text of the podshift user's tsv.conf, if it can be read.
# @details:
#   Uses PODSHIFT_TSV_CONF from the main configuration, usually
#   /home/podshift/.config/podshift/tsv.conf. A missing, unreadable or symlink file
#   prints nothing so only the built-in rows are shown.
# @stdout: the file text, or nothing.
# @exitcode: 0 always.
cockpit-overview-config-tsv-text() {
    local file
    if [[ -z "${PODSHIFT_TSV_CONF:-}" ]]; then
        # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_5CD1612D967C}/../../../../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main
    fi
    file="${PODSHIFT_TSV_CONF:-}"
    if [[ -n "${file}" && -f "${file}" && -r "${file}" && ! -L "${file}" ]]; then
        cat -- "${file}" 2>/dev/null || true
    fi
}
