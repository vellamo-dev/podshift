#!/usr/bin/env bash
# @file: container-stop-if-running.sh
# @source-dir: src/test/cli/shared/fn/container
# @group: test
# @category: helper
# @description: Stops a test container if it is running, without removing it.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Stops the container if it is running and logs it. A container that is not running is left as it is.
# @arg: $1 - the run folder.
# @arg: $2 - the log name, for example build-container-stop.
# @arg: $3 - the container name.
# @stdout: NOTE stopped or not running, or the problem.
# @exitcode: 0 if it is not running anymore, 1 otherwise.
container-stop-if-running() {
    local run_dir name cnt
    run_dir="${1}"
    name="${2}"
    cnt="${3}"
    if ! container-running "${cnt}"; then
        echo "NOTE: not running"
        return 0
    fi
    container-cli stop "${cnt}" || { echo "The container ${cnt} could not be stopped"; return 1; }
    write-log "${run_dir}" "${name}" "Container ${cnt}: stopped"
    echo "NOTE: stopped"
}
