#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/update-self
# @dest-dir: /opt/podshift/cli/modules/update-self
# @host-edit: no
# @group: cli
# @category: entry
# @description: Updates the PodShift package to the latest version.
# @run-as: root
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Updates the PodShift package to the latest version.
# @exitcode: 0 on success, 1 if not an administrator, not updatable, or the update fails.
podshift-update-self() {
    # shellcheck source=../../../fn/utils/require-admin.sh
    declare -F require-admin >/dev/null || source /opt/podshift/fn/utils/require-admin.sh
    require-admin || return 1

    # Verify the package is available in an enabled repository.
    if [[ -z "$(dnf repoquery podshift 2>/dev/null)" ]]; then
        echo "PodShift cannot be updated: not available in any enabled repository." >&2
        echo "It may have been installed directly from an RPM file instead of COPR." >&2
        return 1
    fi

    sudo dnf update --refresh podshift -y
}

podshift-update-self "$@"
