#!/usr/bin/env bash
# @file: 030-handler-paths.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: Handler paths: setsid, invalid arguments, capabilities, realms and module failures.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# --- handler paths. These call cockpit-serve, so the outer process is not switched to root. ---
version="$(get-podshift-version)"

reset_mocks
MODE="emit"
EMIT='{"pong":true,"uid":300}'
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
if expect_code "ping-mock-session" "OK"; then
    if [[ "$(field '.data.pong')" == "true" && "$(field '.data.uid')" == "300" && "$(field '.request.action')" == "ping" && "$(field '.request.args | length')" == "0" && "$(field '.podshift.version')" == "${version}" && "$(field '.podshift.apiVersion')" == "1" && "$(field '.status.ok')" == "true" ]]; then
        if grep -q 'action=ping code=OK duration_ms=' "${LOG}" && ! grep -q '{' "${LOG}"; then
            ok "ping-mock-session"
        else
            bad "ping-mock-session" "log $(cat "${LOG}")"
        fi
    else
        bad "ping-mock-session" "${LAST_OUT}"
    fi
fi

# --- with setsid: macOS has none, so a fake setsid on PATH logs its call and runs the rest. Both realms take that branch. ---
mkdir -p "${WORK}/setsid-bin"
cp "${MOCKS}/setsid.sh" "${WORK}/setsid-bin/setsid"
chmod 755 "${WORK}/setsid-bin/setsid"
SETSID_LOG="${WORK}/setsid.log"
export COCKPIT_TEST_SETSID_LOG="${SETSID_LOG}"
OLD_PATH="${PATH}"
for SETSID_ACTION in ping capabilities; do
    reset_mocks
    MODE="emit"
    EMIT='{"pong":true,"uid":300}'
    : > "${SETSID_LOG}"
    PATH="${WORK}/setsid-bin:${OLD_PATH}"
    run_serve "{\"apiVersion\":1,\"action\":\"${SETSID_ACTION}\",\"args\":{}}"
    PATH="${OLD_PATH}"
    if expect_code "setsid-${SETSID_ACTION}" "OK"; then
        grep -qx 'setsid --wait' "${SETSID_LOG}"
        expect_status "setsid-${SETSID_ACTION}" $? "setsid was not used"
    fi
done
unset COCKPIT_TEST_SETSID_LOG

reset_mocks
MODE="emit"
EMIT='{"pong":true,"uid":300}'
run_serve "{\"apiVersion\":1,\"action\":\"ping\",\"args\":{\"token\":\"${secret}\"}}"
if expect_code "ping-invalid-args" "INVALID_ARGS"; then
    [[ ! -s "${ARGV}" && "$(field '.request.args')" == "null" && "$(field '.status.message')" == "Given arguments are not supported: token." ]] && ! printf '%s%s%s' "${LAST_OUT}" "${LAST_ERR}" "$(cat "${LOG}")" | grep -q "${secret}"
    expect_status "ping-invalid-args" $? "module ran or secret leaked"
fi

reset_mocks
run_serve '{"apiVersion":1,"action":"capabilities","args":{}}'
if expect_code "capabilities-lists-actions" "OK"; then
    if [[ "$(field '.status.message')" == "Action completed" && "$(field '.status.ok')" == "true" && "$(field '.request.action')" == "capabilities" && "$(field '.request.args | length')" == "0" ]]; then
        if printf '%s' "${LAST_OUT}" | jq -e '
            (.data.actions | length) == 25
            and .data.actions[0].action == "ping"
            and .data.actions[0].name == "Ping"
            and .data.actions[0].status == "active"
            and (.data.actions[0].description | type) == "string"
            and (.data.actions[0].input | type) == "object"
            and (.data.actions[0].output | type) == "object"
            and .data.actions[1].action == "capabilities"
            and .data.actions[1].name == "Capabilities"
            and .data.actions[1].status == "active"
            and (.data.actions[1].description | type) == "string"
            and (.data.actions[1].input | type) == "object"
            and (.data.actions[1].output | type) == "object"
            and .data.actions[2].action == "overview-status"
            and .data.actions[2].name == "Overview status"
            and .data.actions[2].status == "active"
            and (.data.actions[2].description | type) == "string"
            and (.data.actions[2].input | type) == "object"
            and (.data.actions[2].output | type) == "object"
            and .data.actions[3].action == "overview-usage"
            and .data.actions[3].name == "Overview usage"
            and .data.actions[3].status == "active"
            and (.data.actions[3].description | type) == "string"
            and (.data.actions[3].input | type) == "object"
            and (.data.actions[3].output | type) == "object"
            and .data.actions[4].action == "overview-info"
            and .data.actions[4].name == "Overview info"
            and .data.actions[4].status == "active"
            and (.data.actions[4].description | type) == "string"
            and (.data.actions[4].input | type) == "object"
            and (.data.actions[4].output | type) == "object"
            and .data.actions[5].action == "overview-config"
            and .data.actions[5].name == "Overview config"
            and .data.actions[5].status == "active"
            and (.data.actions[5].description | type) == "string"
            and (.data.actions[5].input | type) == "object"
            and (.data.actions[5].output | type) == "object"
            and .data.actions[6].action == "health-check"
            and .data.actions[6].name == "Health check"
            and .data.actions[6].status == "active"
            and (.data.actions[6].description | type) == "string"
            and (.data.actions[6].input | type) == "object"
            and (.data.actions[6].output | type) == "object"
            and .data.actions[7].action == "networks-list"
            and .data.actions[7].name == "Networks list"
            and .data.actions[7].status == "active"
            and (.data.actions[7].description | type) == "string"
            and (.data.actions[7].input | type) == "object"
            and (.data.actions[7].output | type) == "object"
            and .data.actions[8].action == "images-list"
            and .data.actions[8].name == "Images list"
            and .data.actions[8].status == "active"
            and (.data.actions[8].description | type) == "string"
            and (.data.actions[8].input | type) == "object"
            and (.data.actions[8].output | type) == "object"
            and .data.actions[9].action == "volumes-list"
            and .data.actions[9].name == "Volumes list"
            and .data.actions[9].status == "active"
            and (.data.actions[9].description | type) == "string"
            and (.data.actions[9].input | type) == "object"
            and (.data.actions[9].output | type) == "object"
            and .data.actions[10].action == "containers-list"
            and .data.actions[10].name == "Containers list"
            and .data.actions[10].status == "active"
            and (.data.actions[10].description | type) == "string"
            and (.data.actions[10].input | type) == "object"
            and (.data.actions[10].output | type) == "object"
            and .data.actions[11].action == "inspect"
            and .data.actions[11].name == "Inspect"
            and .data.actions[11].status == "active"
            and .data.actions[11].input.required == ["kind","ref"]
            and (.data.actions[11].output | type) == "object"
            and .data.actions[11].input.properties.kind.enum == ["container","image","volume","network","secret"]
            and .data.actions[12].action == "secrets-list"
            and .data.actions[12].name == "Secrets list"
            and .data.actions[12].status == "active"
            and (.data.actions[12].description | type) == "string"
            and (.data.actions[12].input | type) == "object"
            and (.data.actions[12].output | type) == "object"
            and .data.actions[13].action == "services-list"
            and .data.actions[13].name == "Services list"
            and .data.actions[13].status == "active"
            and .data.actions[14].action == "service-view"
            and .data.actions[14].name == "Service view"
            and .data.actions[14].input.required == ["unit","mode"]
            and .data.actions[14].input.properties.mode.enum == ["unit","status"]
            and .data.actions[15].action == "service-logs"
            and .data.actions[15].name == "Service logs"
            and .data.actions[15].input.required == ["unit"]
            and .data.actions[16].action == "quadlets-list"
            and .data.actions[16].name == "Quadlets list"
            and .data.actions[16].status == "active"
            and (.data.actions[16].input | type) == "object"
            and (.data.actions[16].output | type) == "object"
            and .data.actions[17].action == "quadlet-view"
            and .data.actions[17].name == "Quadlet view"
            and .data.actions[17].input.required == ["unit"]
            and .data.actions[18].action == "config-set"
            and .data.actions[18].name == "Config set"
            and .data.actions[18].input.required == ["key","value"]
            and .data.actions[19].action == "config-unset"
            and .data.actions[19].name == "Config unset"
            and .data.actions[19].input.required == ["key"]
            and .data.actions[20].action == "env-set"
            and .data.actions[20].name == "Environment tag set"
            and .data.actions[20].input.required == ["value"]
            and .data.actions[21].action == "quadlet-drop"
            and .data.actions[21].name == "Quadlet drop"
            and .data.actions[21].input.required == ["name","content"]
            and .data.actions[22].action == "quadlet-drop-history"
            and .data.actions[22].name == "Quadlet drop history"
            and .data.actions[22].output.required == ["readable","items"]
            and .data.actions[23].action == "quadlet-install-log"
            and .data.actions[23].name == "Quadlet install log"
            and .data.actions[23].output.required == ["readable","entries"]
            and .data.actions[24].action == "quadlet-remove"
            and .data.actions[24].name == "Quadlet remove"
            and .data.actions[24].input.required == ["name"]
        ' >/dev/null; then
            if grep -q 'action=capabilities code=OK duration_ms=' "${LOG}" && ! grep -q '{' "${LOG}"; then
                ok "capabilities-lists-actions"
            else
                bad "capabilities-lists-actions" "log $(cat "${LOG}")"
            fi
        else
            bad "capabilities-lists-actions" "${LAST_OUT}"
        fi
    else
        bad "capabilities-lists-actions" "${LAST_OUT}"
    fi
fi

reset_mocks
run_serve '{"apiVersion":1,"action":"capabilities","args":{}}'
if expect_code "capabilities-root-realm-no-session" "OK"; then
    if [[ ! -s "${ARGV}" ]]; then
        ok "capabilities-root-realm-no-session"
    else
        bad "capabilities-root-realm-no-session" "argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
run_serve "{\"apiVersion\":1,\"action\":\"capabilities\",\"args\":{\"token\":\"${secret}\"}}"
if expect_code "capabilities-invalid-args" "INVALID_ARGS"; then
    [[ ! -s "${ARGV}" && "$(field '.request.args')" == "null" ]] && ! printf '%s%s%s' "${LAST_OUT}" "${LAST_ERR}" "$(cat "${LOG}")" | grep -q "${secret}"
    expect_status "capabilities-invalid-args" $? "module ran or secret leaked"
fi

copy_podshift_tree "${CASES_WORK}/broken-ping"
printf '%s\n' '{' > "${CASES_WORK}/broken-ping/cockpit/api/modules/ping/capability.json"
reset_mocks
run_serve_api "${CASES_WORK}/broken-ping/cockpit/api" '{"apiVersion":1,"action":"capabilities","args":{}}'
if expect_code "capabilities-broken-ping-metadata" "INTERNAL"; then
    if [[ "$(field '.data')" == "null" ]]; then
        ok "capabilities-broken-ping-metadata"
    else
        bad "capabilities-broken-ping-metadata" "data $(field '.data')"
    fi
fi

copy_podshift_tree "${CASES_WORK}/retired-ping"
jq '.status="retired"' "${CASES_WORK}/retired-ping/cockpit/api/modules/ping/capability.json" > "${CASES_WORK}/retired-ping/cockpit/api/modules/ping/capability.tmp"
mv "${CASES_WORK}/retired-ping/cockpit/api/modules/ping/capability.tmp" "${CASES_WORK}/retired-ping/cockpit/api/modules/ping/capability.json"
reset_mocks
run_serve_api "${CASES_WORK}/retired-ping/cockpit/api" '{"apiVersion":1,"action":"capabilities","args":{}}'
if expect_code "capabilities-lists-retired" "OK"; then
    if printf '%s' "${LAST_OUT}" | jq -e '
        (.data.actions | map(select(.action == "ping")) | length) == 1
        and (.data.actions | map(select(.action == "ping")) | .[0].status) == "retired"
        and (.data.actions | map(select(.action == "capabilities")) | .[0].status) == "active"
    ' >/dev/null; then
        ok "capabilities-lists-retired"
    else
        bad "capabilities-lists-retired" "${LAST_OUT}"
    fi
fi


reset_mocks
MODE="fail"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "realm-unavailable" "REALM_UNAVAILABLE" && [[ "$(field '.data')" == "null" ]] && grep -q ' reason=realm$' "${LOG}" && ok "realm-unavailable"
printf '%s' "${LAST_ERR}" | grep -q 'podshift-api: systemd-run: mock: tunnel failed'
expect_status "realm-unavailable-shows-reason" $? "stderr=${LAST_ERR}"

