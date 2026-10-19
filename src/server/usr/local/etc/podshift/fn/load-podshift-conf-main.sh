#!/usr/bin/env bash
# @file: load-podshift-conf-main.sh
# @dir: /usr/local/etc/podshift/fn
# @group: config
# @description: Loads (sources and exports) the PodShift main configuration.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Loads (sources and exports) the PodShift main configuration.
# @exitcode: 0 always (silent skip if main.conf is missing).
load-podshift-conf-main() {
    local path_cnf_file
    # Intentionally hardcoded: main.conf always lives at the fixed installation path,
    # regardless of where this script is sourced from.
    # shellcheck source=../conf/main.conf
    path_cnf_file="/usr/local/etc/podshift/conf/main.conf"
    if [ -f "${path_cnf_file}" ]; then
        set -a
        # shellcheck source=../conf/main.conf
        source "${path_cnf_file}"
        set +a
    fi
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && load-podshift-conf-main
fi