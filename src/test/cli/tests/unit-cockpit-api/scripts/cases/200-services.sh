#!/usr/bin/env bash
# @file: 200-services.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: services-list and the handler runs of service-logs.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# --- services-list, service-view, service-logs ---
# The handler passes args to the session; a bad unit name never reaches it.
reset_mocks
MODE="emit"
EMIT='{"items":[{"id":"web.service","title":"web.service","subtitle":"Web","source":"quadlet","activeState":"active","subState":"running","since":"2026-11-12T09:02:14Z","unitFileState":"generated","path":"/run/user/300/systemd/generator/web.service","quadletFile":"/home/podshift/.config/containers/systemd/web.container","quadletKind":"container","mainPid":12,"memory":1024}]}'
run_serve '{"apiVersion":1,"action":"services-list","args":{}}'
if expect_code "services-list-mock-session" "OK"; then
    if [[ "$(field '.data.items[0].quadletKind')" == "container" ]] && grep -q 'cockpit-run-in-session.sh services-list ' "${ARGV}"; then
        ok "services-list-mock-session"
    else
        bad "services-list-mock-session" "${LAST_OUT} argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"items":[{"id":"web.service","title":"web.service"}]}'
run_serve '{"apiVersion":1,"action":"services-list","args":{}}'
expect_code "services-list-output-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "services-list-output-contract"

reset_mocks
MODE="emit"
EMIT='{"items":[{"id":"web.container","title":"web","type":"container","unitName":"web.service","path":"/home/podshift/.config/containers/systemd/web.container","status":"active/running","app":"","pod":"","description":"Web"}]}'
run_serve '{"apiVersion":1,"action":"quadlets-list","args":{}}'
if expect_code "quadlets-list-mock-session" "OK"; then
    if [[ "$(field '.data.items[0].title')" == "web" ]] && grep -q 'cockpit-run-in-session.sh quadlets-list ' "${ARGV}"; then
        ok "quadlets-list-mock-session"
    else
        bad "quadlets-list-mock-session" "${LAST_OUT} argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"items":[{"id":"web.container","title":"web"}]}'
run_serve '{"apiVersion":1,"action":"quadlets-list","args":{}}'
expect_code "quadlets-list-output-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "quadlets-list-output-contract"


reset_mocks
MODE="emit"
EMIT='{"unit":"web.service","mode":"status","found":true,"text":"● web.service - Web\n"}'
run_serve '{"apiVersion":1,"action":"service-view","args":{"unit":"web.service","mode":"status"}}'
if expect_code "service-view-mock-session" "OK"; then
    if [[ "$(field '.data.found')" == "true" && "$(field '.request.args.unit')" == "web.service" ]] && grep -q 'cockpit-run-in-session.sh service-view ' "${ARGV}" && grep -q 'web.service' "${STDIN}" && ! grep -q 'web.service' "${ARGV}"; then
        ok "service-view-mock-session"
    else
        bad "service-view-mock-session" "${LAST_OUT} argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"unit":"web.service","found":true,"quadlet":true,"name":"web.container","path":"/home/podshift/.config/containers/systemd/web.container","kind":"container","text":"[Container]\nImage=nginx\n"}'
run_serve '{"apiVersion":1,"action":"quadlet-view","args":{"unit":"web.service"}}'
if expect_code "quadlet-view-mock-session" "OK"; then
    if [[ "$(field '.data.name')" == "web.container" && "$(field '.request.args.unit')" == "web.service" ]] && grep -q 'cockpit-run-in-session.sh quadlet-view ' "${ARGV}" && grep -q 'web.service' "${STDIN}" && ! grep -q 'web.service' "${ARGV}"; then
        ok "quadlet-view-mock-session"
    else
        bad "quadlet-view-mock-session" "${LAST_OUT} argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"unit":"web.service","found":true,"quadlet":true,"error":"SECRET_LEAK"}'
run_serve '{"apiVersion":1,"action":"quadlet-view","args":{"unit":"web.service"}}'
expect_code "quadlet-view-output-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "quadlet-view-output-contract"


# service-logs is root realm: the handler runs the real module in this process, with id,
# systemctl and journalctl stubbed on PATH. No podshift session is entered.
reset_mocks
svc_bin="${WORK}/service-logs-bin"
mkdir -p "${svc_bin}"
cat > "${svc_bin}/id" <<'STUB'
#!/usr/bin/env bash
[[ "$*" == "-u podshift" ]] && { echo 300; exit 0; }
exit 1
STUB
cat > "${svc_bin}/systemctl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${SVC_ROOT_LOG}.systemctl"
[[ "$1" == "--machine=300@.host" && "$2" == "--user" && "$3" == "list-units" ]] || exit 1
printf 'web.service loaded active running Web\n'
STUB
cat > "${svc_bin}/journalctl" <<'STUB'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${SVC_ROOT_LOG}.journalctl"
printf '%s\n' '{"__REALTIME_TIMESTAMP":"1794474134000000","PRIORITY":"4","SYSLOG_IDENTIFIER":"web","_HOSTNAME":"podshift","MESSAGE":"root read"}'
STUB
chmod 755 "${svc_bin}/id" "${svc_bin}/systemctl" "${svc_bin}/journalctl"
export SVC_ROOT_LOG="${WORK}/service-logs-root"
rm -f "${SVC_ROOT_LOG}.systemctl" "${SVC_ROOT_LOG}.journalctl"
PATH="${svc_bin}:${PATH}" run_serve '{"apiVersion":1,"action":"service-logs","args":{"unit":"web.service"}}'
if expect_code "service-logs-root-handler" "OK"; then
    if printf '%s' "$(field '.data')" | jq -e '.found == true and .readable == true and .entries == [{"time":"2026-11-12T09:02:14Z","hostname":"podshift","identifier":"web","priority":4,"message":"root read"}]' >/dev/null \
        && [[ "$(cat "${SVC_ROOT_LOG}.journalctl" 2>/dev/null)" == "-n 100 -o json --no-pager _SYSTEMD_USER_UNIT=web.service _UID=300 + USER_UNIT=web.service _UID=300 + OBJECT_SYSTEMD_USER_UNIT=web.service _UID=300" ]] \
        && grep -q -- '^--machine=300@.host --user list-units ' "${SVC_ROOT_LOG}.systemctl" \
        && ! grep -q 'cockpit-run-in-session' "${ARGV}" 2>/dev/null; then
        ok "service-logs-root-handler"
    else
        bad "service-logs-root-handler" "${LAST_OUT} journalctl $(cat "${SVC_ROOT_LOG}.journalctl" 2>/dev/null) systemctl $(cat "${SVC_ROOT_LOG}.systemctl" 2>/dev/null) argv $(cat "${ARGV}" 2>/dev/null)"
    fi
fi
rm -rf "${svc_bin}" "${SVC_ROOT_LOG}.systemctl" "${SVC_ROOT_LOG}.journalctl"
unset SVC_ROOT_LOG

long_unit="$(printf 'a%.0s' {1..250}).service"
svc_bad_n=0
for svc_case in \
    'service-view|{"unit":"web.socket","mode":"unit"}|unit' \
    'service-view|{"unit":"-web.service","mode":"unit"}|unit' \
    'service-view|{"unit":"../web.service","mode":"unit"}|unit' \
    'service-view|{"unit":"a b.service","mode":"unit"}|unit' \
    'service-view|{"unit":"a;b.service","mode":"unit"}|unit' \
    'service-view|{"unit":"a$(id).service","mode":"unit"}|unit' \
    "service-view|{\"unit\":\"${long_unit}\",\"mode\":\"unit\"}|unit" \
    'service-view|{"unit":"web.service","mode":"logs"}|mode' \
    'service-view|{"unit":"web.service"}|mode' \
    'service-view|{"unit":"web.service","mode":"unit","follow":true}|follow' \
    'service-logs|{"unit":"web"}|unit' \
    'service-logs|{"unit":""}|unit' \
    'service-logs|{"unit":"web.service","mode":"unit"}|mode' \
    'service-logs|{}|unit' \
    'quadlet-view|{"unit":"web"}|unit' \
    'quadlet-view|{"unit":"web.service","mode":"unit"}|mode' \
    'quadlet-view|{}|unit'; do
    svc_action="${svc_case%%|*}"
    svc_rest="${svc_case#*|}"
    svc_args="${svc_rest%|*}"
    svc_want="Given arguments are not supported: ${svc_rest##*|}."
    svc_bad_n=$((svc_bad_n + 1))
    reset_mocks
    MODE="emit"
    EMIT='{"unit":"web.service","found":false}'
    run_serve "{\"apiVersion\":1,\"action\":\"${svc_action}\",\"args\":${svc_args}}"
    if expect_code "services-bad-name-${svc_bad_n}" "INVALID_ARGS"; then
        if [[ ! -s "${ARGV}" && "$(field '.status.message')" == "${svc_want}" ]]; then
            ok "services-bad-name-${svc_bad_n}"
        else
            bad "services-bad-name-${svc_bad_n}" "${svc_args}: $(field '.status.message')"
        fi
    fi
done

# Module level: systemctl and journalctl are stubbed. Calls are recorded, one per line.
svc_calls="${WORK}/services.calls"
services_contract="$(jq -c '.output' "${API}/modules/services-list/capability.json")"
view_contract="$(jq -c '.output' "${API}/modules/service-view/capability.json")"
logs_contract="$(jq -c '.output' "${API}/modules/service-logs/capability.json")"
svc_units=$'web.service loaded active running Web\nold.service loaded inactive dead Old\nmissing.service not-found inactive dead missing.service\n'
svc_show=$'Id=old.service\nDescription=Old\nLoadState=loaded\nActiveState=inactive\nSubState=dead\nStateChangeTimestamp=\nUnitFileState=disabled\nUnitFilePreset=disabled\nFragmentPath=/home/podshift/.config/systemd/user/old.service\nSourcePath=\nTriggeredBy=old.timer\nResult=success\nMainPID=0\nMemoryCurrent=[not set]\n\nId=web.service\nDescription=Web\nLoadState=loaded\nActiveState=active\nSubState=running\nStateChangeTimestamp=@1794474134\nUnitFileState=generated\nUnitFilePreset=enabled\nFragmentPath=/run/user/300/systemd/generator/web.service\nSourcePath=/home/podshift/.config/containers/systemd/web.container\nTriggeredBy=\nResult=success\nMainPID=12\nMemoryCurrent=1024\n'

cockpit-services-list-systemctl() {
    printf '%s\n' "$*" >> "${svc_calls}"
    case "${1-}" in
        list-units) printf '%s' "${SVC_UNITS-}" ;;
        show) printf '%s' "${svc_show}" ;;
        *) return 1 ;;
    esac
}
: > "${svc_calls}"
services_out="$(SVC_UNITS="${svc_units}" cockpit-module-services-list)"
if printf '%s' "${services_out}" | jq -e '[.items[].id] == ["old.service","web.service"] and .items[1].source == "quadlet" and .items[1].since == "2026-11-12T09:02:14Z" and .items[0].triggeredBy == "old.timer"' >/dev/null \
    && cockpit-validate-contract "${services_contract}" "${services_out}" \
    && grep -q -- '^show --timestamp=unix --property=Id,Description,LoadState,ActiveState,SubState,StateChangeTimestamp,UnitFileState,UnitFilePreset,FragmentPath,SourcePath,TriggeredBy,Result,MainPID,MemoryCurrent -- old.service web.service$' "${svc_calls}" \
    && ! grep -q 'missing.service' "${svc_calls}"; then
    ok "services-list-module"
else
    bad "services-list-module" "${services_out} calls $(tr '\n' ';' < "${svc_calls}")"
fi

: > "${svc_calls}"
services_out="$(SVC_UNITS="" cockpit-module-services-list)"
[[ "${services_out}" == '{"items":[]}' ]] && ! grep -q '^show' "${svc_calls}"
expect_status "services-list-empty" $? "${services_out}"

cockpit-services-list-systemctl() {
    return 1
}
if services_out="$(cockpit-module-services-list 2>/dev/null)"; then
    bad "services-list-systemctl-fails" "${services_out}"
else
    ok "services-list-systemctl-fails"
fi

cockpit-services-list-systemctl() {
    case "${1-}" in
        list-units) printf '%s' "${svc_units}" ;;
        *) return 1 ;;
    esac
}
if services_out="$(cockpit-module-services-list 2>/dev/null)"; then
    bad "services-list-show-fails" "${services_out}"
else
    ok "services-list-show-fails"
fi

