#!/usr/bin/env bash
# @file: postun.sh
# @source-dir: src/server/opt/podshift/rpm
# @dest-dir: /opt/podshift/rpm
# @host-edit: no
# @group: postun
# @category: entry
# @step: PS-PU-0PU
# @description: Reports the data left behind after uninstallation.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Runs after the PodShift package files have been removed. It is self-contained
# (no sourced scripts) because the package files are already gone by this point.
# It never removes user data; it only reports what was left in place.

# @description: Reports the data left behind after uninstallation, also to the journal (tag podshift-install).
# @exitcode: 0 always.
podshift-rpm-do-postun() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PU-0PU"
    local action
    action="${1}"

    # Upgrade: the package is still installed, nothing to report.
    if [[ "${action}" -gt 0 ]]; then
        return 0
    fi

    # Log the report to the journal like the other scriptlets. The spec can't wrap this one, because it embeds the file.
    exec > >(tee >(systemd-cat -t podshift-install)) 2>&1

    # Final removal: report what was left in place (nothing removed automatically).
    echo "[${step_tag}] PodShift removed, data left in place"
    echo -e "\t- user podshift (UID 300), home /home/podshift"
    echo -e "\t- /var/lib/podshift/runtime.conf"
    echo -e "\t- container storage: /home/podshift/.local/share/containers"
    echo -e "\t- quadlets: /home/podshift/.config/containers/systemd, /home/podshift/.quadlets"
    echo -e "\t- /etc/subuid and /etc/subgid entries for podshift"
    echo -e "\t- enabled user services: podman.socket, podman-auto-update.timer"
    echo -e "\t- user lingering: /var/lib/systemd/linger/podshift"
    echo -e "\tTo fully remove, delete these manually and remove the podshift user."
    echo -e "\t[OK] Done"
    echo -e "\tDuration: ${SECONDS}s"
    exec >&- 2>&-
    wait
}

podshift-rpm-do-postun "${1:-0}"
