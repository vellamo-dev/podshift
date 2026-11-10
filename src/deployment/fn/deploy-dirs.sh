#!/usr/bin/env bash
# @file: deploy-dirs.sh
# @source-dir: src/deployment/fn
# @group: deployment
# @category: step
# @step: PS-DP-DRS
# @description: Deploys the source directory structure into the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

if [[ -z "${DIR_AC638D967F6D:-}" ]]; then
    DIR_AC638D967F6D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_AC638D967F6D
fi

# @description: Creates the source tree's directory structure inside the build root.
# @arg: $1 - build root directory.
# @arg: $2 - source tree directory.
deploy-dirs() {
    local -r step_tag="PS-DP-DRS"
    local path_dirs path_build
    path_build=$(realpath "$1")
    path_dirs=$(realpath "$2")
    cd "${path_dirs}"
    # shellcheck source=./utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_AC638D967F6D}/utils/print-step.sh"
    print-step-header "${step_tag}" "Deploying directories..."
    find . -type d -exec sh -c 'install -dm755 "$1" "$2/${1#./}"' _ {} "${path_build}" \;
    print-step-ok
}
