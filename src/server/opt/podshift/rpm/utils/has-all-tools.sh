#!/usr/bin/env bash
# @file: has-all-tools.sh
# @source-dir: src/server/opt/podshift/rpm/utils
# @dest-dir: /opt/podshift/rpm/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Returns 0 when every named tool is on PATH.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 when every named tool is on PATH.
# @arg: $@ - tool names to check
# @exitcode: 0 if all tools are on PATH, 1 otherwise.
has-all-tools() {
    local tool
    for tool in "$@"; do
        command -v "${tool}" >/dev/null 2>&1 || return 1
    done
    return 0
}
