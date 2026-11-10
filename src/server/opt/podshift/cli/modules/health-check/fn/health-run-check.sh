#!/usr/bin/env bash
# @file: health-run-check.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @description: Runs one health check in its realm.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs one check in its realm, for that check only.
# @arg: $1 - route: direct (as the caller) or podshift-session (inside the podshift user's session).
# @arg: $2 - path to the check script.
# @stdout: the check's output line.
# @exitcode: the check's exit code; 124 on timeout.
health-run-check() {
    local route script
    local -a limit
    route="${1}"
    script="${2}"
    limit=()
    command -v timeout >/dev/null 2>&1 && limit=(timeout 10)
    case "${route}" in
        direct)
            "${limit[@]}" bash "${script}" 2>/dev/null </dev/null
            ;;
        podshift-session)
            "${limit[@]}" systemd-run --machine=podshift@.host --user --wait --pipe --quiet --collect \
                bash "${script}" 2>/dev/null </dev/null
            ;;
    esac
}
