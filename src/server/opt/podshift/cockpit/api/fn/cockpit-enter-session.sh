#!/usr/bin/env bash
# @file: cockpit-enter-session.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Thin handoff that starts the podshift@.host session tunnel and launches the internal session script inside it.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_C7AAABD3EB81:-}" ]]; then
    DIR_C7AAABD3EB81="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C7AAABD3EB81
fi

# @description: Runs cockpit-run-in-session.sh in the podshift user session through systemd-run.
# @details:
#   systemd-run gets anonymous pipes for stdout and stderr, which cat copies on, because
#   systemd-run --pipe fails with "Bad message" on a named FIFO or a regular file. The session
#   script is executed, not sourced. The first stdout byte is a fixed marker written only after the
#   session command has started, so a missing marker means the session was not entered. The unit
#   name is written to the given file before systemd-run so a timeout can stop that unit.
# @arg: $1 - action name already accepted by the dispatch map.
# @arg: $2 - path of a file that receives the transient unit name.
# @stdout: the session marker and then the session script stdout.
# @stderr: systemd-run diagnostics when the tunnel cannot start.
# @exitcode: the session script exit code when the tunnel starts, or the systemd-run exit code when it does not.
cockpit-enter-session() {
    local action unit_file unit script rc
    action="${1:-}"
    unit_file="${2:-}"
    [[ -n "${unit_file}" ]] || return 1
    # $$ is set on Bash 3.2. BASHPID is not, and set -u would stop the handler.
    unit="podshift-api-$$-${RANDOM}"
    script="${DIR_C7AAABD3EB81}/cockpit-run-in-session.sh"
    printf '%s\n' "${unit}" > "${unit_file}" || return 1
    systemd-run \
        --unit="${unit}" \
        --machine=podshift@.host \
        --user \
        --wait \
        --pipe \
        --quiet \
        --collect \
        bash -c 'printf "\034"; exec bash "$1" "$2"' _ "${script}" "${action}" \
        2> >(cat >&2) \
        | cat
    rc="${PIPESTATUS[0]}"
    return "${rc}"
}
