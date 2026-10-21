#!/usr/bin/env bash
# @file: deploy-dirs.sh
# @dir: src/deployment/fn
# @group: deployment
# @prefix: PS-DP
# @id: DRS
# @description: Deploys the source directory structure into the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

# @description: Creates the source tree's directory structure inside the build root.
# @param: $1 - build root directory.
# @param: $2 - source tree directory.
deploy-dirs() {
    local -r step_tag="PS-DP-DRS"
    local path_dirs path_build
    path_build=$(realpath "$1")
    path_dirs=$(realpath "$2")
    cd "${path_dirs}"
    print-step-header "${step_tag}" "Deploying directories..."
    find . -type d -exec sh -c 'install -dm755 "$1" "$2/${1#./}"' _ {} "${path_build}" \;
    print-step-ok
}