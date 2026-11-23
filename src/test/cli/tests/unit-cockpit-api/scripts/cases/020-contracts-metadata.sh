#!/usr/bin/env bash
# @file: 020-contracts-metadata.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: Contract checks, capability metadata, the ping uid, dispatch and the session uid refusal.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# --- contracts ---
expect_contract "type-object" '{"type":"object"}' '{}' 0
expect_contract "type-object-reject" '{"type":"object"}' '[]' 1
expect_contract "type-array" '{"type":"array","items":{"type":"integer"}}' '[1,2]' 0
expect_contract "type-array-reject" '{"type":"array","items":{"type":"integer"}}' '[1,"x"]' 1
expect_contract "type-string" '{"type":"string"}' '"ab"' 0
expect_contract "type-string-reject" '{"type":"string"}' '1' 1
expect_contract "type-integer" '{"type":"integer"}' '300' 0
expect_contract "type-integer-reject" '{"type":"integer"}' '1.5' 1
expect_contract "type-number" '{"type":"number"}' '1.5' 0
expect_contract "type-boolean" '{"type":"boolean"}' 'false' 0
expect_contract "type-boolean-reject" '{"type":"boolean"}' '0' 1
expect_contract "type-null" '{"type":"null"}' 'null' 0
expect_contract "type-null-reject" '{"type":"null"}' '0' 1
expect_contract "addl-reject" '{"type":"object","properties":{},"additionalProperties":false}' '{"a":1}' 1
expect_contract "addl-allow-when-omitted" '{"type":"object","properties":{"a":{"type":"integer"}}}' '{"a":1,"b":2}' 0
expect_contract "required-missing" '{"type":"object","required":["a"]}' '{}' 1
expect_contract "enum-accept" '{"enum":[300,"x",true]}' '300' 0
expect_contract "enum-reject" '{"enum":[300]}' '301' 1
expect_contract "const-accept" '{"const":{"a":1}}' '{"a":1}' 0
expect_contract "const-reject" '{"const":false}' 'true' 1
expect_contract "keyword-rejected" '{"type":"array","maxItems":1}' '[]' 2
expect_contract "min-length-accept" '{"type":"string","minLength":2}' '"ab"' 0
expect_contract "min-length-reject" '{"type":"string","minLength":2}' '"a"' 1
expect_contract "max-length-accept" '{"type":"string","maxLength":2}' '"ab"' 0
expect_contract "max-length-reject" '{"type":"string","maxLength":2}' '"abc"' 1
expect_contract "length-not-string" '{"maxLength":1}' '[1,2,3]' 0
expect_contract "length-negative-rejected" '{"type":"string","minLength":-1}' '"a"' 2
expect_contract "length-fraction-rejected" '{"type":"string","maxLength":1.5}' '"a"' 2
expect_contract "pattern-accept" '{"type":"string","pattern":"\\A[a-z]+\\z"}' '"abc"' 0
expect_contract "pattern-reject" '{"type":"string","pattern":"\\A[a-z]+\\z"}' '"ab1"' 1
expect_contract "pattern-newline-reject" '{"type":"string","pattern":"\\A[a-z]+\\z"}' '"ab\nc"' 1
expect_contract "pattern-not-string-rejected" '{"type":"string","pattern":1}' '"a"' 2
expect_contract "pattern-invalid-rejected" '{"type":"string","pattern":"(["}' '"a"' 2
expect_contract "keyword-nested" '{"type":"object","properties":{"a":{"type":"string","format":"x"}}}' '{"a":"b"}' 2
expect_contract "items-tuple-rejected" '{"type":"array","items":[{"type":"string"}]}' '["a"]' 2
expect_contract "type-array-rejected" '{"type":["string","null"]}' '"a"' 2
expect_contract "addl-true-rejected" '{"additionalProperties":true}' '{}' 2
NEST='{"type":"object","additionalProperties":false,"required":["user"],"properties":{"user":{"type":"object","additionalProperties":false,"required":["name","tags"],"properties":{"name":{"type":"string"},"tags":{"type":"array","items":{"type":"object","additionalProperties":false,"required":["id"],"properties":{"id":{"type":"integer"}}}}}}}}'
expect_contract "nested-accept" "${NEST}" '{"user":{"name":"a","tags":[{"id":1},{"id":2}]}}' 0
expect_contract "nested-extra" "${NEST}" '{"user":{"name":"a","tags":[{"id":1}],"extra":true}}' 1
expect_contract "nested-item-type" "${NEST}" '{"user":{"name":"a","tags":[{"id":"z"}]}}' 1
expect_contract "nested-missing" "${NEST}" '{"user":{"tags":[{"id":1}]}}' 1
expect_contract "ping-input" '{"type":"object","properties":{},"additionalProperties":false}' '{}' 0
expect_contract "ping-output" '{"type":"object","properties":{"pong":{"type":"boolean"},"uid":{"type":"integer","enum":[300]}},"required":["pong","uid"],"additionalProperties":false}' '{"pong":true,"uid":300}' 0
expect_contract "ping-output-uid" '{"type":"object","properties":{"pong":{"type":"boolean"},"uid":{"type":"integer","enum":[300]}},"required":["pong","uid"],"additionalProperties":false}' '{"pong":true,"uid":1000}' 1

# --- metadata ---
good_cap="$(cat "${API}/modules/ping/capability.json")"
cockpit-validate-capability ping "${good_cap}"
[[ "$?" -eq 0 ]]
expect_status "ping-metadata" $? "rc $?"
cockpit-validate-capability other "${good_cap}"
[[ "$?" -eq 1 ]]
expect_status "metadata-action-mismatch" $? "rc $?"
cockpit-validate-capability ping "{" 2>/dev/null
[[ "$?" -eq 1 ]]
expect_status "metadata-malformed" $? "rc $?"
retired_cap="$(printf '%s' "${good_cap}" | jq -c '.status="retired"')"
cockpit-validate-capability ping "${retired_cap}"
[[ "$?" -eq 2 ]]
expect_status "metadata-retired" $? "rc $?"
deprecated_cap="$(printf '%s' "${good_cap}" | jq -c '.status="deprecated"')"
cockpit-validate-capability ping "${deprecated_cap}"
[[ "$?" -eq 0 ]]
expect_status "metadata-deprecated" $? "rc $?"
bad_kw="$(printf '%s' "${good_cap}" | jq -c '.input.maxItems=1')"
cockpit-validate-capability ping "${bad_kw}"
[[ "$?" -eq 1 ]]
expect_status "metadata-unknown-keyword" $? "rc $?"

mkdir -p "${WORK}/missing"
cockpit-load-capability "${WORK}/missing"
[[ "$?" -eq 1 ]]
expect_status "metadata-missing-file" $? "rc $?"
dd if=/dev/zero bs=65537 count=1 2>/dev/null | tr '\0' 'c' > "${WORK}/big.json"
mkdir -p "${WORK}/bigmod"
cp "${WORK}/big.json" "${WORK}/bigmod/capability.json"
cockpit-load-capability "${WORK}/bigmod"
[[ "$?" -eq 1 ]]
expect_status "metadata-too-big" $? "rc $?"
ln -s "${API}/modules/ping/capability.json" "${WORK}/cap.link"
mkdir -p "${WORK}/linkmod"
ln -s "${WORK}/cap.link" "${WORK}/linkmod/capability.json"
cockpit-load-capability "${WORK}/linkmod"
[[ "$?" -eq 1 ]]
expect_status "metadata-symlink" $? "rc $?"

# --- ping module reports the real uid ---
ping_out="$(cockpit-module-ping)"
[[ "${ping_out}" == "{\"pong\":true,\"uid\":${EUID}}" ]]
expect_status "ping-real-uid" $? "${ping_out}"

# --- dispatch ---
list_out="$(cockpit-dispatch-action list)"
printf '%s' "${list_out}" | jq -e 'length == 25 and .[0].action == "ping" and .[0].function == "cockpit-module-ping" and .[0].realm == "podshift" and .[1].action == "capabilities" and .[1].function == "cockpit-module-capabilities" and .[1].realm == "root" and .[2].action == "overview-status" and .[2].function == "cockpit-module-overview-status" and .[2].realm == "root" and .[3].action == "overview-usage" and .[3].function == "cockpit-module-overview-usage" and .[3].realm == "podshift" and .[4].action == "overview-info" and .[4].function == "cockpit-module-overview-info" and .[4].realm == "podshift" and .[5].action == "overview-config" and .[5].function == "cockpit-module-overview-config" and .[5].realm == "podshift" and .[6].action == "health-check" and .[6].function == "cockpit-module-health-check" and .[6].realm == "root" and .[7].action == "networks-list" and .[7].function == "cockpit-module-networks-list" and .[7].realm == "podshift" and .[8].action == "images-list" and .[8].function == "cockpit-module-images-list" and .[8].realm == "podshift" and .[9].action == "volumes-list" and .[9].function == "cockpit-module-volumes-list" and .[9].realm == "podshift" and .[10].action == "containers-list" and .[10].function == "cockpit-module-containers-list" and .[10].realm == "podshift" and .[11].action == "inspect" and .[11].function == "cockpit-module-inspect" and .[11].realm == "podshift" and .[12].action == "secrets-list" and .[12].function == "cockpit-module-secrets-list" and .[12].realm == "podshift" and .[13].action == "services-list" and .[13].function == "cockpit-module-services-list" and .[13].realm == "podshift" and .[14].action == "service-view" and .[14].function == "cockpit-module-service-view" and .[14].realm == "podshift" and .[15].action == "service-logs" and .[15].function == "cockpit-module-service-logs" and .[15].realm == "root" and .[16].action == "quadlets-list" and .[16].function == "cockpit-module-quadlets-list" and .[16].realm == "podshift" and .[17].action == "quadlet-view" and .[17].function == "cockpit-module-quadlet-view" and .[17].realm == "podshift" and .[18].action == "config-set" and .[18].function == "cockpit-module-config-set" and .[18].realm == "podshift" and .[19].action == "config-unset" and .[19].function == "cockpit-module-config-unset" and .[19].realm == "podshift" and .[20].action == "env-set" and .[20].function == "cockpit-module-env-set" and .[20].realm == "root" and .[21].action == "quadlet-drop" and .[21].function == "cockpit-module-quadlet-drop" and .[21].realm == "podshift" and .[22].action == "quadlet-drop-history" and .[22].function == "cockpit-module-quadlet-drop-history" and .[22].realm == "root" and .[23].action == "quadlet-install-log" and .[23].function == "cockpit-module-quadlet-install-log" and .[23].realm == "root" and .[24].action == "quadlet-remove" and .[24].function == "cockpit-module-quadlet-remove" and .[24].realm == "podshift"' >/dev/null
expect_status "dispatch-lists-actions" $? "${list_out}"
cap_lookup="$(cockpit-dispatch-action lookup capabilities)"
printf '%s' "${cap_lookup}" | jq -e '.action == "capabilities" and .function == "cockpit-module-capabilities" and .realm == "root"' >/dev/null
expect_status "dispatch-lists-capabilities" $? "${cap_lookup}"

# all-fields prints every entry as a tab-separated line, in the same order as list.
all_fields_out="$(cockpit-dispatch-action all-fields | cut -f1,2,4 | tr '\t' ' ')"
all_list_out="$(cockpit-dispatch-action list | jq -r '.[] | "\(.action) \(.function) \(.realm)"')"
[[ -n "${all_fields_out}" && "${all_fields_out}" == "${all_list_out}" ]]
expect_status "dispatch-all-fields-match-list" $? "${all_fields_out}"

dispatch_bad=""
for dispatch_name in $(printf '%s' "${list_out}" | jq -r '.[].action'); do
    dispatch_want="$(cockpit-dispatch-action lookup "${dispatch_name}" | jq -r '[.action, .function, .directory, .realm] | @tsv')"
    if [[ "$(cockpit-dispatch-action fields "${dispatch_name}")" != "${dispatch_want}" ]]; then
        dispatch_bad="${dispatch_bad} ${dispatch_name}"
    fi
done
if cockpit-dispatch-action fields nope >/dev/null || cockpit-dispatch-action lookup "" >/dev/null || cockpit-dispatch-action other ping >/dev/null; then
    dispatch_bad="${dispatch_bad} unknown-accepted"
fi
[[ -z "${dispatch_bad}" ]]
expect_status "dispatch-fields-match-lookup" $? "${dispatch_bad}"

# --- session script refuses this uid ---
sess_out="$(bash "${API}/fn/cockpit-run-in-session.sh" ping 2>"${WORK}/sess.err")"
sess_rc=$?
[[ "${sess_rc}" -ne 0 && -z "${sess_out}" ]] && ! printf '%s' "${sess_out}" | grep -q '{'
expect_status "session-requires-uid-300" $? "rc ${sess_rc} out ${sess_out}"

if grep -nE '(^|[[:space:]])source[[:space:]].*cockpit-run-in-session' "${API}/main.sh" "${API}/fn/cockpit-enter-session.sh" "${API}/fn/cockpit-run-module.sh" "${API}/fn/cockpit-dispatch-action.sh" >/dev/null; then
    bad "root-does-not-source-session" "a root helper sources the session script"
else
    ok "root-does-not-source-session"
fi
if grep -nE '(^|[^[:alnum:]_])eval[[:space:]]' "${API}/main.sh" "${API}/fn/"*.sh "${API}/fn/"*/*.sh "${API}/modules/"*/module.sh "${API}/modules/"*/fn/*.sh >/dev/null; then
    bad "no-eval" "eval is present"
else
    ok "no-eval"
fi

