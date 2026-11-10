#!/usr/bin/env bash
# @file: deploy-sh-scripts.sh
# @source-dir: src/deployment/fn
# @group: deployment
# @category: step
# @step: PS-DP-SHS
# @description: Deploys shell scripts from the source tree into the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

if [[ -z "${DIR_69240E92BC62:-}" ]]; then
    DIR_69240E92BC62="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_69240E92BC62
fi

# @description: Deploys .sh scripts from the source tree into the build root as executable.
# @arg: $1 - build root directory.
# @arg: $2 - source tree directory.
deploy-sh-scripts() {
    local -r step_tag="PS-DP-SHS"
    local path_sh_files path_build
    path_build=$(realpath "$1")
    path_sh_files=$(realpath "$2")
    cd "${path_sh_files}"
    # shellcheck source=./utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_69240E92BC62}/utils/print-step.sh"
    print-step-header "${step_tag}" "Deploying shell scripts..."
    find . -name "*.sh" -type f -exec sh -c 'install -Dm755 "$1" "$2/${1#./}"' _ {} "${path_build}" \;
    print-step-ok
}
