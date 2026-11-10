#!/usr/bin/env bash
# @file: print-run-header.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Prints the run header, shown once per run.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the run title, the environment, the bash on PATH, the output mode, the logs folder and the start time.
# @details:
#   Interactive mode shows the title in bold and the labels dimmed, so the test headers stand out
#   more. When the running shell's bash path differs from the one on PATH, that running bash is
#   printed on the next line.
# @arg: $1 - the output mode: interactive or plain. Plain has no colors.
# @arg: $2 - the environment, for example macOS 27.0.1.
# @arg: $3 - the output mode and reason, for example plain (no terminal).
# @arg: $4 - the run folder shown on screen.
# @stdout: the run header.
print-run-header() {
    local title_on label_on off bash_path bash_version
    title_on=""
    label_on=""
    off=""
    if [[ "${1}" == "interactive" ]]; then
        title_on=$'\033[1m'
        label_on=$'\033[2m'
        off=$'\033[0m'
    fi
    bash_path="$(command -v bash 2>/dev/null || true)"
    if [[ -n "${bash_path}" ]]; then
        bash_version="$("${bash_path}" -c 'printf %s "$BASH_VERSION"')"
    else
        bash_path=""
        bash_version=""
    fi
    printf '\n%sPodShift Development Tests%s\n' "${title_on}" "${off}"
    printf '    %sEnvironment:%s %s\n' "${label_on}" "${off}" "${2}"
    if [[ -n "${bash_path}" ]]; then
        printf '    %sBash:%s %s (%s)\n' "${label_on}" "${off}" "${bash_version}" "${bash_path}"
    else
        printf '    %sBash:%s unknown\n' "${label_on}" "${off}"
    fi
    if [[ -n "${BASH:-}" && -n "${bash_path}" && "${BASH}" != "${bash_path}" ]]; then
        printf '    %sBash (running):%s %s (%s)\n' "${label_on}" "${off}" "${BASH_VERSION}" "${BASH}"
    fi
    printf '    %sOutput:%s %s\n' "${label_on}" "${off}" "${3}"
    printf '    %sLogs:%s %s\n' "${label_on}" "${off}" "${4}"
    printf '    %sTime:%s %s\n' "${label_on}" "${off}" "$(date '+%Y-%m-%d %H:%M:%S')"
}
