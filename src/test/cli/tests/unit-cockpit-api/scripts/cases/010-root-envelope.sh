#!/usr/bin/env bash
# @file: 010-root-envelope.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: The root gate before stdin, the request envelope and the direct read bounds.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# --- root rejection before stdin ---
# A held-open pipe writes nothing. A handler that reads stdin waits.
mkfifo "${WORK}/gate.fifo"
sleep 30 > "${WORK}/gate.fifo" &
gate_hold=$!
bash "${API}/main.sh" < "${WORK}/gate.fifo" > "${WORK}/gate.out" 2>"${WORK}/gate.err" &
gate_pid=$!
waited=0
while (( waited < 20 )); do
    if ! kill -0 "${gate_pid}" 2>/dev/null; then
        break
    fi
    sleep 0.1
    waited=$((waited + 1))
done
if kill -0 "${gate_pid}" 2>/dev/null; then
    kill -KILL "${gate_pid}" 2>/dev/null || true
    bad "not-root-before-stdin" "main.sh blocked before producing a response"
else
    wait "${gate_pid}"
    gate_rc=$?
    LAST_OUT="$(cat "${WORK}/gate.out")"
    if [[ "${gate_rc}" -ne 0 ]]; then
        bad "not-root-before-stdin" "exit ${gate_rc}"
    elif ! one_json; then
        bad "not-root-before-stdin" "stdout is not one JSON value"
    elif [[ "$(field '.status.code')" != "NOT_ROOT" || "$(field '.request')" != "null" || "$(field '.data')" != "null" ]]; then
        bad "not-root-before-stdin" "envelope $(field '.status.code') request=$(field '.request')"
    elif [[ "$(field '.status.ok')" != "false" ]]; then
        bad "not-root-before-stdin" "status.ok was not false"
    else
        ok "not-root-before-stdin"
    fi
fi
kill -KILL "${gate_hold}" 2>/dev/null || true
wait "${gate_hold}" 2>/dev/null || true
rm -f "${WORK}/gate.fifo"

secret="SUPERSECRET-ARGS-VALUE"
printf '%s' "{\"apiVersion\":1,\"action\":\"ping\",\"args\":{\"token\":\"${secret}\"}}" | bash "${API}/main.sh" > "${WORK}/nr.out" 2>"${WORK}/nr.err"
nr_rc=$?
LAST_OUT="$(cat "${WORK}/nr.out")"
if [[ "${nr_rc}" -ne 0 ]]; then
    bad "not-root-exit" "exit ${nr_rc}"
elif ! one_json || [[ "$(field '.status.code')" != "NOT_ROOT" ]]; then
    bad "not-root-exit" "code $(field '.status.code')"
elif printf '%s%s' "${LAST_OUT}" "$(cat "${WORK}/nr.err")" | grep -q "${secret}"; then
    bad "not-root-exit" "secret leaked"
else
    ok "not-root-ignores-body"
fi

bash_bin="$(command -v bash)"
PATH="$(mktemp -d)" "${bash_bin}" "${API}/main.sh" </dev/null > "${WORK}/nojq.out" 2>"${WORK}/nojq.err"
nojq_rc=$?
if [[ "${nojq_rc}" -eq 0 ]]; then
    bad "jq-missing" "exit 0"
elif [[ -s "${WORK}/nojq.out" ]]; then
    bad "jq-missing" "stdout was not empty"
elif ! grep -q 'jq is required' "${WORK}/nojq.err"; then
    bad "jq-missing" "stderr did not name jq"
else
    ok "jq-missing"
fi

# --- envelope ---
reset_mocks
run_serve ""
expect_code "empty" "INVALID_REQUEST" && ok "empty"

reset_mocks
run_serve "   "
expect_code "whitespace" "INVALID_REQUEST" && ok "whitespace"

reset_mocks
run_serve "{"
expect_code "malformed" "INVALID_REQUEST" && ok "malformed"

reset_mocks
run_serve "{}{}"
expect_code "two-values" "INVALID_REQUEST" && ok "two-values"

reset_mocks
run_serve "{}"
expect_code "empty-object" "INVALID_REQUEST" && ok "empty-object"

reset_mocks
run_serve "{\"apiVersion\":1,\"action\":\"ping\",\"args\":{},\"extra\":1}"
expect_code "unknown-field" "INVALID_REQUEST" && ok "unknown-field"

reset_mocks
run_serve "{\"apiVersion\":\"1\",\"action\":\"ping\",\"args\":{}}"
expect_code "version-string" "INVALID_REQUEST" && ok "version-string"

reset_mocks
run_serve "{\"apiVersion\":1,\"action\":\"ping\",\"args\":[]}"
expect_code "args-array" "INVALID_REQUEST" && ok "args-array"

reset_mocks
run_serve "{\"apiVersion\":2,\"action\":\"ping\",\"args\":{}}"
expect_code "version-2" "UNSUPPORTED_VERSION" && ok "version-2"

reset_mocks
run_serve "{\"apiVersion\":1,\"action\":\"nope\",\"args\":{}}"
expect_code "unknown-action" "UNKNOWN_ACTION" && [[ "$(field '.request')" == "null" ]] && ! grep -q 'nope' "${LOG}" && ok "unknown-action"

reset_mocks
run_serve "{\"apiVersion\":1,\"action\":\"../ping\",\"args\":{}}"
expect_code "action-path" "UNKNOWN_ACTION" && [[ ! -s "${ARGV}" ]] && ok "action-path"

reset_mocks
python_payload="$(dd if=/dev/zero bs=65537 count=1 2>/dev/null | tr '\0' 'a')"
run_serve "${python_payload}"
expect_code "request-too-big" "INVALID_REQUEST" && ok "request-too-big"

# direct read bounds
empty_out="$(printf '' | cockpit-read-request)"
empty_rc=$?
[[ "${empty_rc}" -eq 1 && -z "${empty_out}" ]]
expect_status "read-empty" $? "rc ${empty_rc}"
big="$(dd if=/dev/zero bs=131073 count=1 2>/dev/null | tr '\0' 'b')"
big_out="$(printf '%s' "${big}" | cockpit-read-request)"
big_rc=$?
[[ "${big_rc}" -eq 2 && -z "${big_out}" ]]
expect_status "read-oversize" $? "rc ${big_rc} bytes ${#big_out}"

mkfifo "${WORK}/slow.fifo"
sleep 30 > "${WORK}/slow.fifo" &
slow_hold=$!
read_start="${SECONDS}"
cockpit-read-request < "${WORK}/slow.fifo" > "${WORK}/slow.out" 2>"${WORK}/slow.err"
slow_rc=$?
slow_elapsed=$((SECONDS - read_start))
kill -KILL "${slow_hold}" 2>/dev/null || true
wait "${slow_hold}" 2>/dev/null || true
rm -f "${WORK}/slow.fifo"
[[ "${slow_rc}" -eq 3 && "${slow_elapsed}" -ge 4 && "${slow_elapsed}" -le 8 ]]
expect_status "read-wait-bound" $? "rc ${slow_rc} elapsed ${slow_elapsed}"

