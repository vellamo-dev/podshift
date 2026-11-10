#!/usr/bin/env bash
# @file: deploy-sh-symlinks.sh
# @source-dir: src/deployment/fn
# @group: deployment
# @category: step
# @step: PS-DP-SYM
# @description: Creates the extensionless command links in the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

if [[ -z "${DIR_DAA882B02926:-}" ]]; then
    DIR_DAA882B02926="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DAA882B02926
fi

# @description: Creates extensionless command links from the shortcut scripts.
# @arg: $1 - build root directory.
# @arg: $2 - source tree directory.
deploy-sh-symlinks() {
    local -r step_tag="PS-DP-SYM"
    local path_build path_src name script count
    path_build=$(realpath "$1")
    path_src=$(realpath "$2")
    count=0
    # shellcheck source=./utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_DAA882B02926}/utils/print-step.sh"
    print-step-header "${step_tag}" "Deploying command links..."
    mkdir -p "${path_build}/usr/bin" "${path_build}/usr/sbin"

    # Dispatcher becomes /usr/bin/podshift.
    for script in "${path_src}/opt/podshift/cli/"*.sh; do
        [[ -e "${script}" ]] || continue
        name="$(basename "${script}" .sh)"
        ln -sfn "/opt/podshift/cli/${name}.sh" "${path_build}/usr/bin/${name}"
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
