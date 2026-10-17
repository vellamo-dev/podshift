#!/usr/bin/env bash
# is-windows.sh
# /usr/local/etc/podshift/fn/utils

# Returns 0 (true) if the running system is Windows (native, Git Bash, MSYS, or Cygwin), non-zero otherwise.
is-windows() {
    local kernel_name
    kernel_name="$(uname -s 2>/dev/null)"
    [[ "${OS:-}" == "Windows_NT" ]] || \
        [[ "${kernel_name}" == MINGW* || "${kernel_name}" == MSYS* || "${kernel_name}" == CYGWIN* ]]
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-windows
fi
