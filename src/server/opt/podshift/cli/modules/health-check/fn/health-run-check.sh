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
# @details:
#   The check gets 10 seconds. In the podshift session the transient unit has its own name, so on a
#   timeout that unit is stopped too; otherwise the check could keep running as a stray user unit.
# @arg: $1 - route: direct (as the caller) or podshift-session (inside the podshift user's session).
# @arg: $2 - path to the check script.
# @stdout: the check's output line.
# @exitcode: the check's exit code; 124 on timeout.
health-run-check() {
    local route script unit rc
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
            # $$ is set on Bash 3.2, BASHPID is not.
            unit="podshift-health-$$-${RANDOM}"
            "${limit[@]}" systemd-run --unit="${unit}" --machine=podshift@.host --user --wait --pipe --quiet --collect \
                bash "${script}" 2>/dev/null </dev/null && rc=0 || rc=$?
            if [[ "${rc}" -eq 124 ]]; then
                # timeout stopped only the systemd-run client; stop the unit as well.
                timeout 2 systemctl --machine=podshift@.host --user stop "${unit}.service" >/dev/null 2>&1 || true
            fi
            return "${rc}"
            ;;
    esac
}
