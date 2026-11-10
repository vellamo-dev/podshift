#!/usr/bin/env bash
# @file: run-cockpit-api-cases.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts
# @group: test
# @category: entry
# @description: Runs the Cockpit API cases outside the podshift session, with systemd-run and logger mocked where a session is required.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set +e
umask 022

if ! command -v jq >/dev/null 2>&1; then
    echo "jq was not found"
    echo "Fix: install jq"
    exit 3
fi

pass=0
fail=0
repo=""
here=""

here="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
repo="${here}"
while [[ "${repo}" != "/" && ! -f "${repo}/podshift.spec" ]]; do
    repo="$(dirname -- "${repo}")"
done
if [[ ! -f "${repo}/podshift.spec" ]]; then
    echo "DETAIL: FAIL repo root was not found"
    exit 2
fi

API="${repo}/src/server/opt/podshift/cockpit/api"
PODSHIFT="${repo}/src/server/opt/podshift"
CASES_WORK="${repo}/artifacts/work/cockpit-capabilities"
mkdir -p "${CASES_WORK}"
work="$(mktemp -d)"
argv="${work}/argv"
log="${work}/log"
child="${work}/child"
: >"${argv}"
: >"${log}"

cleanup_cases() {
    local pid
    if [[ -f "${child}" ]]; then
        pid="$(cat "${child}" 2>/dev/null || true)"
        if [[ -n "${pid}" ]]; then
            kill -KILL "${pid}" 2>/dev/null || true
        fi
    fi
    rm -rf "${work}" "${CASES_WORK}/broken-ping" "${CASES_WORK}/retired-ping"
}
trap cleanup_cases EXIT

ok() {
    echo "DETAIL: PASS ${1}"
    pass=$((pass + 1))
}

bad() {
    echo "DETAIL: FAIL ${1}: ${2}"
    fail=$((fail + 1))
}

reset_mocks() {
    : >"${argv}"
    : >"${log}"
    rm -f "${child}"
    MODE="fail"
    EMIT=""
    EMIT_RC="0"
    LOGGER_FAIL=""
}

cat > "${work}/systemd-run" << 'EOF'
#!/usr/bin/env bash
printf '%q ' "$@" >> "${COCKPIT_TEST_ARGV}"
printf '\n' >> "${COCKPIT_TEST_ARGV}"
# systemctl stop looks up systemd-run on PATH. Only the handler invocation may sleep or write.
if [[ "$*" != *cockpit-run-in-session.sh* ]]; then
    exit 0
fi
# Real systemd-run --pipe fails on a named FIFO or a regular file as stdout or stderr. An anonymous pipe or a terminal works.
# A FIFO with a filesystem name is named. Linux shows pipe:[n] for an anonymous pipe, and lsof on macOS shows ->0x.
for fd in 1 2; do
    fd_bad=""
    if [[ -f "/dev/fd/${fd}" ]]; then
        fd_bad=1
    elif [[ -p "/dev/fd/${fd}" ]]; then
        if [[ -e "/proc/$$/fd/${fd}" ]]; then
            fd_name="$(readlink "/proc/$$/fd/${fd}" 2>/dev/null)"
        else
            fd_name="$(lsof -a -p "$$" -d "${fd}" -Fn 2>/dev/null | sed -n 's/^n//p')"
        fi
        case "${fd_name}" in
            /*) fd_bad=1 ;;
        esac
    fi
    if [[ -n "${fd_bad}" ]]; then
        printf 'Failed to start transient service unit: Failed to set unit properties: Bad message\n' >&2
        exit 1
    fi
done
case "${COCKPIT_TEST_SYSTEMD_MODE:-fail}" in
    emit)
        printf '\034%s' "${COCKPIT_TEST_EMIT}"
        exit "${COCKPIT_TEST_EMIT_RC:-0}"
        ;;
    oversize)
        sleep 60 &
        printf '%s\n' "$!" > "${COCKPIT_TEST_CHILD}"
        printf '\034'
        dd if=/dev/zero bs=70000 count=1 2>/dev/null | tr '\0' 'A'
        wait
        ;;
    timeout)
        sleep 60 &
        printf '%s\n' "$!" > "${COCKPIT_TEST_CHILD}"
        printf '\034{"pong":true,"uid":300}'
        wait
        ;;
    stray)
        printf '\034LEAKED-MODULE-OUTPUT'
        exit 0
        ;;
    twovalue)
        printf '\034{"pong":true}{"pong":false}'
        exit 0
        ;;
    nonzero)
        printf '\034{"pong":true,"uid":300}'
        exit 4
        ;;
    baduid)
        printf '\034{"pong":true,"uid":999}'
        exit 0
        ;;
    run)
        while [[ $# -gt 0 ]]; do
            if [[ "${1}" == "bash" ]]; then
                exec "$@"
            fi
            shift
        done
        exit 1
        ;;
    *)
        printf 'mock: tunnel failed\n' >&2
        exit 1
        ;;
esac
EOF

cat > "${work}/logger" << 'EOF'
#!/usr/bin/env bash
printf '%s\n' "$*" >> "${COCKPIT_TEST_LOG}"
if [[ "${COCKPIT_TEST_LOGGER_FAIL:-}" == "1" ]]; then
    exit 1
fi
exit 0
EOF
chmod 755 "${work}/systemd-run" "${work}/logger"

# shellcheck source=/dev/null
source "${API}/fn/cockpit-validate-contract.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-validate-capability.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-load-capability.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-dispatch-action.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-read-request.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-log-request.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-stop-process-tree.sh"
# shellcheck source=/dev/null
source "${API}/modules/ping/module.sh"
# shellcheck source=/dev/null
source "${PODSHIFT}/fn/common/get-podshift-version.sh"

LAST_OUT=""
LAST_ERR=""
LAST_RC=0
MODE="fail"
EMIT=""
EMIT_RC="0"
LOGGER_FAIL=""

run_serve() {
    local payload errfile
    payload="${1-}"
    errfile="$(mktemp)"
    LAST_OUT="$(
        printf '%s' "${payload}" | PATH="${work}:${PATH}" \
            COCKPIT_TEST_ARGV="${argv}" \
            COCKPIT_TEST_LOG="${log}" \
            COCKPIT_TEST_CHILD="${child}" \
            COCKPIT_TEST_SYSTEMD_MODE="${MODE}" \
            COCKPIT_TEST_EMIT="${EMIT}" \
            COCKPIT_TEST_EMIT_RC="${EMIT_RC}" \
            COCKPIT_TEST_LOGGER_FAIL="${LOGGER_FAIL}" \
            bash -c 'set +e; source "$1"; cockpit-serve 0; exit $?' _ "${API}/main.sh" \
            2>"${errfile}"
    )"
    LAST_RC=$?
    LAST_ERR="$(cat "${errfile}" 2>/dev/null || true)"
    rm -f "${errfile}"
}

run_serve_api() {
    local api_dir payload errfile
    api_dir="${1}"
    payload="${2-}"
    errfile="$(mktemp)"
    LAST_OUT="$(
        printf '%s' "${payload}" | PATH="${work}:${PATH}" \
            COCKPIT_TEST_ARGV="${argv}" \
            COCKPIT_TEST_LOG="${log}" \
            COCKPIT_TEST_CHILD="${child}" \
            COCKPIT_TEST_SYSTEMD_MODE="${MODE}" \
            COCKPIT_TEST_EMIT="${EMIT}" \
            COCKPIT_TEST_EMIT_RC="${EMIT_RC}" \
            COCKPIT_TEST_LOGGER_FAIL="${LOGGER_FAIL}" \
            bash -c 'set +e; source "$1"; cockpit-serve 0; exit $?' _ "${api_dir}/main.sh" \
            2>"${errfile}"
    )"
    LAST_RC=$?
    LAST_ERR="$(cat "${errfile}" 2>/dev/null || true)"
    rm -f "${errfile}"
}

copy_podshift_tree() {
    local dest
    dest="${1}"
    rm -rf "${dest}"
    mkdir -p "${dest}"
    cp -R "${PODSHIFT}/." "${dest}/"
}

one_json() {
    printf '%s' "${LAST_OUT}" | jq -e -s 'length == 1' >/dev/null 2>&1
}

field() {
    printf '%s' "${LAST_OUT}" | jq -r "${1}" 2>/dev/null
}

expect_code() {
    local name want got
    name="${1}"
    want="${2}"
    if [[ "${LAST_RC}" -ne 0 ]]; then
        bad "${name}" "exit ${LAST_RC}, stderr=${LAST_ERR}"
        return 1
    fi
    if ! one_json; then
        bad "${name}" "stdout is not one JSON value"
        return 1
    fi
    got="$(field '.status.code')"
    if [[ "${got}" != "${want}" ]]; then
        bad "${name}" "code ${got}, want ${want}"
        return 1
    fi
    return 0
}

still_alive() {
    local pid stat
    pid="${1}"
    stat="$(ps -o stat= -p "${pid}" 2>/dev/null | tr -d '[:space:]')"
    [[ -n "${stat}" && "${stat}" != Z* ]]
}

echo "NOTE: mocked session paths are not a live podshift@.host login"

# --- root rejection before stdin ---
# A held-open pipe writes nothing. A handler that reads stdin waits.
mkfifo "${work}/gate.fifo"
sleep 30 > "${work}/gate.fifo" &
gate_hold=$!
bash "${API}/main.sh" < "${work}/gate.fifo" > "${work}/gate.out" 2>"${work}/gate.err" &
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
    LAST_OUT="$(cat "${work}/gate.out")"
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
rm -f "${work}/gate.fifo"

secret="SUPERSECRET-ARGS-VALUE"
printf '%s' "{\"apiVersion\":1,\"action\":\"ping\",\"args\":{\"token\":\"${secret}\"}}" | bash "${API}/main.sh" > "${work}/nr.out" 2>"${work}/nr.err"
nr_rc=$?
LAST_OUT="$(cat "${work}/nr.out")"
if [[ "${nr_rc}" -ne 0 ]]; then
    bad "not-root-exit" "exit ${nr_rc}"
elif ! one_json || [[ "$(field '.status.code')" != "NOT_ROOT" ]]; then
    bad "not-root-exit" "code $(field '.status.code')"
elif printf '%s%s' "${LAST_OUT}" "$(cat "${work}/nr.err")" | grep -q "${secret}"; then
    bad "not-root-exit" "secret leaked"
else
    ok "not-root-ignores-body"
fi

bash_bin="$(command -v bash)"
PATH="$(mktemp -d)" "${bash_bin}" "${API}/main.sh" </dev/null > "${work}/nojq.out" 2>"${work}/nojq.err"
nojq_rc=$?
if [[ "${nojq_rc}" -eq 0 ]]; then
    bad "jq-missing" "exit 0"
elif [[ -s "${work}/nojq.out" ]]; then
    bad "jq-missing" "stdout was not empty"
elif ! grep -q 'jq is required' "${work}/nojq.err"; then
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
expect_code "unknown-action" "UNKNOWN_ACTION" && [[ "$(field '.request')" == "null" ]] && ! grep -q 'nope' "${log}" && ok "unknown-action"

reset_mocks
run_serve "{\"apiVersion\":1,\"action\":\"../ping\",\"args\":{}}"
expect_code "action-path" "UNKNOWN_ACTION" && [[ ! -s "${argv}" ]] && ok "action-path"

reset_mocks
python_payload="$(dd if=/dev/zero bs=65537 count=1 2>/dev/null | tr '\0' 'a')"
run_serve "${python_payload}"
expect_code "request-too-big" "INVALID_REQUEST" && ok "request-too-big"

# direct read bounds
empty_out="$(printf '' | cockpit-read-request)"
empty_rc=$?
if [[ "${empty_rc}" -eq 1 && -z "${empty_out}" ]]; then
    ok "read-empty"
else
    bad "read-empty" "rc ${empty_rc}"
fi
big="$(dd if=/dev/zero bs=65537 count=1 2>/dev/null | tr '\0' 'b')"
big_out="$(printf '%s' "${big}" | cockpit-read-request)"
big_rc=$?
if [[ "${big_rc}" -eq 2 && -z "${big_out}" ]]; then
    ok "read-oversize"
else
    bad "read-oversize" "rc ${big_rc} bytes ${#big_out}"
fi

mkfifo "${work}/slow.fifo"
sleep 30 > "${work}/slow.fifo" &
slow_hold=$!
read_start="${SECONDS}"
cockpit-read-request < "${work}/slow.fifo" > "${work}/slow.out" 2>"${work}/slow.err"
slow_rc=$?
slow_elapsed=$((SECONDS - read_start))
kill -KILL "${slow_hold}" 2>/dev/null || true
wait "${slow_hold}" 2>/dev/null || true
rm -f "${work}/slow.fifo"
if [[ "${slow_rc}" -eq 3 && "${slow_elapsed}" -ge 4 && "${slow_elapsed}" -le 8 ]]; then
    ok "read-wait-bound"
else
    bad "read-wait-bound" "rc ${slow_rc} elapsed ${slow_elapsed}"
fi

# --- contracts ---
expect_contract() {
    local name contract value want got
    name="${1}"
    contract="${2}"
    value="${3}"
    want="${4}"
    cockpit-validate-contract "${contract}" "${value}"
    got=$?
    if [[ "${got}" -eq "${want}" ]]; then
        ok "${name}"
    else
        bad "${name}" "rc ${got} want ${want}"
    fi
}

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
expect_contract "keyword-rejected" '{"type":"string","minLength":1}' '"a"' 2
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
if [[ "$?" -eq 0 ]]; then
    ok "ping-metadata"
else
    bad "ping-metadata" "rc $?"
fi
cockpit-validate-capability other "${good_cap}"
if [[ "$?" -eq 1 ]]; then
    ok "metadata-action-mismatch"
else
    bad "metadata-action-mismatch" "rc $?"
fi
cockpit-validate-capability ping "{" 2>/dev/null
if [[ "$?" -eq 1 ]]; then
    ok "metadata-malformed"
else
    bad "metadata-malformed" "rc $?"
fi
retired_cap="$(printf '%s' "${good_cap}" | jq -c '.status="retired"')"
cockpit-validate-capability ping "${retired_cap}"
if [[ "$?" -eq 2 ]]; then
    ok "metadata-retired"
else
    bad "metadata-retired" "rc $?"
fi
deprecated_cap="$(printf '%s' "${good_cap}" | jq -c '.status="deprecated"')"
cockpit-validate-capability ping "${deprecated_cap}"
if [[ "$?" -eq 0 ]]; then
    ok "metadata-deprecated"
else
    bad "metadata-deprecated" "rc $?"
fi
bad_kw="$(printf '%s' "${good_cap}" | jq -c '.input.minLength=1')"
cockpit-validate-capability ping "${bad_kw}"
if [[ "$?" -eq 1 ]]; then
    ok "metadata-unknown-keyword"
else
    bad "metadata-unknown-keyword" "rc $?"
fi

mkdir -p "${work}/missing"
cockpit-load-capability "${work}/missing"
if [[ "$?" -eq 1 ]]; then
    ok "metadata-missing-file"
else
    bad "metadata-missing-file" "rc $?"
fi
dd if=/dev/zero bs=65537 count=1 2>/dev/null | tr '\0' 'c' > "${work}/big.json"
mkdir -p "${work}/bigmod"
cp "${work}/big.json" "${work}/bigmod/capability.json"
cockpit-load-capability "${work}/bigmod"
if [[ "$?" -eq 1 ]]; then
    ok "metadata-too-big"
else
    bad "metadata-too-big" "rc $?"
fi
ln -s "${API}/modules/ping/capability.json" "${work}/cap.link"
mkdir -p "${work}/linkmod"
ln -s "${work}/cap.link" "${work}/linkmod/capability.json"
cockpit-load-capability "${work}/linkmod"
if [[ "$?" -eq 1 ]]; then
    ok "metadata-symlink"
else
    bad "metadata-symlink" "rc $?"
fi

# --- ping module reports the real uid ---
ping_out="$(cockpit-module-ping)"
if [[ "${ping_out}" == "{\"pong\":true,\"uid\":${EUID}}" ]]; then
    ok "ping-real-uid"
else
    bad "ping-real-uid" "${ping_out}"
fi

# --- dispatch ---
list_out="$(cockpit-dispatch-action list)"
if printf '%s' "${list_out}" | jq -e 'length == 2 and .[0].action == "ping" and .[0].function == "cockpit-module-ping" and .[0].realm == "podshift" and .[1].action == "capabilities" and .[1].function == "cockpit-module-capabilities" and .[1].realm == "root"' >/dev/null; then
    ok "dispatch-lists-actions"
else
    bad "dispatch-lists-actions" "${list_out}"
fi
cap_lookup="$(cockpit-dispatch-action lookup capabilities)"
if printf '%s' "${cap_lookup}" | jq -e '.action == "capabilities" and .function == "cockpit-module-capabilities" and .realm == "root"' >/dev/null; then
    ok "dispatch-lists-capabilities"
else
    bad "dispatch-lists-capabilities" "${cap_lookup}"
fi

# --- session script refuses this uid ---
sess_out="$(bash "${API}/fn/cockpit-run-in-session.sh" ping 2>"${work}/sess.err")"
sess_rc=$?
if [[ "${sess_rc}" -ne 0 && -z "${sess_out}" ]] && ! printf '%s' "${sess_out}" | grep -q '{'; then
    ok "session-requires-uid-300"
else
    bad "session-requires-uid-300" "rc ${sess_rc} out ${sess_out}"
fi

if grep -nE '(^|[[:space:]])source[[:space:]].*cockpit-run-in-session' "${API}/main.sh" "${API}/fn/cockpit-enter-session.sh" "${API}/fn/cockpit-run-module.sh" "${API}/fn/cockpit-dispatch-action.sh" >/dev/null; then
    bad "root-does-not-source-session" "a root helper sources the session script"
else
    ok "root-does-not-source-session"
fi
if grep -nE '(^|[^[:alnum:]_])eval[[:space:]]' "${API}/main.sh" "${API}/fn/"*.sh "${API}/modules/"*/module.sh >/dev/null; then
    bad "no-eval" "eval is present"
else
    ok "no-eval"
fi

# --- handler paths. These call cockpit-serve, so the outer process is not switched to root. ---
version="$(get-podshift-version)"

reset_mocks
MODE="emit"
EMIT='{"pong":true,"uid":300}'
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
if expect_code "ping-mock-session" "OK"; then
    if [[ "$(field '.data.pong')" == "true" && "$(field '.data.uid')" == "300" && "$(field '.request.action')" == "ping" && "$(field '.request.args | length')" == "0" && "$(field '.podshift.version')" == "${version}" && "$(field '.podshift.apiVersion')" == "1" && "$(field '.status.ok')" == "true" ]]; then
        if grep -q 'action=ping code=OK duration_ms=' "${log}" && ! grep -q '{' "${log}"; then
            ok "ping-mock-session"
        else
            bad "ping-mock-session" "log $(cat "${log}")"
        fi
    else
        bad "ping-mock-session" "${LAST_OUT}"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"pong":true,"uid":300}'
run_serve "{\"apiVersion\":1,\"action\":\"ping\",\"args\":{\"token\":\"${secret}\"}}"
if expect_code "ping-invalid-args" "INVALID_ARGS"; then
    if [[ ! -s "${argv}" && "$(field '.request.args')" == "null" ]] && ! printf '%s%s%s' "${LAST_OUT}" "${LAST_ERR}" "$(cat "${log}")" | grep -q "${secret}"; then
        ok "ping-invalid-args"
    else
        bad "ping-invalid-args" "module ran or secret leaked"
    fi
fi

reset_mocks
run_serve '{"apiVersion":1,"action":"capabilities","args":{}}'
if expect_code "capabilities-lists-actions" "OK"; then
    if [[ "$(field '.status.message')" == "Action completed" && "$(field '.status.ok')" == "true" && "$(field '.request.action')" == "capabilities" && "$(field '.request.args | length')" == "0" ]]; then
        if printf '%s' "${LAST_OUT}" | jq -e '
            (.data.actions | length) == 2
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
        ' >/dev/null; then
            if grep -q 'action=capabilities code=OK duration_ms=' "${log}" && ! grep -q '{' "${log}"; then
                ok "capabilities-lists-actions"
            else
                bad "capabilities-lists-actions" "log $(cat "${log}")"
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
    if [[ ! -s "${argv}" ]]; then
        ok "capabilities-root-realm-no-session"
    else
        bad "capabilities-root-realm-no-session" "argv $(cat "${argv}")"
    fi
fi

reset_mocks
run_serve "{\"apiVersion\":1,\"action\":\"capabilities\",\"args\":{\"token\":\"${secret}\"}}"
if expect_code "capabilities-invalid-args" "INVALID_ARGS"; then
    if [[ ! -s "${argv}" && "$(field '.request.args')" == "null" ]] && ! printf '%s%s%s' "${LAST_OUT}" "${LAST_ERR}" "$(cat "${log}")" | grep -q "${secret}"; then
        ok "capabilities-invalid-args"
    else
        bad "capabilities-invalid-args" "module ran or secret leaked"
    fi
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
expect_code "realm-unavailable" "REALM_UNAVAILABLE" && [[ "$(field '.data')" == "null" ]] && ok "realm-unavailable"
if printf '%s' "${LAST_ERR}" | grep -q 'podshift-api: systemd-run: mock: tunnel failed'; then
    ok "realm-unavailable-shows-reason"
else
    bad "realm-unavailable-shows-reason" "stderr=${LAST_ERR}"
fi

# The mock must refuse a named FIFO or a regular file, as real systemd-run does, or the pipe fix is not tested.
reset_mocks
fifo_dir="${work}/fifo-check"
mkdir -p "${fifo_dir}"
mkfifo "${fifo_dir}/fifo"
cat "${fifo_dir}/fifo" >/dev/null &
fc_reader=$!
COCKPIT_TEST_ARGV="${argv}" COCKPIT_TEST_SYSTEMD_MODE="emit" COCKPIT_TEST_EMIT='{}' \
    "${work}/systemd-run" bash cockpit-run-in-session.sh ping >"${fifo_dir}/fifo" 2>/dev/null
fc_named=$?
wait "${fc_reader}" 2>/dev/null
COCKPIT_TEST_ARGV="${argv}" COCKPIT_TEST_SYSTEMD_MODE="emit" COCKPIT_TEST_EMIT='{}' \
    "${work}/systemd-run" bash cockpit-run-in-session.sh ping 2>/dev/null | cat >/dev/null
fc_anon="${PIPESTATUS[0]}"
COCKPIT_TEST_ARGV="${argv}" COCKPIT_TEST_SYSTEMD_MODE="emit" COCKPIT_TEST_EMIT='{}' \
    "${work}/systemd-run" bash cockpit-run-in-session.sh ping 2>"${fifo_dir}/err" | cat >/dev/null
fc_errfile="${PIPESTATUS[0]}"
rm -rf "${fifo_dir}"
if [[ "${fc_named}" -ne 0 && "${fc_errfile}" -ne 0 && "${fc_anon}" -eq 0 ]]; then
    ok "mock-refuses-fifo-or-file"
else
    bad "mock-refuses-fifo-or-file" "named=${fc_named} errfile=${fc_errfile} anonymous=${fc_anon}"
fi

reset_mocks
MODE="nonzero"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "module-nonzero" "INTERNAL" && [[ "$(field '.status.code')" != "REALM_UNAVAILABLE" ]] && ok "module-nonzero"

reset_mocks
MODE="stray"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "module-stray" "INTERNAL" && ! printf '%s%s' "${LAST_OUT}" "${LAST_ERR}" | grep -q 'LEAKED-MODULE-OUTPUT' && ok "module-stray"

reset_mocks
MODE="twovalue"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "module-two-values" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "module-two-values"

reset_mocks
MODE="baduid"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "output-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ! printf '%s%s' "${LAST_OUT}" "${LAST_ERR}" | grep -q '999' && ok "output-contract"

reset_mocks
MODE="run"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
if expect_code "session-script-through-tunnel" "INTERNAL"; then
    if grep -q -- '--machine=podshift@.host' "${argv}" && grep -q -- '--user' "${argv}" && grep -q -- '--wait' "${argv}" && grep -q -- '--pipe' "${argv}" && grep -q -- '--quiet' "${argv}" && grep -q -- '--collect' "${argv}" && grep -q 'cockpit-run-in-session.sh' "${argv}"; then
        ok "session-script-through-tunnel"
    else
        bad "session-script-through-tunnel" "argv $(cat "${argv}")"
    fi
fi

reset_mocks
MODE="oversize"
over_start="${SECONDS}"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
over_elapsed=$((SECONDS - over_start))
over_child=""
[[ -f "${child}" ]] && over_child="$(cat "${child}")"
if expect_code "output-bound" "INTERNAL"; then
    if [[ "${over_elapsed}" -lt 5 && -n "${over_child}" ]] && ! still_alive "${over_child}"; then
        ok "output-bound"
    else
        bad "output-bound" "elapsed ${over_elapsed} child ${over_child}"
        [[ -n "${over_child}" ]] && kill -KILL "${over_child}" 2>/dev/null || true
    fi
fi

reset_mocks
MODE="timeout"
time_start="${SECONDS}"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
time_elapsed=$((SECONDS - time_start))
time_child=""
[[ -f "${child}" ]] && time_child="$(cat "${child}")"
if expect_code "time-bound" "INTERNAL"; then
    if [[ "${time_elapsed}" -ge 8 && "${time_elapsed}" -le 20 && -n "${time_child}" ]] && ! still_alive "${time_child}"; then
        ok "time-bound"
    else
        bad "time-bound" "elapsed ${time_elapsed} child ${time_child}"
        [[ -n "${time_child}" ]] && kill -KILL "${time_child}" 2>/dev/null || true
    fi
fi

# direct descendant cleanup
sleep 60 &
tree_pid=$!
cockpit-stop-process-tree "${tree_pid}"
if still_alive "${tree_pid}"; then
    bad "stop-process-tree" "pid ${tree_pid} still alive"
    kill -KILL "${tree_pid}" 2>/dev/null || true
else
    ok "stop-process-tree"
fi

# logging sanitises caller text and survives logger failure
reset_mocks
PATH="${work}:${PATH}" COCKPIT_TEST_LOG="${log}" COCKPIT_TEST_LOGGER_FAIL="" cockpit-log-request "${secret}" "OK;rm" "12ms" >/dev/null
if grep -q 'action=unknown-action code=INTERNAL duration_ms=0' "${log}" && ! grep -q "${secret}" "${log}"; then
    ok "log-sanitises"
else
    bad "log-sanitises" "$(cat "${log}")"
fi
reset_mocks
LOGGER_FAIL=1
MODE="emit"
EMIT='{"pong":true,"uid":300}'
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
if expect_code "log-failure-keeps-json" "OK"; then
    if printf '%s' "${LAST_ERR}" | grep -q 'journal logging failed'; then
        ok "log-failure-keeps-json"
    else
        bad "log-failure-keeps-json" "stderr ${LAST_ERR}"
    fi
fi

# retired and deprecated fixtures, root realm, so the session tunnel is not used
fix="${work}/fixture"
mkdir -p "${fix}"
cat > "${fix}/module.sh" << 'EOF'
#!/usr/bin/env bash
cockpit-module-demo() {
    printf '%s\n' '{"ok":true}'
}
EOF
cat > "${fix}/capability.json" << 'EOF'
{
  "action": "demo",
  "name": "Demo",
  "description": "Fixture action used only by the handler test.",
  "status": "deprecated",
  "input": {"type": "object", "properties": {}, "additionalProperties": false},
  "output": {"type": "object", "properties": {"ok": {"type": "boolean"}}, "required": ["ok"], "additionalProperties": false}
}
EOF
touch "${work}/ran"
rm -f "${work}/ran"
run_fixture() {
    local status_word payload errfile
    status_word="${1}"
    payload="${2}"
    jq --arg status "${status_word}" '.status=$status' "${fix}/capability.json" > "${fix}/capability.tmp"
    mv "${fix}/capability.tmp" "${fix}/capability.json"
    errfile="$(mktemp)"
    LAST_OUT="$(
        printf '%s' "${payload}" | PATH="${work}:${PATH}" COCKPIT_TEST_LOG="${log}" \
            FIXTURE="${fix}" RAN="${work}/ran" \
            bash -c '
                set +e
                source "$1"
                cockpit-dispatch-action() {
                    local mode action
                    mode="${1:-}"
                    action="${2:-}"
                    case "${mode}" in
                        list)
                            cockpit-dispatch-action lookup demo | jq -c -s "."
                            return
                            ;;
                        lookup)
                            [[ "${action}" == "demo" ]] || return 1
                            jq -n -c --arg directory "${FIXTURE}" "{action:\"demo\", function:\"cockpit-module-demo\", directory:\$directory, realm:\"root\"}"
                            ;;
                        *) return 1 ;;
                    esac
                }
                rm -f "${RAN}"
                cockpit-serve 0
                exit $?
            ' _ "${API}/main.sh" 2>"${errfile}"
    )"
    LAST_RC=$?
    LAST_ERR="$(cat "${errfile}" 2>/dev/null || true)"
    rm -f "${errfile}"
}
reset_mocks
run_fixture deprecated '{"apiVersion":1,"action":"demo","args":{}}'
if expect_code "deprecated-runs" "OK"; then
    if [[ "$(field '.data.ok')" == "true" && ! -s "${argv}" ]]; then
        ok "deprecated-runs"
    else
        bad "deprecated-runs" "${LAST_OUT}"
    fi
fi
reset_mocks
run_fixture retired '{"apiVersion":1,"action":"demo","args":{}}'
if expect_code "retired-stops" "ACTION_RETIRED"; then
    if [[ "$(field '.data')" == "null" && ! -f "${work}/ran" ]]; then
        ok "retired-stops"
    else
        bad "retired-stops" "data $(field '.data') ran=$([[ -f ${work}/ran ]] && echo yes || echo no)"
    fi
fi

# The retired fixture does not touch a file. Point the module at a writer and repeat.
cat > "${fix}/module.sh" << 'EOF'
#!/usr/bin/env bash
cockpit-module-demo() {
    : > "${RAN}"
    printf '%s\n' '{"ok":true}'
}
EOF
reset_mocks
run_fixture retired '{"apiVersion":1,"action":"demo","args":{}}'
if expect_code "retired-does-not-run" "ACTION_RETIRED"; then
    if [[ ! -f "${work}/ran" ]]; then
        ok "retired-does-not-run"
    else
        bad "retired-does-not-run" "module ran"
    fi
fi

# broken metadata does not run the module
printf '%s\n' '{' > "${fix}/capability.json"
reset_mocks
run_fixture_raw() {
    local payload errfile
    payload="${1}"
    errfile="$(mktemp)"
    LAST_OUT="$(
        printf '%s' "${payload}" | PATH="${work}:${PATH}" COCKPIT_TEST_LOG="${log}" \
            FIXTURE="${fix}" RAN="${work}/ran" \
            bash -c '
                set +e
                source "$1"
                cockpit-dispatch-action() {
                    local mode action
                    mode="${1:-}"
                    action="${2:-}"
                    case "${mode}" in
                        lookup)
                            [[ "${action}" == "demo" ]] || return 1
                            jq -n -c --arg directory "${FIXTURE}" "{action:\"demo\", function:\"cockpit-module-demo\", directory:\$directory, realm:\"root\"}"
                            ;;
                        *) return 1 ;;
                    esac
                }
                rm -f "${RAN}"
                cockpit-serve 0
                exit $?
            ' _ "${API}/main.sh" 2>"${errfile}"
    )"
    LAST_RC=$?
    LAST_ERR="$(cat "${errfile}" 2>/dev/null || true)"
    rm -f "${errfile}"
}
run_fixture_raw '{"apiVersion":1,"action":"demo","args":{}}'
if expect_code "broken-metadata" "INTERNAL"; then
    if [[ ! -f "${work}/ran" && "$(field '.data')" == "null" ]]; then
        ok "broken-metadata"
    else
        bad "broken-metadata" "module ran or data leaked"
    fi
fi

# real systemd-run cannot enter podshift@.host here. This is a live command, and it must fail closed.
reset_mocks
real_start="${SECONDS}"
real_err="$(mktemp)"
LAST_OUT="$(
    printf '%s' '{"apiVersion":1,"action":"ping","args":{}}' | PATH="${PATH}" COCKPIT_TEST_LOG="${log}" \
        bash -c 'set +e; source "$1"; cockpit-serve 0; exit $?' _ "${API}/main.sh" 2>"${real_err}"
)"
LAST_RC=$?
LAST_ERR="$(cat "${real_err}" 2>/dev/null || true)"
rm -f "${real_err}"
real_elapsed=$((SECONDS - real_start))
if expect_code "live-tunnel-unavailable" "REALM_UNAVAILABLE"; then
    if [[ "${real_elapsed}" -lt 8 ]]; then
        ok "live-tunnel-unavailable"
    else
        bad "live-tunnel-unavailable" "elapsed ${real_elapsed}"
    fi
fi

echo "NOTE: ${pass} passed, ${fail} failed. Session success was mocked. Live systemd-run was only checked for a failed tunnel."
if [[ "${fail}" -ne 0 ]]; then
    exit 2
fi
exit 0
