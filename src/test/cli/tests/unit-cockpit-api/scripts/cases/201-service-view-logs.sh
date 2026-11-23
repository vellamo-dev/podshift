#!/usr/bin/env bash
# @file: 201-service-view-logs.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: service-view and service-logs at module level.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# Own call log in the run folder, so the mocks never write outside ${WORK}.
svc_calls="${WORK}/services.calls"

# service-view: SVC_RC is the exit code of cat or status, SVC_TEXT the text they print.
cockpit-service-view-systemctl() {
    printf '%s\n' "$*" >> "${svc_calls}"
    case "${1-}" in
        list-units) printf '%s' "${svc_units}" ;;
        cat|status)
            printf '%s' "${SVC_TEXT-}"
            return "${SVC_RC:-0}"
            ;;
        *) return 1 ;;
    esac
}

: > "${svc_calls}"
view_out="$(SVC_TEXT=$'# /run/user/300/systemd/generator/web.service\n[Unit]\nDescription=Web\n' cockpit-module-service-view '{"unit":"web.service","mode":"unit"}')"
if printf '%s' "${view_out}" | jq -e '.found == true and .mode == "unit" and .text == "# /run/user/300/systemd/generator/web.service\n[Unit]\nDescription=Web\n"' >/dev/null \
    && cockpit-validate-contract "${view_contract}" "${view_out}" && grep -q -- '^cat -- web.service$' "${svc_calls}"; then
    ok "service-view-unit"
else
    bad "service-view-unit" "${view_out} calls $(tr '\n' ';' < "${svc_calls}")"
fi

: > "${svc_calls}"
view_out="$(SVC_RC=3 SVC_TEXT=$'○ old.service - Old\n     Active: inactive (dead)\n' cockpit-module-service-view '{"unit":"old.service","mode":"status"}')"
printf '%s' "${view_out}" | jq -e '.found == true and .mode == "status" and (.text | startswith("○ old.service"))' >/dev/null \
    && grep -q -- '^status --no-pager --full --lines=10 -- old.service$' "${svc_calls}"
expect_status "service-view-inactive-status-exit-3" $? "${view_out}"

view_out="$(SVC_RC=4 cockpit-module-service-view '{"unit":"web.service","mode":"status"}')"
expect_eq "service-view-status-exit-4" "${view_out}" '{"unit":"web.service","mode":"status","found":false}'

: > "${svc_calls}"
view_out="$(cockpit-module-service-view '{"unit":"missing.service","mode":"unit"}')"
[[ "${view_out}" == '{"unit":"missing.service","mode":"unit","found":false}' ]] && ! grep -q '^cat' "${svc_calls}"
expect_status "service-view-unknown-unit" $? "${view_out}"

: > "${svc_calls}"
if view_out="$(cockpit-module-service-view '{"unit":"../web.service","mode":"unit"}' 2>/dev/null)" || [[ -s "${svc_calls}" ]]; then
    bad "service-view-bad-name" "${view_out}"
else
    ok "service-view-bad-name"
fi

if view_out="$(SVC_RC=1 cockpit-module-service-view '{"unit":"web.service","mode":"unit"}' 2>/dev/null)"; then
    bad "service-view-cat-fails" "${view_out}"
else
    ok "service-view-cat-fails"
fi

if view_out="$(SVC_RC=1 cockpit-module-service-view '{"unit":"web.service","mode":"status"}' 2>/dev/null)"; then
    bad "service-view-status-fails" "${view_out}"
else
    ok "service-view-status-fails"
fi

view_out="$(SVC_TEXT="$(head -c 140000 /dev/zero | tr '\0' 'x')" cockpit-module-service-view '{"unit":"web.service","mode":"unit"}')"
if [[ "${view_out}" == '{"unit":"web.service","mode":"unit","found":true,"tooLarge":true,"size":140000}' ]] \
    && cockpit-validate-contract "${view_contract}" "${view_out}"; then
    ok "service-view-limit"
else
    bad "service-view-limit" "$(printf '%s' "${view_out}" | head -c 200)"
fi

# service-logs: SVC_JOURNAL is printed by journalctl, SVC_JOURNAL_ERR on stderr, SVC_JOURNAL_RC is its exit code.
# service-logs runs as root: the UID comes from id -u podshift (SVC_UID, or SVC_UID_RC to fail),
# and systemctl gets the UID first, for --machine=<uid>@.host.
cockpit-service-logs-uid() {
    [[ "${SVC_UID_RC:-0}" -eq 0 ]] || return "${SVC_UID_RC}"
    printf '%s\n' "${SVC_UID:-300}"
}
cockpit-service-logs-systemctl() {
    printf '%s\n' "$*" >> "${svc_calls}.systemctl"
    case "${2-}" in
        list-units) printf '%s' "${svc_units}" ;;
        *) return 1 ;;
    esac
}
cockpit-service-logs-journalctl() {
    printf '%s\n' "$*" >> "${svc_calls}"
    printf '%s' "${SVC_JOURNAL-}"
    printf '%s' "${SVC_JOURNAL_ERR-}" >&2
    return "${SVC_JOURNAL_RC:-0}"
}

: > "${svc_calls}"
logs_out="$(SVC_JOURNAL=$'{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"3","SYSLOG_IDENTIFIER":"web","_PID":"12","_HOSTNAME":"podshift","MESSAGE":"boom"}\n' cockpit-module-service-logs '{"unit":"web.service"}')"
if printf '%s' "${logs_out}" | jq -e '.found == true and .readable == true and .entries == [{"time":"2026-11-12T09:02:14Z","hostname":"podshift","identifier":"web","priority":3,"message":"boom","pid":12}]' >/dev/null \
    && cockpit-validate-contract "${logs_contract}" "${logs_out}" \
    && [[ "$(cat "${svc_calls}")" == "-n 100 -o json --no-pager _SYSTEMD_USER_UNIT=web.service _UID=300 + USER_UNIT=web.service _UID=300 + OBJECT_SYSTEMD_USER_UNIT=web.service _UID=300" ]] \
    && grep -q -- '^300 list-units --type=service --all ' "${svc_calls}.systemctl" \
    && ! grep -q -- '--user-unit' "${svc_calls}"; then
    ok "service-logs-module"
else
    bad "service-logs-module" "${logs_out} calls $(tr '\n' ';' < "${svc_calls}")"
fi

logs_out="$(SVC_JOURNAL=$'-- No entries --\n' cockpit-module-service-logs '{"unit":"old.service"}')"
expect_eq "service-logs-empty" "${logs_out}" '{"unit":"old.service","found":true,"readable":true,"entries":[]}'

: > "${svc_calls}"
logs_out="$(cockpit-module-service-logs '{"unit":"missing.service"}')"
[[ "${logs_out}" == '{"unit":"missing.service","found":false}' ]] && [[ ! -s "${svc_calls}" ]]
expect_status "service-logs-unknown-unit" $? "${logs_out}"

: > "${svc_calls}"
rm -f "${svc_calls}.systemctl"
if logs_out="$(SVC_UID_RC=1 cockpit-module-service-logs '{"unit":"web.service"}' 2>/dev/null)" || [[ -s "${svc_calls}" || -s "${svc_calls}.systemctl" ]]; then
    bad "service-logs-no-podshift-uid" "${logs_out}"
else
    ok "service-logs-no-podshift-uid"
fi

: > "${svc_calls}"
if logs_out="$(SVC_UID=podshift cockpit-module-service-logs '{"unit":"web.service"}' 2>/dev/null)" || [[ -s "${svc_calls}" ]]; then
    bad "service-logs-bad-podshift-uid" "${logs_out}"
else
    ok "service-logs-bad-podshift-uid"
fi

: > "${svc_calls}"
logs_out="$(SVC_UID=1001 SVC_JOURNAL=$'-- No entries --\n' cockpit-module-service-logs '{"unit":"web.service"}')"
if [[ "${logs_out}" == '{"unit":"web.service","found":true,"readable":true,"entries":[]}' ]] \
    && grep -q -- ' _SYSTEMD_USER_UNIT=web.service _UID=1001 + USER_UNIT=web.service _UID=1001 + OBJECT_SYSTEMD_USER_UNIT=web.service _UID=1001$' "${svc_calls}" \
    && grep -q -- '^1001 list-units ' "${svc_calls}.systemctl"; then
    ok "service-logs-uid-from-id"
else
    bad "service-logs-uid-from-id" "${logs_out} calls $(tr '\n' ';' < "${svc_calls}")"
fi

: > "${svc_calls}"
if logs_out="$(cockpit-module-service-logs '{"unit":"web"}' 2>/dev/null)" || [[ -s "${svc_calls}" ]]; then
    bad "service-logs-bad-name" "${logs_out}"
else
    ok "service-logs-bad-name"
fi

logs_out="$(cockpit-module-service-logs '{"unit":"old.service"}')"
[[ "${logs_out}" == '{"unit":"old.service","found":true,"readable":true,"entries":[]}' ]] \
    && cockpit-validate-contract "${logs_contract}" "${logs_out}"
expect_status "service-logs-no-output" $? "${logs_out}"

logs_out="$(SVC_JOURNAL_RC=1 SVC_JOURNAL=$'-- No entries --\n' cockpit-module-service-logs '{"unit":"old.service"}')"
expect_eq "service-logs-no-entries-exit-1" "${logs_out}" '{"unit":"old.service","found":true,"readable":true,"entries":[]}'

logs_out="$(SVC_JOURNAL_RC=1 SVC_JOURNAL_ERR=$'No journal files were found.\n' cockpit-module-service-logs '{"unit":"web.service"}')"
expect_eq "service-logs-no-files" "${logs_out}" '{"unit":"web.service","found":true,"readable":true,"entries":[]}'

logs_out="$(SVC_JOURNAL_RC=1 SVC_JOURNAL_ERR=$'Hint: You are currently not seeing messages from other users and the system.\n' cockpit-module-service-logs '{"unit":"web.service"}')"
expect_eq "service-logs-exit-1-hint" "${logs_out}" '{"unit":"web.service","found":true,"readable":true,"entries":[]}'

logs_out="$(SVC_JOURNAL_ERR=$'No journal files were opened due to insufficient permissions.\n' cockpit-module-service-logs '{"unit":"web.service"}')"
[[ "${logs_out}" == '{"unit":"web.service","found":true,"readable":false,"error":"JOURNAL_UNREADABLE","reason":"No journal files were opened due to insufficient permissions.","entries":[]}' ]] \
    && cockpit-validate-contract "${logs_contract}" "${logs_out}"
expect_status "service-logs-no-permission" $? "${logs_out}"

logs_out="$(SVC_JOURNAL_RC=1 SVC_JOURNAL_ERR=$'Failed to open\t/var/log/journal/x/user-300.journal: Permission denied\nHint: more\n' cockpit-module-service-logs '{"unit":"web.service"}')"
[[ "${logs_out}" == '{"unit":"web.service","found":true,"readable":false,"error":"JOURNAL_UNREADABLE","reason":"Failed to open /var/log/journal/x/user-300.journal: Permission denied","entries":[]}' ]] \
    && cockpit-validate-contract "${logs_contract}" "${logs_out}"
expect_status "service-logs-permission-denied" $? "${logs_out}"

logs_out="$(SVC_JOURNAL=$'{"__REALTIME_TIMESTAMP":"1794474134000000","MESSAGE":"kept"}\n' SVC_JOURNAL_ERR=$'Failed to open /x: Permission denied\n' cockpit-module-service-logs '{"unit":"web.service"}')"
printf '%s' "${logs_out}" | jq -e '.readable == true and (.entries | length) == 1 and .entries[0].message == "kept"' >/dev/null
expect_status "service-logs-partial-permission" $? "${logs_out}"

# 100 entries of 1024 quote characters do not fit in 131072 bytes as JSON, so fewer are kept.
svc_big="$(for i in $(seq 1 100); do jq -n -c --argjson i "${i}" '{__REALTIME_TIMESTAMP: ((1794474000 + $i) * 1000000 | tostring), MESSAGE: ("\"" * 1200)}'; done)"
logs_out="$(SVC_JOURNAL="${svc_big}" cockpit-module-service-logs '{"unit":"web.service"}')"
logs_bytes="$(printf '%s\n' "${logs_out}" | LC_ALL=C wc -c | tr -d '[:space:]')"
if (( logs_bytes <= 131072 )) && printf '%s' "${logs_out}" | jq -e '(.entries | length) == 50 and .entries[49].time == "2026-11-12T09:01:40Z"' >/dev/null \
    && cockpit-validate-contract "${logs_contract}" "${logs_out}"; then
    ok "service-logs-limit"
else
    bad "service-logs-limit" "bytes ${logs_bytes} entries $(printf '%s' "${logs_out}" | jq '.entries | length')"
fi

