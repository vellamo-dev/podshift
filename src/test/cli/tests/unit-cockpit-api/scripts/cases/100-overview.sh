#!/usr/bin/env bash
# @file: 100-overview.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: Loads the modules, then the overview modules and the health check.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# --- overview modules ---

for cap_action in overview-status overview-usage overview-info overview-config health-check networks-list images-list volumes-list containers-list inspect secrets-list services-list service-view service-logs quadlets-list quadlet-view config-set config-unset env-set quadlet-drop quadlet-drop-history quadlet-install-log quadlet-remove; do
    cap_file="${API}/modules/${cap_action}/capability.json"
    cap_raw="$(cat "${cap_file}")"
    cockpit-validate-capability "${cap_action}" "${cap_raw}"
    [[ "$?" -eq 0 ]]
    expect_status "${cap_action}-metadata" $? "rc $?"
done

# overview-status is root realm: the handler runs the real module in this process.
reset_mocks
run_serve '{"apiVersion":1,"action":"overview-status","args":{}}'
if expect_code "overview-status-handler" "OK"; then
    if [[ "$(field '.status.message')" == "Action completed" && "$(field '.data | .rows | length')" == "11" ]]; then
        printf '%s' "$(field '.data')" | jq -e '[.rows[].id] == ["podman_socket","auto_update","drop_watcher","drop_safety","quadlet_validator","quadlet_installer","quadlet_remover","tmpfiles_setup","firewall","fail2ban","ssh_port"]' >/dev/null
        expect_status "overview-status-handler" $? "${LAST_OUT}"
    else
        bad "overview-status-handler" "${LAST_OUT}"
    fi
fi

cockpit-overview-status-user-show() {
    case "${1}" in
        podman.socket) printf 'LoadState=loaded\nActiveState=active\nSubState=listening\n' ;;
        podman-auto-update.timer) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-drop.path) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-drop-safety.timer) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-qdl-validate.path) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-qdl-install.path) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-qdl-remove.path) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        systemd-tmpfiles-setup.service) printf 'LoadState=loaded\nActiveState=active\nSubState=exited\n' ;;
        *) printf 'LoadState=not-found\nActiveState=inactive\nSubState=dead\n' ;;
    esac
}
cockpit-overview-status-system-show() {
    case "${1}" in
        firewalld.service) printf 'LoadState=loaded\nActiveState=active\nSubState=running\n' ;;
        fail2ban.service) printf 'LoadState=not-found\nActiveState=inactive\nSubState=dead\n' ;;
        *) printf 'LoadState=not-found\nActiveState=inactive\nSubState=dead\n' ;;
    esac
}
cockpit-overview-status-sshd-t() {
    printf 'port 1022\npasswordauthentication no\n'
}
status_out="$(cockpit-module-overview-status)"
if printf '%s' "${status_out}" | jq -e '
    [.rows[].id] == ["podman_socket","auto_update","drop_watcher","drop_safety","quadlet_validator","quadlet_installer","quadlet_remover","tmpfiles_setup","firewall","fail2ban","ssh_port"]
    and .rows[0].value == "Running"
    and .rows[1].value == "Waiting"
    and .rows[6].value == "Waiting"
    and .rows[7].value == "Exited"
    and .rows[8].value == "Running"
    and .rows[9].value == null
    and .rows[10].value == "1022"
    and .rows[0].unit == "podman.socket" and .rows[0].scope == "user"
    and .rows[1].unit == "podman-auto-update.timer" and .rows[1].scope == "user"
    and .rows[2].unit == "podshift-drop.path" and .rows[2].scope == "user"
    and .rows[3].unit == "podshift-drop-safety.timer" and .rows[3].scope == "user"
    and .rows[4].unit == "podshift-qdl-validate.path" and .rows[4].scope == "user"
    and .rows[5].unit == "podshift-qdl-install.path" and .rows[5].scope == "user"
    and .rows[6].unit == "podshift-qdl-remove.path" and .rows[6].scope == "user"
    and .rows[7].unit == "systemd-tmpfiles-setup.service" and .rows[7].scope == "user"
    and .rows[8].unit == "firewalld.service" and .rows[8].scope == "system"
    and .rows[9].unit == "fail2ban.service" and .rows[9].scope == "system"
    and .rows[10].unit == "sshd.service" and .rows[10].scope == "system"
' >/dev/null; then
    expect_row_contract "overview-status-stubbed" "${status_out}"
else
    bad "overview-status-stubbed" "${status_out}"
fi

cockpit-overview-usage-service-counts() {
    printf '1 / 2\n'
}
cockpit-overview-usage-quadlet-counts() {
    case "${1}" in
        all) printf '0\n' ;;
    esac
}
cockpit-overview-usage-podman-counts() {
    case "${1}" in
        networks) printf '1\n' ;;
        containers) printf '2 / 4\n' ;;
        volumes) printf '0 / 1\n' ;;
        images) printf '2 / 5\n' ;;
        secrets) printf '0\n' ;;
    esac
}
usage_out="$(cockpit-module-overview-usage)"
if printf '%s' "${usage_out}" | jq -e '
    [.rows[].id] == ["services","networks","containers","volumes","images","quadlets","secrets"]
    and .rows[0].value == "1 / 2"
    and .rows[1].value == "1"
    and .rows[2].value == "2 / 4"
    and .rows[3].value == "0 / 1"
    and .rows[4].value == "2 / 5"
    and .rows[5].value == "0"
    and .rows[6].value == "0"
' >/dev/null; then
    expect_row_contract "overview-usage-stubbed" "${usage_out}"
else
    bad "overview-usage-stubbed" "${usage_out}"
fi

is-install-type-desktop() { return 0 ; }
install_out="$(cockpit-overview-info-install-type)"
expect_eq "overview-info-install-desktop" "${install_out}" "desktop"
is-install-type-desktop() { return 1 ; }
install_out="$(cockpit-overview-info-install-type)"
expect_eq "overview-info-install-server" "${install_out}" "server"

cockpit-overview-info-os-release() { printf 'PRETTY_NAME="Fedora Linux 45"\n' ; }
cockpit-overview-info-podman-version() { printf '5.0.0\n' ; }
cockpit-overview-info-podshift-version() { printf '0.1.0\n' ; }
cockpit-overview-info-fail2ban-version() { return 0 ; }
cockpit-overview-info-install-type() { printf 'server\n' ; }
info_out="$(cockpit-module-overview-info)"
if printf '%s' "${info_out}" | jq -e '
    [.rows[].id] == ["os","podman","podshift","fail2ban","install"]
    and .rows[0].value == "Fedora Linux 45"
    and .rows[1].value == "5.0.0"
    and .rows[2].value == "0.1.0"
    and .rows[3].value == null
    and .rows[4].value == "server"
    and .rows[4].label == "Install type"
' >/dev/null; then
    expect_row_contract "overview-info-stubbed" "${info_out}"
else
    bad "overview-info-stubbed" "${info_out}"
fi

cockpit-overview-config-tsv-text() { return 0; }
cockpit-overview-config-load() {
    TSV_ENV=dev
    TSV_NW1=192.0.2.10
    TSV_NW3=192.0.2.30
    PODSHIFT_ENV_TYPES=dev,,prod
    unset TSV_NW2 TSV_NW4 TSV_NW5 TSV_NW6 TSV_NW7 TSV_NW8
}
config_out="$(cockpit-module-overview-config)"
if printf '%s' "${config_out}" | jq -e '
    [.rows[].id] == ["tsv_env","tsv_nw1","tsv_nw3"]
    and .rows[0].value == "dev"
    and .rows[1].value == "192.0.2.10"
    and .rows[2].value == "192.0.2.30"
    and [.rows[].editable] == [false,false,false]
    and .envSuggestions == ["dev","prod"]
' >/dev/null; then
    expect_row_contract "overview-config-stubbed" "${config_out}"
else
    bad "overview-config-stubbed" "${config_out}"
fi

cockpit-overview-config-load() {
    unset TSV_ENV TSV_NW1 TSV_NW2 TSV_NW3 TSV_NW4 TSV_NW5 TSV_NW6 TSV_NW7 TSV_NW8
    unset PODSHIFT_ENV_TYPES
}
cockpit-overview-config-tsv-text() { return 0; }
config_out="$(cockpit-module-overview-config)"
if printf '%s' "${config_out}" | jq -e '
    (.rows | length) == 1
    and .rows[0].id == "tsv_env"
    and .rows[0].label == "TSV_ENV"
    and .rows[0].value == null
    and .rows[0].editable == true
    and .envSuggestions == []
' >/dev/null; then
    expect_row_contract "overview-config-no-nw" "${config_out}"
else
    bad "overview-config-no-nw" "${config_out}"
fi

cockpit-overview-config-load() {
    TSV_ENV=dev
    TSV_NW1=192.0.2.10
    unset TSV_NW2 TSV_NW3 TSV_NW4 TSV_NW5 TSV_NW6 TSV_NW7 TSV_NW8
}
cockpit-overview-config-tsv-text() {
    printf '# comment\nTSV_ENV=ignored\nTSV_ZED=z\nTSV_APP=ok\nTSV_bad=no\nTSV_EMPTY=\nTSV_NWOLD=x\n'
}
config_out="$(cockpit-module-overview-config)"
if printf '%s' "${config_out}" | jq -e '
    (.rows | length) == 5
    and [.rows[].id] == ["tsv_env","tsv_nw1","tsv_app","tsv_nwold","tsv_zed"]
    and .rows[0].value == "dev"
    and .rows[1].value == "192.0.2.10"
    and .rows[2].id == "tsv_app" and .rows[2].label == "TSV_APP" and .rows[2].value == "ok"
    and .rows[4].id == "tsv_zed" and .rows[4].label == "TSV_ZED" and .rows[4].value == "z"
    and [.rows[].editable] == [false,false,true,false,true]
' >/dev/null; then
    expect_row_contract "overview-config-user-keys" "${config_out}"
else
    bad "overview-config-user-keys" "${config_out}"
fi

cockpit-health-check-run() {
    printf '%s\n' \
        $'host\tos\tOS\tOK\tFedora Linux 45\t' \
        $'config\tconfig-files\tConfig files\tINFO\tno custom keys yet\tpodshift --help config' \
        $'network\tregistries\tRegistries\tOK\tall reachable\t'
}
health_out="$(cockpit-module-health-check)"
if printf '%s' "${health_out}" | jq -e '
    (.groups | length) == 3
    and .groups[0].id == "host" and .groups[0].label == "Host"
    and .groups[0].rows[0] == {"id":"os","label":"OS","state":"ok","value":"Fedora Linux 45","fix":null}
    and .groups[1].id == "config" and .groups[1].label == "Configuration"
    and .groups[1].rows[0].state == "note"
    and .groups[1].rows[0].fix == "podshift --help config"
    and .groups[2].id == "network" and .groups[2].label == "Network and monitoring"
    and .summary.state == "ok"
    and .summary.label == "Healthy (2 passed, 1 note)"
    and .summary.passed == 2
    and .summary.notes == 1
    and .summary.warnings == 0
    and .summary.failed == 0
' >/dev/null; then
    ok "health-check-stubbed"
else
    bad "health-check-stubbed" "${health_out}"
fi

