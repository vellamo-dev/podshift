#!/usr/bin/env bash
# @file: load-rootless-conf.sh
# @source-dir: src/server/opt/podshift/fn/rootless
# @dest-dir: /opt/podshift/fn/rootless
# @host-edit: no
# @group: rootless
# @category: helper
# @description: Loads and exports the rootless configuration, such as XDG_RUNTIME_DIR.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_705A91F29D6D:-}" ]]; then
    DIR_705A91F29D6D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_705A91F29D6D
fi

# @description: Sources the rootless configuration file and exports its values.
# @stderr: an error when PODSHIFT_ROOTLESS_CONF is not defined.
# @exitcode: 0 if loaded or the file is missing, 1 if PODSHIFT_ROOTLESS_CONF is not defined.
load-rootless-conf() {
    local path_rootless_cnf_file
    # Load main config first to resolve PODSHIFT_ROOTLESS_CONF
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_705A91F29D6D}/../load-podshift-conf-main.sh"
    load-podshift-conf-main
    if [ -z "${PODSHIFT_ROOTLESS_CONF:-}" ]; then
        echo "Error: PODSHIFT_ROOTLESS_CONF is not defined." >&2
        return 1
    fi
    path_rootless_cnf_file="${PODSHIFT_ROOTLESS_CONF}"
    if [ -f "${path_rootless_cnf_file}" ]; then
        set -a
        # shellcheck source=../../conf/rootless.conf
        source "${path_rootless_cnf_file}"
        set +a
    fi
}
