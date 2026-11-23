#!/usr/bin/env bash
# @file: health-run-live.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @description: Runs one health check while a spinner shows which check is running.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_79D638708AAC:-}" ]]; then
    DIR_79D638708AAC="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_79D638708AAC
fi

# @description: Runs one check and writes its result line to a file.
# @details:
#   In interactive mode a spinner shows the check title meanwhile, and the line is cleared at the
#   end.
# @arg: $1 - path to the check script.
# @arg: $2 - the group key, for example host.
# @arg: $3 - the caller: root, podshift, or other.
# @arg: $4 - the file that gets the result line.
# @stdout: the spinner line, in interactive mode only.
# @exitcode: 0 always.
health-run-live() {
    local script group caller out_file title spinner_pid
    script="${1}"
    group="${2}"
    caller="${3}"
    out_file="${4}"
    spinner_pid=""
    if [[ "${PODSHIFT_OUTPUT:-plain}" == "interactive" ]]; then
        title="$(grep -m1 '^# @title:' "${script}" 2>/dev/null | sed 's/^# @title: //')"
        # shellcheck source=health-run-live-spinner.sh
        declare -F health-run-live-spinner >/dev/null || source "${DIR_79D638708AAC}/health-run-live-spinner.sh"
        health-run-live-spinner "${title:-$(basename "${script}" .sh)}" &
        spinner_pid=$!
    fi
    # shellcheck source=health-result.sh
    declare -F health-result >/dev/null || source "${DIR_79D638708AAC}/health-result.sh"
    health-result "${script}" "${group}" "${caller}" > "${out_file}"
    if [[ -n "${spinner_pid}" ]]; then
        kill "${spinner_pid}" 2>/dev/null
        wait "${spinner_pid}" 2>/dev/null
        printf '\r\033[K'
    fi
    return 0
}
