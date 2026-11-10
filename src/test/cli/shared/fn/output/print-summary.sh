#!/usr/bin/env bash
# @file: print-summary.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Prints the Summary block at the end of a run.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Summary block, marked with ◆: one line per planned test with its result, then the run result.
# @details:
#   Interactive mode colors ◆ and the result by the run result: green passed, yellow cannot run
#   here, red failed or error.
# @arg: $1 - the output mode: interactive or plain. Plain has no colors.
# @arg: $2 - the run exit code: 0 passed, 1 test error, 2 product failed, 3 cannot run here.
# @arg: $3 - one line per test, separated by |: exit code (empty if not run), title, first problem.
# @stdout: the Summary block.
print-summary() {
    local mode run_rc rows width rc title problem icon color text line run_text run_color
    mode="${1}"
    run_rc="${2}"
    rows="${3}"
    width="$(printf '%s\n' "${rows}" | awk -F '|' '{ if (length($2) > w) w = length($2) } END { print w + 0 }')"
    case "${run_rc}" in
        0) color=32; text="passed" ;;
        2) color=31; text="failed" ;;
        3) color=33; text="cannot run" ;;
        *) color=31; text="error" ;;
    esac
    if [[ "${mode}" == "interactive" ]]; then
        printf '\n\033[1;%sm◆\033[0m \033[1mSummary\033[0m\n\n' "${color}"
    else
        printf '\n◆ Summary\n\n'
    fi
    run_text="${text}"
    run_color="${color}"
    while IFS='|' read -r rc title problem; do
        case "${rc}" in
            0) icon="✔"; color=32; text="passed" ;;
            2) icon="✘"; color=31; text="failed" ;;
            3) icon="✘"; color=31; text="cannot run" ;;
            "") icon="○"; color=90; text="not run" ;;
            *) icon="⚠"; color=33; text="error" ;;
        esac
        [[ "${mode}" != "interactive" ]] || icon=$'\033['"${color}"'m'"${icon}"$'\033[0m'
        line="$(printf '    %s %-*s   %s' "${icon}" "${width}" "${title}" "${text}")"
        [[ -z "${problem}" ]] || line="$(printf '%-*s   %s' $((${#line} + 10 - ${#text})) "${line}" "${problem}")"
        printf '%s\n' "${line}"
    done <<<"${rows}"
    if [[ "${mode}" == "interactive" ]]; then
        printf '\n    Result: \033[1;%sm%s\033[0m (exit %s)\n' "${run_color}" "${run_text}" "${run_rc}"
    else
        printf '\n    Result: %s (exit %s)\n' "${run_text}" "${run_rc}"
    fi
}
