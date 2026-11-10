#!/usr/bin/env bash
# @file: is-darwin.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Detects whether the running system is macOS (Darwin).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi


# @description: Returns 0 if the running system is macOS (Darwin).
# @exitcode: 0 if Darwin, 1 otherwise.
is-darwin() {
    local kernel_name
    kernel_name="$(uname -s)"
    [[ "${kernel_name}" == "Darwin" ]]
}
