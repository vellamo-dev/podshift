#!/usr/bin/env bash
# @file: print-deploy-header.sh
# @source-dir: src/deployment/fn/utils
# @group: deployment
# @category: helper
# @description: Prints a deployment step header line tagged with the step id.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Emits a section header tagged with the step id.
# @arg: $1 - step tag (e.g. "PS-DP-DRS")
# @arg: $2 - header message
# @stdout: prints the tagged header line
print-deploy-header() {
    local tag message
    tag="${1}"
    message="${2}"
    echo -e "\n[${tag}] ${message}"
}
