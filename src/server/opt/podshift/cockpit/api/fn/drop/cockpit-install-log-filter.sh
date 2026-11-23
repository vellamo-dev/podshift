#!/usr/bin/env bash
# @file: cockpit-install-log-filter.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/drop
# @dest-dir: /opt/podshift/cockpit/api/fn/drop
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Keeps the journal lines of the Quadlet install log and drops systemd and Podman noise.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the journalctl -o json lines from stdin that belong in the install log, one per line.
# @details:
#   Lines that are not JSON objects, such as -- No entries --, are skipped. The input is read
#   twice (slurped): the first pass collects the units that PodShift installed or removed, the
#   second keeps the lines. A unit counts when a podshift-qdl-install line reads "queued start of
#   <unit>", or when a podshift-qdl-remove line (other than a "used by" refusal) names it: a word
#   ending in .service is taken as it is, and a Quadlet file name is turned into its unit as
#   get-quadlet-unit-name does (web.container and web.kube give web.service, web.pod gives
#   web-pod.service, and .network, .volume, .image and .build likewise). A systemd line is kept
#   only when its USER_UNIT is one of these units, so the user manager start, libpod scopes,
#   podshift-* and run-* units and units that PodShift did not install, such as the examples,
#   are left out. A podman line is kept only when MESSAGE has PODMAN_SYSTEMD_UNIT=<unit> (ended
#   by a comma or a closing bracket) for one of these units and its event is not health_status,
#   exec or exec_died. Lines with any other identifier, the pipeline tags, are kept as they are.
#   The order is unchanged. A unit started again later only shows while its install or removal
#   line is in the same input.
# @stdout: the kept journal lines as compact JSON, one per line.
# @exitcode: 0 when the lines were written, 1 when jq fails.
cockpit-install-log-filter() {
    jq -R -n -c '
        def str: if type == "string" then . else "" end;
        def unit_of:
            sub("^.*/"; "")
            | if test("^[^.].*\\.service$") then .
              elif test("^.+\\.(container|kube)$") then sub("\\.(container|kube)$"; ".service")
              elif test("^.+\\.(pod|network|volume|image|build)$") then
                  capture("^(?<s>.+)\\.(?<e>pod|network|volume|image|build)$") | "\(.s)-\(.e).service"
              else empty end;
        [inputs | select(startswith("{")) | (try fromjson catch empty) | objects] as $lines
        | ([$lines[]
            | (.SYSLOG_IDENTIFIER | str) as $id
            | (.MESSAGE | str) as $msg
            | if $id == "podshift-qdl-install" then ($msg | capture("^queued start of (?<u>\\S+)$").u)
              elif $id == "podshift-qdl-remove" and ($msg | contains("used by") | not) then
                  ($msg | scan("[^\\s:,()]+") | unit_of)
              else empty end
           ] | map({key: ., value: true}) | from_entries) as $units
        | $lines[]
        | (.SYSLOG_IDENTIFIER | str) as $id
        | (.USER_UNIT | str) as $unit
        | (.MESSAGE | str) as $msg
        | if $id == "systemd" then
            select($units[$unit] == true)
          elif $id == "podman" then
            select(any($msg | scan("PODMAN_SYSTEMD_UNIT=([^,)]+)")[0]; $units[.] == true)
                and ($msg | test("^[a-z]+ (health_status|exec|exec_died) ") | not))
          else . end
    ' 2>/dev/null
}
