#!/usr/bin/env bash
# @file: print-step-header.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints a step header line tagged with the step id.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Emits a section header tagged with the step id.
# @arg: $1 - step tag (e.g. "PS-PT-DRC")
# @arg: $2 - header message
# @stdout: prints the tagged header line
print-step-header() {
    local tag message
    tag="${1}"
    message="${2}"
    echo -e "\n[${tag}] ${message}"
}
