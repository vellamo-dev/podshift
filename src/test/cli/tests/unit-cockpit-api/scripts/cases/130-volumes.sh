#!/usr/bin/env bash
# @file: 130-volumes.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: volumes-list, cockpit-units-info and the batch inspect fallback.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# volumes-list: podman, systemctl and du are stubbed; Quadlet .volume and .container files are real files.
vol_home="${WORK}/volumes-home"
mkdir -p "${vol_home}/quadlets/shop.qdl-bundle"
printf '[Volume]\nVolumeName=pgdata\n' > "${vol_home}/quadlets/shop.qdl-bundle/pgdata.volume"
printf '[Volume]\n' > "${vol_home}/quadlets/unused.volume"
printf '[Container]\nImage=nginx\nVolume=web-data:/srv\n' > "${vol_home}/quadlets/web.container"
vol_anon="3f9a1c7e5b2d4086a1e9c3b7d5f2048e6a9c1b3d5f7e9a2c4b6d8f0e1a3c5b7d"
cockpit-volumes-list-podman() {
    case "${1-} ${2-}" in
        "volume ls")
            printf '[{"Name":"pgdata"},{"Name":"web-data"},{"Name":"loose"},{"Name":"%s"},{"Name":"pgdata"}]\n' "${vol_anon}"
            ;;
        "volume inspect")
            printf '[
                {"Name":"pgdata","Driver":"local","Mountpoint":"%s/vols/pgdata/_data","CreatedAt":"2026-10-28T11:15:00+02:00","Labels":{},"Options":{}},
                {"Name":"web-data","Driver":"local","Mountpoint":"%s/vols/web-data/_data","CreatedAt":"2026-11-02T14:40:00Z","Labels":{},"Options":{}},
                {"Name":"loose","Driver":"local","Mountpoint":"%s/vols/loose/_data","CreatedAt":"2026-09-30T18:05:00Z","Labels":{"podshift.example":"1"},"Options":{}},
                {"Name":"%s","Driver":"local","Mountpoint":"%s/vols/anon/_data","CreatedAt":"2026-11-10T21:03:00Z","Anonymous":true}
            ]\n' "${vol_home}" "${vol_home}" "${vol_home}" "${vol_anon}" "${vol_home}"
            ;;
        "ps -a")
            printf '%s\n' '[
                {"Id":"c1","Names":["db"],"State":"running","Labels":{"PODMAN_SYSTEMD_UNIT":"db.service"}},
                {"Id":"c2","Names":["web"],"State":"running","Labels":{"PODMAN_SYSTEMD_UNIT":"web.service"}},
                {"Id":"c3","Names":["db-backup"],"State":"exited","Labels":null}
            ]'
            ;;
        "container inspect")
            printf '[
                {"Id":"c1","Mounts":[{"Type":"volume","Name":"pgdata","Destination":"/var/lib/postgresql/data"}]},
                {"Id":"c2","Mounts":[{"Type":"volume","Name":"web-data","Destination":"/srv"},{"Type":"bind","Source":"/etc/x","Destination":"/x"}]},
                {"Id":"c3","Mounts":[{"Type":"volume","Name":"pgdata","Destination":"/data"},{"Type":"volume","Name":"%s","Destination":"/tmp/x"}]}
            ]\n' "${vol_anon}"
            ;;
        *)
            return 1
            ;;
    esac
}
# systemctl show gets all units in one call and prints one block per unit, an empty line between.
cockpit-volumes-list-systemctl() {
    local unit first
    first=1
    printf '%s\n' "${*}" >> "${WORK}/volumes-systemctl.log"
    while [[ "${1-}" != "--" && $# -gt 0 ]]; do shift; done
    shift
    for unit in "$@"; do
        (( first == 1 )) || printf '\n'
        first=0
        case "${unit}" in
            pgdata-volume.service) printf 'ActiveState=active\nSourcePath=%s\n' "${vol_home}/quadlets/shop.qdl-bundle/pgdata.volume" ;;
            web.service) printf 'ActiveState=active\nFragmentPath=/run/user/300/systemd/generator/web.service\nSourcePath=%s\n' "${vol_home}/quadlets/web.container" ;;
            db.service) printf 'ActiveState=active\nSourcePath=%s\n' "${vol_home}/quadlets/shop.qdl-bundle/db.container" ;;
            *) printf 'ActiveState=inactive\n' ;;
        esac
    done
}
cockpit-volumes-list-du() {
    case "${1-}" in
        */pgdata/_data) printf '412000000\t%s\n' "${1}" ;;
        */web-data/_data) printf '23400\t%s\n' "${1}"; return 1 ;;
        */anon/_data) printf 'du: cannot read\n'; return 1 ;;
        *) return 124 ;;
    esac
}
: > "${WORK}/volumes-systemctl.log"
volumes_out="$(HOME="${vol_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${vol_home}/quadlets" cockpit-module-volumes-list)"
volumes_contract="$(jq -c '.output' "${API}/modules/volumes-list/capability.json")"
if printf '%s' "${volumes_out}" | jq -e --arg anon "${vol_anon}" '
    ([.items[].id] == [$anon,"loose","pgdata","web-data"])
    and (.items[0].title == "3f9a1c7e5b2d")
    and ([.items[] | {(.id): .source}] | add) == {($anon):"unmanaged","loose":"unmanaged","pgdata":"quadlet","web-data":"container"}
    and ([.items[] | {(.id): [.status, .running]}] | add) == {($anon):["In use",false],"loose":["Unused",false],"pgdata":["In use",true],"web-data":["In use",true]}
    and ((.items[] | select(.id == "pgdata") | .rows) == [
        {"id":"mountpoint","label":"Mountpoint","value":"~/vols/pgdata/_data"},
        {"id":"driver","label":"Driver","value":"local"},
        {"id":"size","label":"Size","value":"412 MB"},
        {"id":"created","label":"Created","value":"2026-10-28T09:15:00Z"},
        {"id":"used-by","label":"Used by","value":"db (Running), db-backup (Exited)"}])
    and ((.items[] | select(.id == "web-data") | .rows[] | select(.id == "size") | .value) == "23.4 kB")
    and ([.items[] | select(.id == $anon or .id == "loose") | .rows[] | select(.id == "size")] == [])
    and ((.items[] | select(.id == "pgdata") | .groups[1]) == {"id":"systemd","label":"Systemd","rows":[
        {"id":"unit","label":"Unit name","value":"pgdata-volume.service"},
        {"id":"unit_state","label":"Unit state","value":"active"},
        {"id":"file","label":"File","value":"~/quadlets/shop.qdl-bundle/pgdata.volume"},
        {"id":"app","label":"App","value":"shop"}]})
    and ((.items[] | select(.id == "web-data") | .groups[1].rows) == [
        {"id":"unit","label":"Unit name","value":"web.service"},
        {"id":"unit_state","label":"Unit state","value":"active"},
        {"id":"file","label":"File","value":"~/quadlets/web.container"}])
    and ((.items[] | select(.id == $anon) | .groups[0].rows) == [{"id":"anonymous","label":"Anonymous","value":"Yes"}])
    and ([.items[] | select(has("quadlet")) | {(.id): .quadlet}] == [{"pgdata": {"name": "pgdata.volume", "app": "shop"}}])
' >/dev/null && cockpit-validate-contract "${volumes_contract}" "${volumes_out}"; then
    ok "volumes-list-stubbed"
else
    bad "volumes-list-stubbed" "${volumes_out}"
fi

# The unit states of each map come from one systemctl show call with all units.
if [[ "$(grep -c '^show ' "${WORK}/volumes-systemctl.log")" == "2" ]] \
    && grep -qx 'show -p ActiveState -p LoadState -p SourcePath -p FragmentPath -- db.service web.service' "${WORK}/volumes-systemctl.log"; then
    ok "volumes-list-one-systemctl-call"
else
    bad "volumes-list-one-systemctl-call" "$(cat "${WORK}/volumes-systemctl.log")"
fi

# cockpit-units-info: when the call for all units fails, each unit is read on its own, and a unit
# that cannot be read keeps its line with empty values.
units_info_runner() {
    while [[ "${1-}" != "--" && $# -gt 0 ]]; do shift; done
    shift
    [[ $# -eq 1 && "${1}" != "bad.service" ]] || return 1
    printf 'LoadState=loaded\nActiveState=active\nFragmentPath=/u/%s\n' "${1}"
}
# shellcheck source=/dev/null
source "${API}/fn/resources/cockpit-units-info.sh"
units_info_out="$(cockpit-units-info units_info_runner a.service bad.service b.service)"
[[ "${units_info_out}" == $'a.service\tactive\tloaded\t/u/a.service\nbad.service\t\t\t\nb.service\tactive\tloaded\t/u/b.service' ]]
expect_status "units-info-falls-back-per-unit" $? "${units_info_out}"

cockpit-volumes-list-du() {
    return 1
}
volumes_out="$(HOME="${vol_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${vol_home}/quadlets" cockpit-module-volumes-list)"
printf '%s' "${volumes_out}" | jq -e '(.items | length) == 4 and ([.items[].rows[] | select(.id == "size")] == [])' >/dev/null \
    && cockpit-validate-contract "${volumes_contract}" "${volumes_out}"
expect_status "volumes-list-du-fails" $? "${volumes_out}"

# A failed batch inspect falls back to one inspect per container: c1 keeps its volume, c3 is
# logged and left without volumes, so the anonymous volume only c3 mounts shows as unused.
vol_inspect_log="${WORK}/volumes-inspect.log"
: > "${vol_inspect_log}"
logger() { printf '%s\n' "$*" >> "${vol_inspect_log}"; }
cockpit-volumes-list-podman() {
    case "${1-} ${2-}" in
        "volume ls") printf '[{"Name":"pgdata"},{"Name":"%s"}]\n' "${vol_anon}" ;;
        "volume inspect")
            printf '[{"Name":"pgdata","Driver":"local","Mountpoint":"%s/vols/pgdata/_data","CreatedAt":"2026-10-28T11:15:00+02:00"},
                {"Name":"%s","Driver":"local","Mountpoint":"%s/vols/anon/_data","CreatedAt":"2026-11-10T21:03:00Z","Anonymous":true}]\n' "${vol_home}" "${vol_anon}" "${vol_home}"
            ;;
        "ps -a") printf '[{"Id":"c1","Names":["db"],"State":"running"},{"Id":"c3","Names":["db-backup"],"State":"exited"}]\n' ;;
        "container inspect")
            if [[ "${#}" -eq 4 && "${4}" == "c1" ]]; then
                printf '[{"Id":"c1","Mounts":[{"Type":"volume","Name":"pgdata","Destination":"/data"}]}]\n'
                return 0
            fi
            printf 'Error: no such container\n' >&2
            return 125
            ;;
        *) return 1 ;;
    esac
}
volumes_out="$(HOME="${vol_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${vol_home}/quadlets" cockpit-module-volumes-list)"
if printf '%s' "${volumes_out}" | jq -e --arg anon "${vol_anon}" '
    ([.items[] | {(.id): .status}] | add) == {($anon):"Unused","pgdata":"In use"}
    and ((.items[] | select(.id == "pgdata") | .rows[] | select(.id == "used-by") | .value) == "db (Running)")
' >/dev/null && cockpit-validate-contract "${volumes_contract}" "${volumes_out}" \
    && grep -q 'container inspect failed for c3: Error: no such container' "${vol_inspect_log}" \
    && ! grep -q 'failed for c1' "${vol_inspect_log}"; then
    ok "volumes-list-inspect-fallback"
else
    bad "volumes-list-inspect-fallback" "${volumes_out} $(cat "${vol_inspect_log}")"
fi
unset -f logger

cockpit-volumes-list-podman() {
    case "${1-} ${2-}" in
        "volume ls") printf '[]\n' ;;
        "ps -a") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
volumes_out="$(HOME="${WORK}/volumes-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/volumes-none" cockpit-module-volumes-list)"
expect_eq "volumes-list-empty" "${volumes_out}" '{"items":[]}'

cockpit-volumes-list-podman() {
    case "${1-} ${2-}" in
        "volume ls") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
if volumes_out="$(HOME="${WORK}/volumes-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/volumes-none" cockpit-module-volumes-list 2>/dev/null)"; then
    bad "volumes-list-ps-fails" "${volumes_out}"
else
    ok "volumes-list-ps-fails"
fi

cockpit-volumes-list-podman() {
    return 1
}
if volumes_out="$(HOME="${WORK}/volumes-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/volumes-none" cockpit-module-volumes-list 2>/dev/null)"; then
    bad "volumes-list-podman-fails" "${volumes_out}"
else
    ok "volumes-list-podman-fails"
fi

# volumes-list with podman JSON over 1 MB: more than Linux (128 KB) or macOS (1 MB) allows in one argument.
big_ps="${WORK}/volumes-big-ps.json"
big_ins="${WORK}/volumes-big-inspect.json"
jq -n -c '[range(0; 1500) | {Id: ("c" + tostring), Names: ["ctr" + tostring], State: "exited", Labels: null}]' > "${big_ps}"
jq -n -c '[range(0; 1500) | {Id: ("c" + tostring), Pad: ("x" * 800),
    Mounts: [{Type: "volume", Name: "big", Destination: "/data"}]}]' > "${big_ins}"
cockpit-volumes-list-podman() {
    case "${1-} ${2-}" in
        "volume ls") printf '[{"Name":"big"}]\n' ;;
        "volume inspect") printf '[{"Name":"big","Driver":"local","Mountpoint":"/vols/big/_data"}]\n' ;;
        "ps -a") cat "${big_ps}" ;;
        "container inspect") cat "${big_ins}" ;;
        *) return 1 ;;
    esac
}
cockpit-volumes-list-du() {
    return 124
}
volumes_out="$(HOME="${WORK}/volumes-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/volumes-none" cockpit-module-volumes-list 2>&1)"
if [[ "$(LC_ALL=C wc -c < "${big_ins}" | tr -d '[:space:]')" -gt 1048576 ]] \
    && printf '%s' "${volumes_out}" | jq -e '
        (.items | length) == 1
        and .items[0].id == "big"
        and .items[0].status == "In use"
        and ((.items[0].rows[] | select(.id == "used-by") | .value) | test("ctr0 \\(Exited\\)"))
    ' >/dev/null \
    && cockpit-validate-contract "${volumes_contract}" "${volumes_out}"; then
    ok "volumes-list-large-input"
else
    bad "volumes-list-large-input" "${volumes_out:0:300}"
fi

