#!/usr/bin/env bash
# @file: 420-drop-history.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: quadlet-drop-history and quadlet-install-log.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# quadlet-drop-history and quadlet-install-log: journalctl and the UID are stubbed in this process.
load_module quadlet-drop-history
load_module quadlet-install-log
hist_contract="$(jq -c '.output' "${API}/modules/quadlet-drop-history/capability.json")"
ilog_contract="$(jq -c '.output' "${API}/modules/quadlet-install-log/capability.json")"
hist_calls="${WORK}/drop-journal-calls"
cockpit-quadlet-drop-history-uid() { printf '300\n'; }
cockpit-quadlet-install-log-uid() { printf '300\n'; }
cockpit-quadlet-drop-history-journalctl() {
    printf '%s\n' "$*" >> "${hist_calls}"
    printf '%s' "${DROP_JOURNAL-}"
    printf '%s' "${DROP_JOURNAL_ERR-}" >&2
    return 0
}
cockpit-quadlet-install-log-journalctl() {
    printf '%s\n' "$*" >> "${hist_calls}"
    printf '%s' "${DROP_JOURNAL-}"
    printf '%s' "${DROP_JOURNAL_ERR-}" >&2
    return 0
}
hist_rec() {
    jq -n -c --arg t "${1}000000" --arg m "${2}" '{__REALTIME_TIMESTAMP: $t, SYSLOG_IDENTIFIER: "podshift-drop-history", MESSAGE: $m}'
}

: > "${hist_calls}"
hist_journal="$(hist_rec 1794474090 '{"name":"web.container","status":"installed"}'; hist_rec 1794474100 '{"id":"018bcfe5-6800-7012-b456-789abcdef012","name":"web.container","status":"accepted","description":"Web"}'; hist_rec 1794474134 '{"id":"018bcfe5-6800-7012-b456-789abcdef012","name":"web.container","status":"installed"}')"
hist_out="$(DROP_JOURNAL="${hist_journal}" cockpit-module-quadlet-drop-history '{}')"
if [[ "${hist_out}" == '{"readable":true,"items":[{"id":"018bcfe5-6800-7012-b456-789abcdef012","name":"web.container","status":"installed","time":"2026-11-12T09:02:14Z","description":"Web"}]}' ]] \
    && cockpit-validate-contract "${hist_contract}" "${hist_out}" \
    && [[ "$(cat "${hist_calls}")" == "-n 1000 -o json --no-pager SYSLOG_IDENTIFIER=podshift-drop-history _UID=300" ]]; then
    ok "quadlet-drop-history-module"
else
    bad "quadlet-drop-history-module" "${hist_out} calls $(cat "${hist_calls}")"
fi
hist_out="$(DROP_JOURNAL=$'-- No entries --\n' cockpit-module-quadlet-drop-history '{}')"
expect_eq "quadlet-drop-history-empty" "${hist_out}" '{"readable":true,"items":[]}'
hist_out="$(DROP_JOURNAL="" DROP_JOURNAL_ERR=$'No journal files were opened due to insufficient permissions.\n' cockpit-module-quadlet-drop-history '{}')"
printf '%s' "${hist_out}" | jq -e '.readable == false and .error == "JOURNAL_UNREADABLE" and .items == [] and (.reason | length) > 0' >/dev/null \
    && cockpit-validate-contract "${hist_contract}" "${hist_out}"
expect_status "quadlet-drop-history-unreadable" $? "${hist_out}"
# The largest records: 150 drops with names of 255 characters and reason and description of 200 characters.
hist_long="$(printf 'r%.0s' {1..300})"
hist_journal="$(for hist_i in $(seq 1 150); do hist_rec "$((1794474000 + hist_i))" "$(jq -n -c --arg n "$(printf '%03d' "${hist_i}")$(printf 'n%.0s' {1..300}).container" --arg id "$(printf '018bcfe5-6800-7000-8000-%012d' "${hist_i}")" --arg r "${hist_long}" '{id: $id, name: $n, status: "failed", reason: $r, description: $r}')"; done)"
hist_out="$(DROP_JOURNAL="${hist_journal}" cockpit-module-quadlet-drop-history '{}')"
hist_bytes="$(printf '%s\n' "${hist_out}" | LC_ALL=C wc -c | tr -d '[:space:]')"
[[ "${hist_bytes}" -le 131072 ]] && printf '%s' "${hist_out}" | jq -e '(.items | length) == 100 and (.items[0].name | startswith("150")) and (.items[0].name | length) == 255' >/dev/null \
    && cockpit-validate-contract "${hist_contract}" "${hist_out}"
expect_status "quadlet-drop-history-bounded" $? "bytes ${hist_bytes}"

: > "${hist_calls}"
ilog_journal="$(printf '%s\n' \
    '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"podshift-drop-process","_PID":"7","_HOSTNAME":"podshift","MESSAGE":"accepted web.container into validation-queue"}' \
    '{"__REALTIME_TIMESTAMP":"1794474135000000","PRIORITY":"4","SYSLOG_IDENTIFIER":"podshift-qdl-install","_HOSTNAME":"podshift","MESSAGE":"failed to install web.container"}')"
ilog_out="$(DROP_JOURNAL="${ilog_journal}" cockpit-module-quadlet-install-log '{}')"
if [[ "${ilog_out}" == '{"readable":true,"entries":[{"time":"2026-11-12T09:02:14Z","hostname":"podshift","identifier":"podshift-drop-process","priority":6,"message":"accepted web.container into validation-queue","pid":7},{"time":"2026-11-12T09:02:15Z","hostname":"podshift","identifier":"podshift-qdl-install","priority":4,"message":"failed to install web.container"}]}' ]] \
    && cockpit-validate-contract "${ilog_contract}" "${ilog_out}" \
    && [[ "$(cat "${hist_calls}")" == "-n 2000 -p info -o json --output-fields=SYSLOG_IDENTIFIER,_COMM,USER_UNIT,PRIORITY,MESSAGE,_PID,SYSLOG_PID,_HOSTNAME --no-pager SYSLOG_IDENTIFIER=podshift-drop-process _UID=300 + SYSLOG_IDENTIFIER=podshift-qdl-validate _UID=300 + SYSLOG_IDENTIFIER=podshift-qdl-install _UID=300 + SYSLOG_IDENTIFIER=podshift-qdl-remove _UID=300 + SYSLOG_IDENTIFIER=systemd _UID=300 + SYSLOG_IDENTIFIER=podman _UID=300" ]]; then
    ok "quadlet-install-log-module"
else
    bad "quadlet-install-log-module" "${ilog_out} calls $(cat "${hist_calls}")"
fi
# systemd and Podman lines of units that PodShift started or removed stay; other units (the examples,
# libpod scopes, podshift and run units), unit-less systemd lines and image pulls go.
ilog_journal="$(printf '%s\n' \
    '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"podshift-qdl-install","MESSAGE":"installed boy.container"}' \
    '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"podshift-qdl-install","MESSAGE":"queued start of boy.service"}' \
    '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"systemd","USER_UNIT":"example-container.service","MESSAGE":"Started example-container.service"}' \
    '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"systemd","USER_UNIT":"libpod-2c6f.scope","MESSAGE":"Started libpod-2c6f.scope - libcrun container."}' \
    '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"systemd","USER_UNIT":"podshift-api-1-2.service","MESSAGE":"Started podshift-api-1-2.service"}' \
    '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"systemd","USER_UNIT":"run-p1-i2.service","MESSAGE":"Started run-p1-i2.service"}' \
    '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"systemd","MESSAGE":"Reloading..."}' \
    '{"__REALTIME_TIMESTAMP":"1794474135000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"podman","MESSAGE":"container start 2c6f (image=docker.io/library/busybox:latest, name=boy, PODMAN_SYSTEMD_UNIT=boy.service)"}' \
    '{"__REALTIME_TIMESTAMP":"1794474135000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"podman","MESSAGE":"image pull d248 docker.io/library/busybox:latest"}' \
    '{"__REALTIME_TIMESTAMP":"1794474136000000","PRIORITY":"4","SYSLOG_IDENTIFIER":"systemd","USER_UNIT":"boy.service","MESSAGE":"boy.service: Failed with result '\''exit-code'\''."}' \
    '{"__REALTIME_TIMESTAMP":"1794474137000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"podshift-qdl-remove","MESSAGE":"removing web.container"}' \
    '{"__REALTIME_TIMESTAMP":"1794474138000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"systemd","USER_UNIT":"web.service","MESSAGE":"Stopped web.service"}')"
ilog_out="$(DROP_JOURNAL="${ilog_journal}" cockpit-module-quadlet-install-log '{}')"
printf '%s' "${ilog_out}" | jq -e '[.entries[] | .identifier] == ["podshift-qdl-install", "podshift-qdl-install", "podman", "systemd", "podshift-qdl-remove", "systemd"] and .entries[3].message == "boy.service: Failed with result \u0027exit-code\u0027." and .entries[3].priority == 4 and .entries[5].message == "Stopped web.service"' >/dev/null \
    && cockpit-validate-contract "${ilog_contract}" "${ilog_out}"
expect_status "quadlet-install-log-units" $? "${ilog_out}"
ilog_out="$(DROP_JOURNAL="" DROP_JOURNAL_ERR=$'Permission denied\n' cockpit-module-quadlet-install-log '{}')"
printf '%s' "${ilog_out}" | jq -e '.readable == false and .error == "JOURNAL_UNREADABLE" and .entries == []' >/dev/null \
    && cockpit-validate-contract "${ilog_contract}" "${ilog_out}"
expect_status "quadlet-install-log-unreadable" $? "${ilog_out}"
ilog_msg="$(printf 'm%.0s' {1..5000})"
ilog_journal="$(for ilog_i in $(seq 1 150); do jq -n -c --arg t "$((1794474000 + ilog_i))000000" --arg m "${ilog_msg}" '{__REALTIME_TIMESTAMP: $t, PRIORITY: "6", SYSLOG_IDENTIFIER: "podshift-qdl-install", _HOSTNAME: "podshift", MESSAGE: $m}'; done)"
ilog_out="$(DROP_JOURNAL="${ilog_journal}" cockpit-module-quadlet-install-log '{}')"
ilog_bytes="$(printf '%s\n' "${ilog_out}" | LC_ALL=C wc -c | tr -d '[:space:]')"
[[ "${ilog_bytes}" -le 131072 ]] && printf '%s' "${ilog_out}" | jq -e '(.entries | length) == 100' >/dev/null \
    && cockpit-validate-contract "${ilog_contract}" "${ilog_out}"
expect_status "quadlet-install-log-bounded" $? "bytes ${ilog_bytes}"
unset -f cockpit-quadlet-drop-history-uid cockpit-quadlet-install-log-uid cockpit-quadlet-drop-history-journalctl cockpit-quadlet-install-log-journalctl
rm -f "${hist_calls}"

# Both run in the root realm: the handler runs the real modules with id and journalctl stubbed on PATH.
drop_bin="${WORK}/drop-journal-bin"
mkdir -p "${drop_bin}"
cat > "${drop_bin}/id" <<'STUB'
#!/usr/bin/env bash
[[ "$*" == "-u podshift" ]] && { echo 300; exit 0; }
exit 1
STUB
cat > "${drop_bin}/journalctl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"6","SYSLOG_IDENTIFIER":"podshift-drop-history","_HOSTNAME":"podshift","MESSAGE":"{\"id\":\"018bcfe5-6800-7012-b456-789abcdef012\",\"name\":\"web.container\",\"status\":\"accepted\"}"}'
STUB
chmod 755 "${drop_bin}/id" "${drop_bin}/journalctl"
for drop_action in quadlet-drop-history quadlet-install-log; do
    reset_mocks
    PATH="${drop_bin}:${PATH}" run_serve "{\"apiVersion\":1,\"action\":\"${drop_action}\",\"args\":{}}"
    if expect_code "${drop_action}-root-handler" "OK"; then
        [[ "$(field '.data.readable')" == "true" ]] && ! grep -q 'cockpit-run-in-session' "${ARGV}" 2>/dev/null
        expect_status "${drop_action}-root-handler" $? "${LAST_OUT}"
    fi
done
rm -rf "${drop_bin}"



