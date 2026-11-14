#!/usr/bin/env bash
# @file: cockpit-overview-status-rows.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the ordered Overview status rows from a values object.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Overview status card as a rows object, in a fixed order.
# @details:
#   Missing keys become null. Each value must already be the display text, or null.
#   Each row includes unit, the systemd unit already checked for that row, and scope,
#   either user or system. User-scope rows link to the PodShift Services tab with
#   that unit as the search filter. System-scope rows link to Cockpit's Services page.
# @arg: $1 - a JSON object mapping row ids to string values or null.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 when the argument is not a JSON object.
cockpit-overview-status-rows() {
    local values
    values="${1-}"
    jq -n -c --argjson values "${values}" '
        if ($values | type) != "object" then halt_error(1) else . end
        | def v($k): if ($values | has($k)) then $values[$k] else null end;
        {rows: [
            {id: "podman_socket", label: "Podman API socket", value: v("podman_socket"), unit: "podman.socket", scope: "user"},
            {id: "auto_update", label: "Container auto-update", value: v("auto_update"), unit: "podman-auto-update.timer", scope: "user"},
            {id: "drop_watcher", label: "Drop-in folder watcher", value: v("drop_watcher"), unit: "podshift-drop.path", scope: "user"},
            {id: "drop_safety", label: "Drop-in safety check", value: v("drop_safety"), unit: "podshift-drop-safety.timer", scope: "user"},
            {id: "quadlet_validator", label: "Quadlet validator", value: v("quadlet_validator"), unit: "podshift-qdl-validate.path", scope: "user"},
            {id: "quadlet_installer", label: "Quadlet installer", value: v("quadlet_installer"), unit: "podshift-qdl-install.path", scope: "user"},
            {id: "tmpfiles_setup", label: "Temporary files setup", value: v("tmpfiles_setup"), unit: "systemd-tmpfiles-setup.service", scope: "user"},
            {id: "firewall", label: "Firewall", value: v("firewall"), unit: "firewalld.service", scope: "system"},
            {id: "fail2ban", label: "Fail2Ban", value: v("fail2ban"), unit: "fail2ban.service", scope: "system"},
            {id: "ssh_port", label: "SSH port", value: v("ssh_port"), unit: "sshd.service", scope: "system"}
        ]}
    '
}
