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

# @description: Shows a spinner and the check title on one line until it is stopped.
# @arg: $1 - the check title.
# @stdout: the spinner line, redrawn in place.
health-run-live-spinner() {
    local title spinner j
    title="${1}"
    spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while true; do
        for ((j = 0; j < ${#spinner}; j++)); do
            printf '\r\033[K        %s %s' "${spinner:j:1}" "${title}"
            sleep 0.1
        done
    done
}

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
