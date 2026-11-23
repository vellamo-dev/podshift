#!/usr/bin/env bash
# @file: 160-containers.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: containers-list, the stats budget and the batch inspect fallback.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# containers-list: podman, systemctl and podman stats are stubbed; Quadlet .container files are real files.
ctr_home="${WORK}/containers-home"
ctr_stats_args="${WORK}/containers-stats.args"
mkdir -p "${ctr_home}/quadlets/shop.qdl-bundle"
printf '[Container]\nImage=postgres\n' > "${ctr_home}/quadlets/shop.qdl-bundle/db.container"
printf '[Container]\nImage=alpine\n' > "${ctr_home}/quadlets/unused.container"
ctr_db="1111111111111111111111111111111111111111111111111111111111111111"
ctr_backup="2222222222222222222222222222222222222222222222222222222222222222"
ctr_loose="3333333333333333333333333333333333333333333333333333333333333333"
cockpit-containers-list-podman() {
    case "${1-} ${2-}" in
        "ps -a")
            printf '[
                {"Id":"%s","Names":["db"],"Image":"docker.io/library/postgres:16","Command":["postgres"],"State":"running","Status":"Up 3 days","Labels":{"PODMAN_SYSTEMD_UNIT":"db.service","io.containers.autoupdate":"registry"},"Networks":["shop-net"],"Ports":[{"host_ip":"127.0.0.1","container_port":5432,"host_port":5432,"range":1,"protocol":"tcp"}]},
                {"Id":"%s","Names":["db-backup"],"Image":"docker.io/library/postgres:16","Command":["pg_dump"],"State":"exited","Status":"Exited (0) 5 hours ago","Labels":{"PODMAN_SYSTEMD_UNIT":"db-backup.service"},"Networks":[]},
                {"Id":"%s","Names":["loose"],"Image":"docker.io/library/alpine:latest","Command":["sleep","infinity"],"State":"running","Status":"Up 1 minute","Labels":{"io.containers.autoupdate":"registry"},"Networks":[]}
            ]\n' "${ctr_db}" "${ctr_backup}" "${ctr_loose}"
            ;;
        "container inspect")
            printf '[
                {"Id":"%s","Created":"2026-11-08T11:12:00.5+02:00","State":{"Status":"running","Health":{"Status":"healthy"}},"HostConfig":{"RestartPolicy":{"Name":""}},"Mounts":[{"Type":"volume","Name":"pgdata","Destination":"/var/lib/postgresql/data"}]},
                {"Id":"%s","Created":"2026-11-11T03:00:00Z","State":{"Status":"exited"},"HostConfig":{"NetworkMode":"pasta"},"Mounts":[{"Type":"bind","Source":"%s/backup","Destination":"/backup"}]},
                {"Id":"%s","Created":"2026-11-11T14:58:00Z","State":{"Status":"running"},"HostConfig":{"NetworkMode":"pasta"},"Mounts":[]}
            ]\n' "${ctr_db}" "${ctr_backup}" "${ctr_home}" "${ctr_loose}"
            ;;
        *)
            return 1
            ;;
    esac
}
cockpit-containers-list-systemctl() {
    local unit first
    first=1
    while [[ "${1-}" != "--" && $# -gt 0 ]]; do shift; done
    shift
    for unit in "$@"; do
        (( first == 1 )) || printf '\n'
        first=0
        case "${unit}" in
            db.service) printf 'ActiveState=active\nLoadState=loaded\nFragmentPath=/run/user/300/systemd/generator/db.service\nSourcePath=%s\n' "${ctr_home}/quadlets/shop.qdl-bundle/db.container" ;;
            db-backup.service) printf 'ActiveState=inactive\nLoadState=loaded\nFragmentPath=%s\n' "${ctr_home}/.config/systemd/user/db-backup.service" ;;
            *) printf 'ActiveState=inactive\nLoadState=not-found\n' ;;
        esac
    done
}
cockpit-containers-list-stats() {
    printf '%s\n' "${*}" > "${ctr_stats_args}"
    printf '[{"id":"%s","cpu_percent":"1.20%%","mem_usage":"84.2MB / 2.06GB"},{"id":"%s","cpu_percent":"0.00%%","mem_usage":"1.044MiB / 2GiB"}]\n' "${ctr_db:0:12}" "${ctr_loose:0:12}"
}
containers_out="$(HOME="${ctr_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${ctr_home}/quadlets" cockpit-module-containers-list)"
containers_contract="$(jq -c '.output' "${API}/modules/containers-list/capability.json")"
if printf '%s' "${containers_out}" | jq -e '
    ([.items[].title] == ["db","db-backup","loose"])
    and ([.items[] | {(.title): [.source, .status, .running]}] | add) == {"db":["quadlet","Running",true],"db-backup":["unit","Exited",false],"loose":["unmanaged","Running",true]}
    and ([.items[] | {(.title): [.autoUpdate, .autoUpdateActive]}] | add) == {"db":["registry",true],"db-backup":[null,null],"loose":["registry",false]}
    and ((.items[0].rows) == [
        {"id":"image","label":"Image","value":"docker.io/library/postgres:16"},
        {"id":"command","label":"Command","value":"postgres"},
        {"id":"state","label":"State","value":"Up 3 days"},
        {"id":"health","label":"Health","value":"Healthy"},
        {"id":"ports","label":"Ports","value":"127.0.0.1:5432 → 5432/tcp"},
        {"id":"created","label":"Created","value":"2026-11-08T09:12:00Z"}])
    and ((.items[0].groups) == [
        {"id":"details","label":"Details","rows":[
            {"id":"networks","label":"Networks","value":"shop-net"},
            {"id":"volumes","label":"Volumes","value":"pgdata → /var/lib/postgresql/data"},
            {"id":"auto-update","label":"Auto-update","value":"Registry"},
            {"id":"restart","label":"Restart policy","value":"no"},
            {"id":"cpu","label":"CPU","value":"1.20%"},
            {"id":"memory","label":"Memory","value":"84.2 MB"}]},
        {"id":"systemd","label":"Systemd","rows":[
            {"id":"unit","label":"Unit name","value":"db.service"},
            {"id":"unit_state","label":"Unit state","value":"active"},
            {"id":"file","label":"File","value":"~/quadlets/shop.qdl-bundle/db.container"},
            {"id":"app","label":"App","value":"shop"}]}])
    and ((.items[1].groups[0].rows[0:2]) == [
        {"id":"networks","label":"Networks","value":"pasta"},
        {"id":"volumes","label":"Volumes","value":"~/backup → /backup"}])
    and ([.items[1].groups[0].rows[].id] | index("cpu") == null)
    and ((.items[1].groups[1].rows) == [
        {"id":"unit","label":"Unit name","value":"db-backup.service"},
        {"id":"unit_state","label":"Unit state","value":"inactive"},
        {"id":"file","label":"File","value":"~/.config/systemd/user/db-backup.service"}])
    and ((.items[2].groups[0].rows[] | select(.id == "memory") | .value) == "1.09 MB")
    and ([.items[2].groups[].id] == ["details"])
    and ([.items[] | select(has("quadlet")) | {(.title): .quadlet}] == [{"db": {"name": "db.container", "app": "shop"}}])
' >/dev/null && cockpit-validate-contract "${containers_contract}" "${containers_out}" \
    && [[ "$(cat "${ctr_stats_args}")" == "5 ${ctr_db} ${ctr_loose}" ]]; then
    ok "containers-list-stubbed"
else
    bad "containers-list-stubbed" "${containers_out}"
fi

cockpit-containers-list-stats() {
    return 124
}
containers_out="$(HOME="${ctr_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${ctr_home}/quadlets" cockpit-module-containers-list)"
printf '%s' "${containers_out}" | jq -e '(.items | length) == 3 and ([.items[].groups[].rows[] | select(.id == "cpu" or .id == "memory")] == [])' >/dev/null \
    && cockpit-validate-contract "${containers_contract}" "${containers_out}"
expect_status "containers-list-stats-fails" $? "${containers_out}"

# The stats sample gets the seconds left, at most 5, and is skipped with less than 1 second left.
cockpit-containers-list-stats() {
    printf '%s\n' "${1-}" > "${ctr_stats_args}"
    printf '[]\n'
}
ctr_ps_running='[{"Id":"abc","State":"running"}]'
rm -f "${ctr_stats_args}"
usage_out="$(cockpit-containers-list-usage "${ctr_ps_running}" 0)"
[[ "${usage_out}" == "[]" && ! -e "${ctr_stats_args}" ]]
expect_status "containers-list-stats-no-time-left" $? "${usage_out}"
cockpit-containers-list-usage "${ctr_ps_running}" 3 >/dev/null
expect_eq "containers-list-stats-time-left" "$(cat "${ctr_stats_args}" 2>/dev/null)" "3"
cockpit-containers-list-usage "${ctr_ps_running}" 9 >/dev/null
expect_eq "containers-list-stats-at-most-5" "$(cat "${ctr_stats_args}" 2>/dev/null)" "5"

rm -f "${ctr_stats_args}"
cockpit-containers-list-stats() {
    printf 'called\n' > "${ctr_stats_args}"
    printf '[]\n'
}
cockpit-containers-list-podman() {
    case "${1-} ${2-}" in
        "ps -a") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
containers_out="$(HOME="${WORK}/containers-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/containers-none" cockpit-module-containers-list)"
[[ "${containers_out}" == '{"items":[]}' && ! -e "${ctr_stats_args}" ]]
expect_status "containers-list-empty" $? "${containers_out}"

# containers-list with podman JSON over 1 MB: more than Linux (128 KB) or macOS (1 MB) allows in one argument.
big_ps="${WORK}/containers-big-ps.json"
big_ins="${WORK}/containers-big-inspect.json"
jq -n -c '[range(0; 1500) | {Id: ("c" + tostring), Names: ["ctr" + tostring], Image: "busybox", State: "exited"}]' > "${big_ps}"
jq -n -c '[range(0; 1500) | {Id: ("c" + tostring), Pad: ("x" * 800), State: {Status: "exited"}}]' > "${big_ins}"
cockpit-containers-list-podman() {
    case "${1-} ${2-}" in
        "ps -a") cat "${big_ps}" ;;
        "container inspect") cat "${big_ins}" ;;
        *) return 1 ;;
    esac
}
containers_out="$(HOME="${WORK}/containers-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/containers-none" cockpit-module-containers-list 2>&1)"
if [[ "$(LC_ALL=C wc -c < "${big_ins}" | tr -d '[:space:]')" -gt 1048576 ]] \
    && printf '%s' "${containers_out}" | jq -e '
        (.items | length) == 1500
        and all(.items[]; .status == "Exited" and .running == false)
    ' >/dev/null \
    && cockpit-validate-contract "${containers_contract}" "${containers_out}"; then
    ok "containers-list-large-input"
else
    bad "containers-list-large-input" "${containers_out:0:300}"
fi

# A failed batch inspect falls back to one inspect per container: the ones that work keep their
# details, the others stay with the ps fields, and each failure is logged with its first stderr line.
ctr_other="4444444444444444444444444444444444444444444444444444444444444444"
inspect_log="${WORK}/containers-inspect.log"
: > "${inspect_log}"
logger() { printf '%s\n' "$*" >> "${inspect_log}"; }
cockpit-containers-list-podman() {
    case "${1-} ${2-}" in
        "ps -a") printf '[{"Id":"%s","Names":["x"],"State":"exited"},{"Id":"%s","Names":["y"],"State":"exited"}]\n' "${ctr_db}" "${ctr_other}" ;;
        "container inspect")
            if [[ "${#}" -eq 4 && "${4}" == "${ctr_other}" ]]; then
                printf '[{"Id":"%s","Created":"2026-11-11T03:00:00Z","State":{"Status":"exited"},"HostConfig":{"RestartPolicy":{"Name":"always"}}}]\n' "${ctr_other}"
                return 0
            fi
            printf 'Error: no such container\n' >&2
            return 125
            ;;
        *) return 1 ;;
    esac
}
if containers_out="$(HOME="${WORK}/containers-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/containers-none" cockpit-module-containers-list 2>/dev/null)" \
    && printf '%s' "${containers_out}" | jq -e '(.items | length) == 2 and ([.items[].title] | sort) == ["x", "y"]' >/dev/null \
    && grep -q 'container inspect failed for 111111111111: Error: no such container' "${inspect_log}" \
    && ! grep -q '444444444444' "${inspect_log}"; then
    ok "containers-list-inspect-fallback"
else
    bad "containers-list-inspect-fallback" "${containers_out} $(cat "${inspect_log}")"
fi
unset -f logger

cockpit-containers-list-podman() {
    return 1
}
if containers_out="$(HOME="${WORK}/containers-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/containers-none" cockpit-module-containers-list 2>/dev/null)"; then
    bad "containers-list-podman-fails" "${containers_out}"
else
    ok "containers-list-podman-fails"
fi

