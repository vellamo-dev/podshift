#!/usr/bin/env bash
# @file: deploy-sh-symlinks.sh
# @dir: src/deployment/fn
# @group: deployment
# @prefix: PS-DP
# @id: SYM
# @description: Creates the extensionless command links in the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

# @description: Creates extensionless command links from the shortcut scripts.
# @param: $1 - build root directory.
# @param: $2 - source tree directory.
deploy-sh-symlinks() {
    local -r step_tag="PS-DP-SYM"
    local path_build path_src name script count
    path_build=$(realpath "$1")
    path_src=$(realpath "$2")
    count=0

    print-step-header "${step_tag}" "Deploying command links..."
    mkdir -p "${path_build}/usr/bin" "${path_build}/usr/sbin"

    # Dispatcher and first-class commands become /usr/bin/<name>.
    for script in "${path_src}/opt/podshift/bin/"*.sh; do
        [[ -e "${script}" ]] || continue
        name="$(basename "${script}" .sh)"
        ln -sfn "/opt/podshift/bin/${name}.sh" "${path_build}/usr/bin/${name}"
        count=$((count + 1))
    done

    # Rootless shortcuts become /usr/bin/<name>.
    for script in "${path_src}/opt/podshift/shortcuts/rootless/"*.sh; do
        [[ -e "${script}" ]] || continue
        name="$(basename "${script}" .sh)"
        ln -sfn "/opt/podshift/shortcuts/rootless/${name}.sh" "${path_build}/usr/bin/${name}"
        count=$((count + 1))
    done

    # Root shortcuts become /usr/sbin/<name>.
    for script in "${path_src}/opt/podshift/shortcuts/root/"*.sh; do
        [[ -e "${script}" ]] || continue
        name="$(basename "${script}" .sh)"
        ln -sfn "/opt/podshift/shortcuts/root/${name}.sh" "${path_build}/usr/sbin/${name}"
        count=$((count + 1))
    done

    print-step-ok "Created ${count} command links"
}
