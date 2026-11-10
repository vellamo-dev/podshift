#!/usr/bin/env bash
# @file: run-task.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Runs one task and prints its result with an icon.
# @details:
#   In interactive mode it shows a spinner, a timer and colors.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Shows a spinner on the task line until it is stopped.
# @details:
#   After 5 seconds it also shows the time so far.
# @arg: $1 - the task title shown on screen.
# @arg: $2 - the start time, in SECONDS.
# @stdout: the spinner line, redrawn in place.
run-task-spinner() {
    local name start spinner j timer
    name="${1}"
    start="${2}"
    spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while true; do
        # Stop if the test itself is gone, so the spinner never keeps drawing alone.
        kill -0 "$$" 2>/dev/null || exit 0
        for ((j = 0; j < ${#spinner}; j++)); do
            timer=""
            ((SECONDS - start < 5)) || timer=" ($(format-duration "$((SECONDS - start))"))"
            printf '\r\033[K        %s %s%s' "${spinner:j:1}" "${name}" "${timer}"
            sleep 0.1
        done
    done
}

# @description: Stops the test on Ctrl+C: stops the spinner, removes the task output file and prints which task was interrupted.
# @arg: $1 - the spinner process, or empty for none.
# @arg: $2 - the task output file.
# @arg: $3 - the task title shown on screen.
# @stdout: the interrupted line, on fd 9, which run-task points at the screen.
# @exitcode: always exits the test with 130.
run-task-interrupt() {
    # Only the spinner (interactive mode) needs its line cleared, so plain output has no escape codes.
    [[ -z "${1}" ]] || { kill "${1}" 2>/dev/null; wait "${1}" 2>/dev/null; printf '\r\033[K' >&9; }
    rm -f "${2}"
    printf '        Interrupted: %s\n' "${3}" >&9
    exit 130
}

# @description: Runs a task and prints ✔ or ✘.
# @details:
#   In interactive mode a spinner runs meanwhile, after 5 seconds with the time so far, and the
#   icons are colored. In plain mode only the final line is printed. The final time is shown in
#   brackets after 5 seconds.
# @arg: $1 - the output mode: interactive or plain.
# @arg: $2 - a file for the first problem of the test, or empty for none. When the task does not pass and the file does not exist yet, the task title and its first output line are written to it.
# @arg: $3 - the task title shown on screen.
# @arg: $4... - the command to run.
# @stdout: the task line, and its DETAIL lines.
# @stderr: the task output when it did not pass.
# @exitcode: the exit code of the command. On Ctrl+C the whole test stops with exit code 130.
run-task() {
    local mode problem_file name rc output_file note detail spinner_pid start secs extra ok bad problem
    mode="${1}"
    problem_file="${2}"
    name="${3}"
    shift 3
    output_file="$(mktemp)"
    start="${SECONDS}"
    spinner_pid=""
    if [[ "${mode}" == "interactive" ]]; then
        run-task-spinner "${name}" "${start}" &
        spinner_pid=$!
    fi
    # Ctrl+C: stop the spinner and the whole test, instead of only the command that was running.
    # fd 9 keeps the screen, since the task output goes to a file while the task runs.
    exec 9>&1
    trap 'run-task-interrupt "${spinner_pid}" "${output_file}" "${name}"' INT TERM
    "$@" </dev/null >"${output_file}" 2>&1
    rc=$?
    trap - INT TERM
    exec 9>&-
    secs=$((SECONDS - start))
    [[ -z "${spinner_pid}" ]] || { kill "${spinner_pid}" 2>/dev/null; wait "${spinner_pid}" 2>/dev/null; printf '\r\033[K'; }
    note="$(grep -m1 '^NOTE: ' "${output_file}" 2>/dev/null | sed 's/^NOTE: //')"
    detail="$(grep '^DETAIL: ' "${output_file}" 2>/dev/null | sed 's/^DETAIL: //')"
    extra="${note}"
    ((secs < 5)) || extra="${extra:+${extra}, }$(format-duration "${secs}")"
    [[ -z "${extra}" ]] || extra=" [${extra}]"
    ok="✔"
    bad="✘"
    [[ "${mode}" != "interactive" ]] || { ok=$'\033[32m✔\033[0m'; bad=$'\033[31m✘\033[0m'; }
    if ((rc == 0)); then
        printf '        %s %s%s\n' "${ok}" "${name}" "${extra}"
    else
        printf '        %s %s%s\n' "${bad}" "${name}" "${extra}"
        grep -v -e '^DETAIL: ' -e '^NOTE: ' "${output_file}" | sed 's/^/            /' >&2
        if [[ -n "${problem_file}" && ! -e "${problem_file}" ]]; then
            problem="$(grep -v -e '^NOTE: ' -e '^[[:space:]]*$' "${output_file}" | head -n 1 | sed 's/^DETAIL: //')"
            printf '%s%s\n' "${name}" "${problem:+: ${problem}}" >"${problem_file}" 2>/dev/null
        fi
    fi
    [[ -z "${detail}" ]] || printf '%s\n' "${detail}" | sed 's/^/            /'
    rm -f "${output_file}"
    return "${rc}"
}
