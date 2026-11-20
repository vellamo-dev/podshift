#!/usr/bin/env bash
# @file: 404-env-tag.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/400-config
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/400-config
# @host-edit: no
# @group: health-check
# @category: check
# @title: Environment tag
# @run-as: podshift
# @description: Verifies the environment tag is set; a missing one is a warning.
# @rationale: Without it, it is unclear which environment this server is for.
# @fix: sudo podshift env --set <env>
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_6C28E0B4A917:-}" ]]; then
    DIR_6C28E0B4A917="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_6C28E0B4A917
fi

# @description: Runs the env-tag check.
# @stdout: one TSV line: env-tag<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 3 = INFO.

health-check-env-tag() {
    # shellcheck source=../../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_6C28E0B4A917}/../../../../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    # shellcheck source=../../../../../fn/load-podshift-conf-runtime.sh
    declare -F load-podshift-conf-runtime >/dev/null || source "${DIR_6C28E0B4A917}/../../../../../fn/load-podshift-conf-runtime.sh"
    load-podshift-conf-runtime
    if [[ -n "${TSV_ENV:-}" ]]; then
        printf 'env-tag\tOK\t%s\n' "${TSV_ENV}"
        return 0
    fi
    printf 'env-tag\tWARN\tnot set\n'
    return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    health-check-env-tag
fi
