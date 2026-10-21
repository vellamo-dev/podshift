#!/usr/bin/env bash
# @file: deploy-sh-scripts.sh
# @dir: src/deployment/fn
# @group: deployment
# @prefix: PS-DP
# @id: SHS
# @description: Deploys shell scripts from the source tree into the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

# @description: Deploys .sh scripts from the source tree into the build root as executable.
# @param: $1 - build root directory.
# @param: $2 - source tree directory.
deploy-sh-scripts() {
    local -r step_tag="PS-DP-SHS"
    local path_sh_files path_build
    path_build=$(realpath "$1")
    path_sh_files=$(realpath "$2")
    cd "${path_sh_files}"
    print-step-header "${step_tag}" "Deploying shell scripts..."
    find . -name "*.sh" -type f -exec sh -c 'install -Dm755 "$1" "$2/${1#./}"' _ {} "${path_build}" \;
    print-step-ok
}