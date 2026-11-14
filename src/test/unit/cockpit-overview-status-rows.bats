#!/usr/bin/env bats
# Unit test for cockpit-overview-status-rows (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-status-rows.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-status-rows.sh"
}

@test "ids and labels are fixed and in order" {
    run cockpit-overview-status-rows '{}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        [.rows[].id] == ["podman_socket","auto_update","drop_watcher","drop_safety","quadlet_validator","quadlet_installer","tmpfiles_setup","firewall","fail2ban","ssh_port"]
        and [.rows[].label] == ["Podman API socket","Container auto-update","Drop-in folder watcher","Drop-in safety check","Quadlet validator","Quadlet installer","Temporary files setup","Firewall","Fail2Ban","SSH port"]
        and all(.rows[]; .value == null)
        and all(.rows[]; .id | test("^[a-z0-9_]+$"))
        and .rows[0].unit == "podman.socket" and .rows[0].scope == "user"
        and .rows[1].unit == "podman-auto-update.timer" and .rows[1].scope == "user"
        and .rows[2].unit == "podshift-drop.path" and .rows[2].scope == "user"
        and .rows[3].unit == "podshift-drop-safety.timer" and .rows[3].scope == "user"
        and .rows[4].unit == "podshift-qdl-validate.path" and .rows[4].scope == "user"
        and .rows[5].unit == "podshift-qdl-install.path" and .rows[5].scope == "user"
        and .rows[6].unit == "systemd-tmpfiles-setup.service" and .rows[6].scope == "user"
        and .rows[7].unit == "firewalld.service" and .rows[7].scope == "system"
        and .rows[8].unit == "fail2ban.service" and .rows[8].scope == "system"
        and .rows[9].unit == "sshd.service" and .rows[9].scope == "system"
    '
}

@test "provided values are used and missing keys stay null" {
    run cockpit-overview-status-rows '{"podman_socket":"Running","ssh_port":"1022","fail2ban":null}'
    [ "${status}" -eq 0 ]
    printf '%s' "${output}" | jq -e '
        .rows[0].value == "Running"
        and .rows[8].value == null
        and .rows[9].value == "1022"
        and .rows[1].value == null
    '
}

@test "a non-object values argument fails" {
    run cockpit-overview-status-rows '[]'
    [ "${status}" -ne 0 ]
}
