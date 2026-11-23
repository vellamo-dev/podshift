#!/usr/bin/env bash
# @file: cockpit-containers-list-stats.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/containers-list/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/containers-list/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints one podman stats sample for the given containers, limited to the given seconds.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints one podman stats sample for the given containers, limited to the given seconds.
# @details:
#   Runs podman stats --no-stream --format json. Nothing usable is printed on a timeout or an
#   error; callers then leave CPU and Memory out.
# @arg: $1 - seconds the sample may take.
# @arg: $@ - container IDs after the seconds.
# @stdout: podman stats JSON, or nothing.
# @exitcode: the podman exit code; callers use the output, not the code.
cockpit-containers-list-stats() {
    local seconds
    seconds="${1-}"
    shift
    if command -v timeout >/dev/null 2>&1; then
        timeout "${seconds}" podman stats --no-stream --format json -- "$@" 2>/dev/null
    else
        podman stats --no-stream --format json -- "$@" 2>/dev/null
    fi
}
