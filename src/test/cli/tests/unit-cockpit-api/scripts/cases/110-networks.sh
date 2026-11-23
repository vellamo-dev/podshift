#!/usr/bin/env bash
# @file: 110-networks.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: networks-list with podman and systemctl stubbed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# networks-list: podman and systemctl are stubbed; Quadlet and user unit files are real files.
net_home="${WORK}/networks-home"
mkdir -p "${net_home}/quadlets/shop.qdl-bundle" "${net_home}/.config/systemd/user"
printf '[Network]\nNetworkName=tsv-nw1\nSubnet=10.89.0.0/24\n' > "${net_home}/quadlets/shop.qdl-bundle/tsv-nw1.network"
printf '[Network]\nSubnet=10.91.0.0/24\n' > "${net_home}/quadlets/plain.network"
printf '[Service]\nType=oneshot\nExecStart=/usr/bin/podman network create --ignore --subnet 10.202.0.0/24 example-unit\n' > "${net_home}/.config/systemd/user/example-unit-network.service"
printf '[Service]\nExecStart=/usr/bin/podman run --network tsv-nw1 img\n' > "${net_home}/.config/systemd/user/other.service"
cockpit-networks-list-podman() {
    case "${1-} ${2-}" in
        "network ls")
            printf '%s\n' '[{"name":"podman"},{"name":"tsv-nw1"},{"name":"systemd-plain"},{"name":"example-unit"},{"name":"loose"}]'
            ;;
        "network inspect")
            printf '%s\n' '[
                {"name":"podman","id":"2f259bab93aaaaa2542b","driver":"bridge","network_interface":"podman0","subnets":[{"subnet":"10.88.0.0/16","gateway":"10.88.0.1"}],"ipv6_enabled":false,"internal":false,"dns_enabled":false},
                {"name":"tsv-nw1","id":"3f1c2b8e9d0a4b5c6d7e","driver":"bridge","network_interface":"podman1","subnets":[{"subnet":"10.89.0.0/24","gateway":"10.89.0.1"}],"ipv6_enabled":false,"internal":false,"dns_enabled":true,"labels":{"PODMAN_SYSTEMD_UNIT":"tsv-nw1-network.service"},"containers":{"a1b2c3":{"name":"shop","interfaces":{"eth0":{"subnets":[{"ipnet":"10.89.0.10/24"}]}}}}},
                {"name":"systemd-plain","id":"5a5a5a5a5a5a5a5a5a5a","driver":"bridge","subnets":[{"subnet":"10.91.0.0/24","gateway":"10.91.0.1"}],"ipv6_enabled":false,"internal":false,"dns_enabled":true},
                {"name":"example-unit","id":"9e8d7c6b5a4938271605","driver":"bridge","subnets":[{"subnet":"10.202.0.0/24","gateway":"10.202.0.1"}],"ipv6_enabled":false,"internal":false,"dns_enabled":true},
                {"name":"loose","id":"1111111111111111","driver":"bridge","subnets":[],"ipv6_enabled":false,"internal":true,"dns_enabled":false}
            ]'
            ;;
        *)
            return 1
            ;;
    esac
}
cockpit-networks-list-systemctl() {
    local unit first
    first=1
    while [[ "${1-}" != "--" && $# -gt 0 ]]; do shift; done
    shift
    for unit in "$@"; do
        (( first == 1 )) || printf '\n'
        first=0
        case "${unit}" in
            tsv-nw1-network.service) printf 'ActiveState=active\n' ;;
            *) printf 'ActiveState=inactive\n' ;;
        esac
    done
}
networks_out="$(HOME="${net_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${net_home}/quadlets" cockpit-module-networks-list)"
networks_contract="$(jq -c '.output' "${API}/modules/networks-list/capability.json")"
if printf '%s' "${networks_out}" | jq -e '
    ([.items[].id] == ["example-unit","loose","podman","systemd-plain","tsv-nw1"])
    and ([.items[] | {(.id): .source}] | add) == {"example-unit":"unit","loose":"unmanaged","podman":"builtin","systemd-plain":"quadlet","tsv-nw1":"quadlet"}
    and ([.items[] | {(.id): .status}] | add) == {"example-unit":"Unused","loose":"Unused","podman":"Unused","systemd-plain":"Unused","tsv-nw1":"In use"}
    and (.items[] | select(.id == "tsv-nw1") | .groups[0]) == {"id":"systemd","label":"Systemd","rows":[
        {"id":"unit","label":"Unit name","value":"tsv-nw1-network.service"},
        {"id":"unit_state","label":"Unit state","value":"active"},
        {"id":"file","label":"File","value":"~/quadlets/shop.qdl-bundle/tsv-nw1.network"},
        {"id":"app","label":"App","value":"shop"}]}
    and ((.items[] | select(.id == "systemd-plain") | .groups[0].rows | map(.id)) == ["unit","unit_state","file"])
    and ((.items[] | select(.id == "example-unit") | .groups[0].rows) == [
        {"id":"unit","label":"Unit name","value":"example-unit-network.service"},
        {"id":"unit_state","label":"Unit state","value":"inactive"},
        {"id":"file","label":"File","value":"~/.config/systemd/user/example-unit-network.service"}])
    and ((.items[] | select(.id == "tsv-nw1") | .groups[1].rows) == [{"id":"shop","label":"shop","value":"10.89.0.10"}])
    and ([.items[] | select(has("quadlet")) | {(.id): .quadlet}] == [{"systemd-plain": {"name": "plain.network"}}, {"tsv-nw1": {"name": "tsv-nw1.network", "app": "shop"}}])
' >/dev/null && cockpit-validate-contract "${networks_contract}" "${networks_out}"; then
    ok "networks-list-stubbed"
else
    bad "networks-list-stubbed" "${networks_out}"
fi

cockpit-networks-list-podman() {
    case "${1-} ${2-}" in
        "network ls") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
networks_out="$(HOME="${WORK}/networks-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/networks-none" cockpit-module-networks-list)"
expect_eq "networks-list-empty" "${networks_out}" '{"items":[]}'

cockpit-networks-list-podman() {
    return 1
}
if networks_out="$(HOME="${WORK}/networks-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/networks-none" cockpit-module-networks-list 2>/dev/null)"; then
    bad "networks-list-podman-fails" "${networks_out}"
else
    ok "networks-list-podman-fails"
fi

