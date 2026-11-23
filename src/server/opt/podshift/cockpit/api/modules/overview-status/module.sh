#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-status
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-status
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Overview status module: lists PodShift user units, the firewall, Fail2Ban and the SSH port.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_C4E18A27B9D0:-}" ]]; then
    DIR_C4E18A27B9D0="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C4E18A27B9D0
fi

# @description: Lists the state of PodShift services, the firewall, Fail2Ban and the SSH port.
# @details:
#   User units are always read from the podshift user manager (UID 300). Firewall and
#   Fail2Ban are system services. The SSH port comes from sshd -T. Each value is already
#   the text shown in the UI, or null when the check could not run.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 otherwise.
cockpit-module-overview-status() {
    local values label port
    # shellcheck source=./fn/cockpit-overview-status-user-show.sh
    declare -F cockpit-overview-status-user-show >/dev/null || source "${DIR_C4E18A27B9D0}/fn/cockpit-overview-status-user-show.sh"
    # shellcheck source=./fn/cockpit-overview-status-label.sh
    declare -F cockpit-overview-status-label >/dev/null || source "${DIR_C4E18A27B9D0}/fn/cockpit-overview-status-label.sh"
    # shellcheck source=./fn/cockpit-overview-status-system-show.sh
    declare -F cockpit-overview-status-system-show >/dev/null || source "${DIR_C4E18A27B9D0}/fn/cockpit-overview-status-system-show.sh"
    # shellcheck source=./fn/cockpit-overview-status-sshd-t.sh
    declare -F cockpit-overview-status-sshd-t >/dev/null || source "${DIR_C4E18A27B9D0}/fn/cockpit-overview-status-sshd-t.sh"
    # shellcheck source=../../fn/overview/cockpit-overview-ssh-port.sh
    declare -F cockpit-overview-ssh-port >/dev/null || source "${DIR_C4E18A27B9D0}/../../fn/overview/cockpit-overview-ssh-port.sh"
    # shellcheck source=../../fn/overview/cockpit-overview-status-rows.sh
    declare -F cockpit-overview-status-rows >/dev/null || source "${DIR_C4E18A27B9D0}/../../fn/overview/cockpit-overview-status-rows.sh"
    values="{}"
    _overview_status_put() {
        local id text
        id="${1}"
        text="${2-}"
        if [[ -n "${text}" ]]; then
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" --arg value "${text}" '$values + {($id): $value}')" || return 1
        else
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" '$values + {($id): null}')" || return 1
        fi
    }
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-user-show podman.socket)")"
    _overview_status_put podman_socket "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-user-show podman-auto-update.timer)")"
    _overview_status_put auto_update "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-user-show podshift-drop.path)")"
    _overview_status_put drop_watcher "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-user-show podshift-drop-safety.timer)")"
    _overview_status_put drop_safety "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-user-show podshift-qdl-validate.path)")"
    _overview_status_put quadlet_validator "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-user-show podshift-qdl-install.path)")"
    _overview_status_put quadlet_installer "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-user-show podshift-qdl-remove.path)")"
    _overview_status_put quadlet_remover "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-user-show systemd-tmpfiles-setup.service)")"
    _overview_status_put tmpfiles_setup "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-system-show firewalld.service)")"
    _overview_status_put firewall "${label}" || return 1
    label="$(cockpit-overview-status-label "$(cockpit-overview-status-system-show fail2ban.service)")"
    _overview_status_put fail2ban "${label}" || return 1
    port="$(cockpit-overview-ssh-port "$(cockpit-overview-status-sshd-t)")" || port=""
    _overview_status_put ssh_port "${port}" || return 1
    cockpit-overview-status-rows "${values}"
}
