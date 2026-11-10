#!/usr/bin/env bash
# @file: is-windows.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Detects whether the running system is Windows.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the running system is Windows (native, Git Bash, MSYS, or Cygwin).
# @exitcode: 0 if Windows, 1 otherwise.
is-windows() {
    local kernel_name
    kernel_name="$(uname -s 2>/dev/null)"
    [[ "${OS:-}" == "Windows_NT" ]] || \
        [[ "${kernel_name}" == MINGW* || "${kernel_name}" == MSYS* || "${kernel_name}" == CYGWIN* ]]
}
