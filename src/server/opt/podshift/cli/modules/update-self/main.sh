#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/update-self
# @dest-dir: /opt/podshift/cli/modules/update-self
# @host-edit: no
# @group: cli
# @category: entry
# @description: Updates PodShift, and the PodShift Cockpit UI when it is installed, to the latest version.
# @run-as: root
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Updates podshift, and cockpit-podshift with it when installed from a repository.
# @details:
#   podshift must be in an enabled repository. When cockpit-podshift is installed and also in an
#   enabled repository, both are updated in one dnf transaction. When it is installed but in no
#   enabled repository (probably from an RPM file), only podshift is updated and a note is printed.
#   cockpit-podshift is never installed by this command.
# @stdout: the dnf output, and a reload hint when the UI was updated.
# @stderr: the reason on failure, or the note that cockpit-podshift was skipped.
# @exitcode: 0 on success, 1 if not an administrator, podshift is not updatable, or the update fails.
podshift-update-self() {
    local with_ui
    # shellcheck source=../../../fn/utils/require-admin.sh
    declare -F require-admin >/dev/null || source /opt/podshift/fn/utils/require-admin.sh
    require-admin || return 1

    # Verify the package is available in an enabled repository.
    if [[ -z "$(dnf repoquery podshift 2>/dev/null)" ]]; then
        echo "PodShift cannot be updated: not available in any enabled repository." >&2
        echo "It may have been installed directly from an RPM file instead of COPR." >&2
        return 1
    fi

    # Update the UI too, but only when it is installed and in an enabled repository.
    with_ui=no
    if rpm -q cockpit-podshift >/dev/null 2>&1; then
        if [[ -n "$(dnf repoquery cockpit-podshift 2>/dev/null)" ]]; then
            with_ui=yes
        else
            echo "Note: cockpit-podshift was skipped: it is not in any enabled repository (probably installed from an RPM file)." >&2
        fi
    fi

    if [[ "${with_ui}" == "yes" ]]; then
        sudo dnf update --refresh podshift cockpit-podshift -y || return 1
        echo "Reload the PodShift page in Cockpit to load the new UI."
        return 0
    fi
    sudo dnf update --refresh podshift -y || return 1
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    podshift-update-self "$@"
fi
