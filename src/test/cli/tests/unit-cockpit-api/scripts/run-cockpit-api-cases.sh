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
        dd if=/dev/zero bs=140000 count=1 2>/dev/null | tr '\0' 'A'
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
bad_kw="$(printf '%s' "${good_cap}" | jq -c '.input.maxItems=1')"
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
if printf '%s' "${list_out}" | jq -e 'length == 18 and .[0].action == "ping" and .[0].function == "cockpit-module-ping" and .[0].realm == "podshift" and .[1].action == "capabilities" and .[1].function == "cockpit-module-capabilities" and .[1].realm == "root" and .[2].action == "overview-status" and .[2].function == "cockpit-module-overview-status" and .[2].realm == "root" and .[3].action == "overview-usage" and .[3].function == "cockpit-module-overview-usage" and .[3].realm == "podshift" and .[4].action == "overview-info" and .[4].function == "cockpit-module-overview-info" and .[4].realm == "podshift" and .[5].action == "overview-config" and .[5].function == "cockpit-module-overview-config" and .[5].realm == "podshift" and .[6].action == "health-check" and .[6].function == "cockpit-module-health-check" and .[6].realm == "root" and .[7].action == "networks-list" and .[7].function == "cockpit-module-networks-list" and .[7].realm == "podshift" and .[8].action == "images-list" and .[8].function == "cockpit-module-images-list" and .[8].realm == "podshift" and .[9].action == "volumes-list" and .[9].function == "cockpit-module-volumes-list" and .[9].realm == "podshift" and .[10].action == "containers-list" and .[10].function == "cockpit-module-containers-list" and .[10].realm == "podshift" and .[11].action == "inspect" and .[11].function == "cockpit-module-inspect" and .[11].realm == "podshift" and .[12].action == "secrets-list" and .[12].function == "cockpit-module-secrets-list" and .[12].realm == "podshift" and .[13].action == "services-list" and .[13].function == "cockpit-module-services-list" and .[13].realm == "podshift" and .[14].action == "service-view" and .[14].function == "cockpit-module-service-view" and .[14].realm == "podshift" and .[15].action == "service-logs" and .[15].function == "cockpit-module-service-logs" and .[15].realm == "root" and .[16].action == "quadlets-list" and .[16].function == "cockpit-module-quadlets-list" and .[16].realm == "podshift" and .[17].action == "quadlet-view" and .[17].function == "cockpit-module-quadlet-view" and .[17].realm == "podshift"' >/dev/null; then
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
if grep -nE '(^|[^[:alnum:]_])eval[[:space:]]' "${API}/main.sh" "${API}/fn/"*.sh "${API}/fn/"*/*.sh "${API}/modules/"*/module.sh >/dev/null; then
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
    if [[ ! -s "${argv}" && "$(field '.request.args')" == "null" && "$(field '.status.message')" == "Given arguments are not supported: token." ]] && ! printf '%s%s%s' "${LAST_OUT}" "${LAST_ERR}" "$(cat "${log}")" | grep -q "${secret}"; then
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
            (.data.actions | length) == 18
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

# --- overview modules ---
# shellcheck source=/dev/null
source "${API}/fn/overview/cockpit-overview-unit-state.sh"
# shellcheck source=/dev/null
source "${API}/fn/overview/cockpit-overview-ssh-port.sh"
# shellcheck source=/dev/null
source "${API}/modules/overview-status/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/overview-usage/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/overview-info/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/overview-config/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/health-check/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/networks-list/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/images-list/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/volumes-list/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/containers-list/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/inspect/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/secrets-list/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/services-list/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/service-view/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/service-logs/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/quadlets-list/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/quadlet-view/module.sh"

expect_row_contract() {
    local name payload
    name="${1}"
    payload="${2}"
    if printf '%s' "${payload}" | jq -e '
        (.rows | type) == "array"
        and all(.rows[]; (.id | type) == "string" and (.id | test("^[a-z0-9_]+$"))
            and (.label | type) == "string" and (.label | length) > 0
            and (.value == null or (.value | type) == "string")
            and (
                (keys | sort) == ["id","label","value"]
                or (
                    (keys | sort) == ["id","label","unit","value"]
                    and (.unit | type) == "string"
                    and (.unit | length) > 0
                )
                or (
                    (keys | sort) == ["id","label","scope","unit","value"]
                    and (.unit | type) == "string"
                    and (.unit | length) > 0
                    and (.scope == "user" or .scope == "system")
                )
            ))
    ' >/dev/null; then
        ok "${name}"
    else
        bad "${name}" "${payload}"
    fi
}

for cap_action in overview-status overview-usage overview-info overview-config health-check networks-list images-list volumes-list containers-list inspect secrets-list services-list service-view service-logs quadlets-list quadlet-view; do
    cap_file="${API}/modules/${cap_action}/capability.json"
    cap_raw="$(cat "${cap_file}")"
    cockpit-validate-capability "${cap_action}" "${cap_raw}"
    if [[ "$?" -eq 0 ]]; then
        ok "${cap_action}-metadata"
    else
        bad "${cap_action}-metadata" "rc $?"
    fi
done

# overview-status is root realm: the handler runs the real module in this process.
reset_mocks
run_serve '{"apiVersion":1,"action":"overview-status","args":{}}'
if expect_code "overview-status-handler" "OK"; then
    if [[ "$(field '.status.message')" == "Action completed" && "$(field '.data | .rows | length')" == "10" ]]; then
        if printf '%s' "$(field '.data')" | jq -e '[.rows[].id] == ["podman_socket","auto_update","drop_watcher","drop_safety","quadlet_validator","quadlet_installer","tmpfiles_setup","firewall","fail2ban","ssh_port"]' >/dev/null; then
            ok "overview-status-handler"
        else
            bad "overview-status-handler" "${LAST_OUT}"
        fi
    else
        bad "overview-status-handler" "${LAST_OUT}"
    fi
fi

cockpit-overview-status-user-show() {
    case "${1}" in
        podman.socket) printf 'LoadState=loaded\nActiveState=active\nSubState=listening\n' ;;
        podman-auto-update.timer) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-drop.path) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-drop-safety.timer) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-qdl-validate.path) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        podshift-qdl-install.path) printf 'LoadState=loaded\nActiveState=active\nSubState=waiting\n' ;;
        systemd-tmpfiles-setup.service) printf 'LoadState=loaded\nActiveState=active\nSubState=exited\n' ;;
        *) printf 'LoadState=not-found\nActiveState=inactive\nSubState=dead\n' ;;
    esac
}
cockpit-overview-status-system-show() {
    case "${1}" in
        firewalld.service) printf 'LoadState=loaded\nActiveState=active\nSubState=running\n' ;;
        fail2ban.service) printf 'LoadState=not-found\nActiveState=inactive\nSubState=dead\n' ;;
        *) printf 'LoadState=not-found\nActiveState=inactive\nSubState=dead\n' ;;
    esac
}
cockpit-overview-status-sshd-t() {
    printf 'port 1022\npasswordauthentication no\n'
}
status_out="$(cockpit-module-overview-status)"
if printf '%s' "${status_out}" | jq -e '
    [.rows[].id] == ["podman_socket","auto_update","drop_watcher","drop_safety","quadlet_validator","quadlet_installer","tmpfiles_setup","firewall","fail2ban","ssh_port"]
    and .rows[0].value == "Running"
    and .rows[1].value == "Waiting"
    and .rows[6].value == "Exited"
    and .rows[7].value == "Running"
    and .rows[8].value == null
    and .rows[9].value == "1022"
    and .rows[0].unit == "podman.socket" and .rows[0].scope == "user"
    and .rows[1].unit == "podman-auto-update.timer" and .rows[1].scope == "user"
    and .rows[2].unit == "podshift-drop.path" and .rows[2].scope == "user"
    and .rows[3].unit == "podshift-drop-safety.timer" and .rows[3].scope == "user"
    and .rows[4].unit == "podshift-qdl-validate.path" and .rows[4].scope == "user"
    and .rows[5].unit == "podshift-qdl-install.path" and .rows[5].scope == "user"
    and .rows[6].unit == "systemd-tmpfiles-setup.service" and .rows[6].scope == "user"
    and .rows[7].unit == "firewalld.service" and .rows[7].scope == "system"
    and .rows[8].unit == "fail2ban.service" and .rows[8].scope == "system"
    and .rows[9].unit == "sshd.service" and .rows[9].scope == "system"
' >/dev/null; then
    expect_row_contract "overview-status-stubbed" "${status_out}"
else
    bad "overview-status-stubbed" "${status_out}"
fi

cockpit-overview-usage-service-counts() {
    printf '1 / 2\n'
}
cockpit-overview-usage-quadlet-counts() {
    case "${1}" in
        all) printf '0\n' ;;
    esac
}
cockpit-overview-usage-podman-counts() {
    case "${1}" in
        networks) printf '1\n' ;;
        containers) printf '2 / 4\n' ;;
        volumes) printf '0 / 1\n' ;;
        images) printf '2 / 5\n' ;;
        secrets) printf '0\n' ;;
    esac
}
usage_out="$(cockpit-module-overview-usage)"
if printf '%s' "${usage_out}" | jq -e '
    [.rows[].id] == ["services","networks","containers","volumes","images","quadlets","secrets"]
    and .rows[0].value == "1 / 2"
    and .rows[1].value == "1"
    and .rows[2].value == "2 / 4"
    and .rows[3].value == "0 / 1"
    and .rows[4].value == "2 / 5"
    and .rows[5].value == "0"
    and .rows[6].value == "0"
' >/dev/null; then
    expect_row_contract "overview-usage-stubbed" "${usage_out}"
else
    bad "overview-usage-stubbed" "${usage_out}"
fi

cockpit-overview-info-os-release() { printf 'PRETTY_NAME="Fedora Linux 45"\n' ; }
cockpit-overview-info-podman-version() { printf '5.0.0\n' ; }
cockpit-overview-info-podshift-version() { printf '0.1.0\n' ; }
cockpit-overview-info-fail2ban-version() { return 0 ; }
info_out="$(cockpit-module-overview-info)"
if printf '%s' "${info_out}" | jq -e '
    [.rows[].id] == ["os","podman","podshift","fail2ban"]
    and .rows[0].value == "Fedora Linux 45"
    and .rows[1].value == "5.0.0"
    and .rows[2].value == "0.1.0"
    and .rows[3].value == null
' >/dev/null; then
    expect_row_contract "overview-info-stubbed" "${info_out}"
else
    bad "overview-info-stubbed" "${info_out}"
fi

cockpit-overview-config-tsv-text() { return 0; }
cockpit-overview-config-load() {
    TSV_ENV=dev
    TSV_NW1=192.0.2.10
    TSV_NW3=192.0.2.30
    unset TSV_NW2 TSV_NW4 TSV_NW5 TSV_NW6 TSV_NW7 TSV_NW8
}
config_out="$(cockpit-module-overview-config)"
if printf '%s' "${config_out}" | jq -e '
    [.rows[].id] == ["tsv_env","tsv_nw1","tsv_nw3"]
    and .rows[0].value == "dev"
    and .rows[1].value == "192.0.2.10"
    and .rows[2].value == "192.0.2.30"
' >/dev/null; then
    expect_row_contract "overview-config-stubbed" "${config_out}"
else
    bad "overview-config-stubbed" "${config_out}"
fi

cockpit-overview-config-load() {
    unset TSV_ENV TSV_NW1 TSV_NW2 TSV_NW3 TSV_NW4 TSV_NW5 TSV_NW6 TSV_NW7 TSV_NW8
}
cockpit-overview-config-tsv-text() { return 0; }
config_out="$(cockpit-module-overview-config)"
if printf '%s' "${config_out}" | jq -e '
    (.rows | length) == 1
    and .rows[0].id == "tsv_env"
    and .rows[0].label == "TSV_ENV"
    and .rows[0].value == null
' >/dev/null; then
    expect_row_contract "overview-config-no-nw" "${config_out}"
else
    bad "overview-config-no-nw" "${config_out}"
fi

cockpit-overview-config-load() {
    TSV_ENV=dev
    TSV_NW1=192.0.2.10
    unset TSV_NW2 TSV_NW3 TSV_NW4 TSV_NW5 TSV_NW6 TSV_NW7 TSV_NW8
}
cockpit-overview-config-tsv-text() {
    printf '# comment\nTSV_ENV=ignored\nTSV_ZED=z\nTSV_APP=ok\nTSV_bad=no\nTSV_EMPTY=\n'
}
config_out="$(cockpit-module-overview-config)"
if printf '%s' "${config_out}" | jq -e '
    (.rows | length) == 4
    and [.rows[].id] == ["tsv_env","tsv_nw1","tsv_app","tsv_zed"]
    and .rows[0].value == "dev"
    and .rows[1].value == "192.0.2.10"
    and .rows[2].id == "tsv_app" and .rows[2].label == "TSV_APP" and .rows[2].value == "ok"
    and .rows[3].id == "tsv_zed" and .rows[3].label == "TSV_ZED" and .rows[3].value == "z"
' >/dev/null; then
    expect_row_contract "overview-config-user-keys" "${config_out}"
else
    bad "overview-config-user-keys" "${config_out}"
fi

cockpit-health-check-run() {
    printf '%s\n' \
        $'host\tos\tOS\tOK\tFedora Linux 45\t' \
        $'config\tconfig-files\tConfig files\tINFO\tno custom keys yet\tpodshift --help config' \
        $'network\tregistries\tRegistries\tOK\tall reachable\t'
}
health_out="$(cockpit-module-health-check)"
if printf '%s' "${health_out}" | jq -e '
    (.groups | length) == 3
    and .groups[0].id == "host" and .groups[0].label == "Host"
    and .groups[0].rows[0] == {"id":"os","label":"OS","state":"ok","value":"Fedora Linux 45","fix":null}
    and .groups[1].id == "config" and .groups[1].label == "Configuration"
    and .groups[1].rows[0].state == "note"
    and .groups[1].rows[0].fix == "podshift --help config"
    and .groups[2].id == "network" and .groups[2].label == "Network and monitoring"
    and .summary.state == "ok"
    and .summary.label == "Healthy (2 passed, 1 note)"
    and .summary.passed == 2
    and .summary.notes == 1
    and .summary.warnings == 0
    and .summary.failed == 0
' >/dev/null; then
    ok "health-check-stubbed"
else
    bad "health-check-stubbed" "${health_out}"
fi

# networks-list: podman and systemctl are stubbed; Quadlet and user unit files are real files.
net_home="${work}/networks-home"
mkdir -p "${net_home}/quadlets/shop.qdl-bundle" "${net_home}/.config/systemd/user"
printf '[Network]\nNetworkName=tsv-nw1\nSubnet=10.89.0.0/24\n' > "${net_home}/quadlets/shop.qdl-bundle/tsv-nw1.network"
printf '[Network]\nSubnet=10.91.0.0/24\n' > "${net_home}/quadlets/plain.network"
printf '[Service]\nType=oneshot\nExecStart=/usr/bin/podman network create --ignore --subnet 10.202.0.0/24 example-unit\n' > "${net_home}/.config/systemd/user/example-unit-network.service"
printf '[Service]\nExecStart=/usr/bin/podman run --network tsv-nw1 img\n' > "${net_home}/.config/systemd/user/other.service"
cockpit-networks-list-podman() {
    case "${1-} ${2-}" in
        "network ls")
            printf '%s\n' '[{"name":"podman"},{"name":"tsv-nw1"},{"name":"systemd-plain"},{"name":"example-unit"},{"name":"loose"}]'
            ;;
        "network inspect")
            printf '%s\n' '[
                {"name":"podman","id":"2f259bab93aaaaa2542b","driver":"bridge","network_interface":"podman0","subnets":[{"subnet":"10.88.0.0/16","gateway":"10.88.0.1"}],"ipv6_enabled":false,"internal":false,"dns_enabled":false},
                {"name":"tsv-nw1","id":"3f1c2b8e9d0a4b5c6d7e","driver":"bridge","network_interface":"podman1","subnets":[{"subnet":"10.89.0.0/24","gateway":"10.89.0.1"}],"ipv6_enabled":false,"internal":false,"dns_enabled":true,"labels":{"PODMAN_SYSTEMD_UNIT":"tsv-nw1-network.service"},"containers":{"a1b2c3":{"name":"shop","interfaces":{"eth0":{"subnets":[{"ipnet":"10.89.0.10/24"}]}}}}},
                {"name":"systemd-plain","id":"5a5a5a5a5a5a5a5a5a5a","driver":"bridge","subnets":[{"subnet":"10.91.0.0/24","gateway":"10.91.0.1"}],"ipv6_enabled":false,"internal":false,"dns_enabled":true},
                {"name":"example-unit","id":"9e8d7c6b5a4938271605","driver":"bridge","subnets":[{"subnet":"10.202.0.0/24","gateway":"10.202.0.1"}],"ipv6_enabled":false,"internal":false,"dns_enabled":true},
                {"name":"loose","id":"1111111111111111","driver":"bridge","subnets":[],"ipv6_enabled":false,"internal":true,"dns_enabled":false}
            ]'
            ;;
        *)
            return 1
            ;;
    esac
}
cockpit-networks-list-systemctl() {
    case "${*}" in
        *tsv-nw1-network.service) printf 'active\n' ;;
        *example-unit-network.service) printf 'inactive\n' ;;
        *) printf 'inactive\n' ;;
    esac
}
networks_out="$(HOME="${net_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${net_home}/quadlets" cockpit-module-networks-list)"
networks_contract="$(jq -c '.output' "${API}/modules/networks-list/capability.json")"
if printf '%s' "${networks_out}" | jq -e '
    ([.items[].id] == ["example-unit","loose","podman","systemd-plain","tsv-nw1"])
    and ([.items[] | {(.id): .source}] | add) == {"example-unit":"unit","loose":"unmanaged","podman":"builtin","systemd-plain":"quadlet","tsv-nw1":"quadlet"}
    and ([.items[] | {(.id): .status}] | add) == {"example-unit":"Unused","loose":"Unused","podman":"Unused","systemd-plain":"Unused","tsv-nw1":"In use"}
    and (.items[] | select(.id == "tsv-nw1") | .groups[0]) == {"id":"systemd","label":"Systemd","rows":[
        {"id":"unit","label":"Unit name","value":"tsv-nw1-network.service"},
        {"id":"unit_state","label":"Unit state","value":"active"},
        {"id":"file","label":"File","value":"~/quadlets/shop.qdl-bundle/tsv-nw1.network"},
        {"id":"app","label":"App","value":"shop"}]}
    and ((.items[] | select(.id == "systemd-plain") | .groups[0].rows | map(.id)) == ["unit","unit_state","file"])
    and ((.items[] | select(.id == "example-unit") | .groups[0].rows) == [
        {"id":"unit","label":"Unit name","value":"example-unit-network.service"},
        {"id":"unit_state","label":"Unit state","value":"inactive"},
        {"id":"file","label":"File","value":"~/.config/systemd/user/example-unit-network.service"}])
    and ((.items[] | select(.id == "tsv-nw1") | .groups[1].rows) == [{"id":"shop","label":"shop","value":"10.89.0.10"}])
' >/dev/null && cockpit-validate-contract "${networks_contract}" "${networks_out}"; then
    ok "networks-list-stubbed"
else
    bad "networks-list-stubbed" "${networks_out}"
fi

cockpit-networks-list-podman() {
    case "${1-} ${2-}" in
        "network ls") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
networks_out="$(HOME="${work}/networks-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/networks-none" cockpit-module-networks-list)"
if [[ "${networks_out}" == '{"items":[]}' ]]; then
    ok "networks-list-empty"
else
    bad "networks-list-empty" "${networks_out}"
fi

cockpit-networks-list-podman() {
    return 1
}
if networks_out="$(HOME="${work}/networks-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/networks-none" cockpit-module-networks-list 2>/dev/null)"; then
    bad "networks-list-podman-fails" "${networks_out}"
else
    ok "networks-list-podman-fails"
fi

# images-list: podman and systemctl are stubbed; Quadlet .image and .container files are real files.
img_home="${work}/images-home"
mkdir -p "${img_home}/quadlets/shop.qdl-bundle"
printf '[Image]\nImage=docker.io/library/busybox:latest\n' > "${img_home}/quadlets/shop.qdl-bundle/cache.image"
printf '[Image]\nImage=quay.io/missing/image\n' > "${img_home}/quadlets/missing.image"
printf '[Container]\nImage=docker.io/library/nginx:1.27\n' > "${img_home}/quadlets/shop.qdl-bundle/web.container"
cockpit-images-list-podman() {
    case "${1-} ${2-}" in
        "image ls")
            printf '%s\n' '[{"Id":"e1c50b84a672c4e6a8c0"},{"Id":"9f1c3e28b4d1a3c5e7f9"},{"Id":"abbc135a7d39c0e8a2fd"},{"Id":"abbc135a7d39c0e8a2fd"},{"Id":"0123456789ab01234567"}]'
            ;;
        "image inspect")
            printf '%s\n' '[
                {"Id":"0123456789ab01234567","RepoTags":[],"Created":"2026-11-10T09:00:00Z","Architecture":"amd64","Os":"linux","Size":512},
                {"Id":"9f1c3e28b4d1a3c5e7f9","RepoTags":["docker.io/library/nginx:1.27"],"Digest":"sha256:c8e4d91a07b2d4f6a8c0","Created":"2026-10-20T08:30:00Z","Config":{"Cmd":["nginx"]},"Architecture":"amd64","Os":"linux","Size":61900000},
                {"Id":"abbc135a7d39c0e8a2fd","RepoTags":["docker.io/library/alpine:latest","docker.io/library/alpine:3.20"],"Created":"2026-11-05T12:12:00+02:00","Config":{"Cmd":["/bin/sh"]},"Architecture":"amd64","Os":"linux","Size":8950000},
                {"Id":"e1c50b84a672c4e6a8c0","RepoTags":["docker.io/library/busybox:latest"],"Created":"2026-09-14T00:00:00Z","Config":{"Cmd":["sh"]},"Architecture":"arm64","Os":"linux","Size":4430000}
            ]'
            ;;
        "ps -a")
            printf '%s\n' '[
                {"Id":"1a2b3c4d5e6f","Names":["web"],"ImageID":"9f1c3e28b4d1a3c5e7f9","State":"running","Labels":{"PODMAN_SYSTEMD_UNIT":"web.service"}},
                {"Id":"2b3c4d5e6f7a","Names":["loose"],"ImageID":"abbc135a7d39c0e8a2fd","State":"exited","Labels":null}
            ]'
            ;;
        *)
            return 1
            ;;
    esac
}
cockpit-images-list-systemctl() {
    case "${*}" in
        *cache-image.service) printf 'ActiveState=inactive\nFragmentPath=/run/user/300/systemd/generator/cache-image.service\nSourcePath=%s\n' "${img_home}/quadlets/shop.qdl-bundle/cache.image" ;;
        *web.service) printf 'ActiveState=active\nFragmentPath=/run/user/300/systemd/generator/web.service\nSourcePath=%s\n' "${img_home}/quadlets/shop.qdl-bundle/web.container" ;;
        *) printf 'ActiveState=inactive\nFragmentPath=\nSourcePath=\n' ;;
    esac
}
images_out="$(HOME="${img_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${img_home}/quadlets" cockpit-module-images-list)"
images_contract="$(jq -c '.output' "${API}/modules/images-list/capability.json")"
if printf '%s' "${images_out}" | jq -e '
    ([.items[].title] == ["<none>","alpine","busybox","nginx"])
    and ((.items[] | select(.title == "alpine") | [.id, .fullId]) == ["abbc135a7d39", "abbc135a7d39c0e8a2fd"])
    and ([.items[] | {(.title): .source}] | add) == {"<none>":"unmanaged","alpine":"unmanaged","busybox":"quadlet","nginx":"container"}
    and ([.items[] | {(.title): .status}] | add) == {"<none>":"Unused","alpine":"In use","busybox":"Unused","nginx":"In use"}
    and ((.items[] | select(.title == "alpine") | [.rows[] | select(.id == "tags" or .id == "created" or .id == "used-by") | .value])
        == ["latest, 3.20","2026-11-05T10:12:00Z","loose (Exited)"])
    and ([.items[] | {(.title): .running}] | add) == {"<none>":false,"alpine":false,"busybox":false,"nginx":true}
    and ((.items[] | select(.title == "nginx") | .rows[] | select(.id == "used-by") | .value) == "web (Running)")
    and ((.items[] | select(.title == "busybox") | .groups[1]) == {"id":"systemd","label":"Systemd","rows":[
        {"id":"unit","label":"Unit name","value":"cache-image.service"},
        {"id":"unit_state","label":"Unit state","value":"inactive"},
        {"id":"file","label":"File","value":"~/quadlets/shop.qdl-bundle/cache.image"},
        {"id":"app","label":"App","value":"shop"}]})
    and ((.items[] | select(.title == "nginx") | .groups[1].rows) == [
        {"id":"unit","label":"Unit name","value":"web.service"},
        {"id":"unit_state","label":"Unit state","value":"active"},
        {"id":"file","label":"File","value":"~/quadlets/shop.qdl-bundle/web.container"},
        {"id":"app","label":"App","value":"shop"}])
' >/dev/null && cockpit-validate-contract "${images_contract}" "${images_out}"; then
    ok "images-list-stubbed"
else
    bad "images-list-stubbed" "${images_out}"
fi

cockpit-images-list-podman() {
    case "${1-} ${2-}" in
        "image ls") printf '[]\n' ;;
        "ps -a") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
images_out="$(HOME="${work}/images-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/images-none" cockpit-module-images-list)"
if [[ "${images_out}" == '{"items":[]}' ]]; then
    ok "images-list-empty"
else
    bad "images-list-empty" "${images_out}"
fi

cockpit-images-list-podman() {
    case "${1-} ${2-}" in
        "image ls") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
if images_out="$(HOME="${work}/images-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/images-none" cockpit-module-images-list 2>/dev/null)"; then
    bad "images-list-ps-fails" "${images_out}"
else
    ok "images-list-ps-fails"
fi

cockpit-images-list-podman() {
    return 1
}
if images_out="$(HOME="${work}/images-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/images-none" cockpit-module-images-list 2>/dev/null)"; then
    bad "images-list-podman-fails" "${images_out}"
else
    ok "images-list-podman-fails"
fi

# volumes-list: podman, systemctl and du are stubbed; Quadlet .volume and .container files are real files.
vol_home="${work}/volumes-home"
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
cockpit-volumes-list-systemctl() {
    case "${*}" in
        *pgdata-volume.service) printf 'ActiveState=active\nSourcePath=%s\n' "${vol_home}/quadlets/shop.qdl-bundle/pgdata.volume" ;;
        *web.service) printf 'ActiveState=active\nFragmentPath=/run/user/300/systemd/generator/web.service\nSourcePath=%s\n' "${vol_home}/quadlets/web.container" ;;
        *db.service) printf 'ActiveState=active\nSourcePath=%s\n' "${vol_home}/quadlets/shop.qdl-bundle/db.container" ;;
        *) printf 'ActiveState=inactive\n' ;;
    esac
}
cockpit-volumes-list-du() {
    case "${1-}" in
        */pgdata/_data) printf '412000000\t%s\n' "${1}" ;;
        */web-data/_data) printf '23400\t%s\n' "${1}"; return 1 ;;
        */anon/_data) printf 'du: cannot read\n'; return 1 ;;
        *) return 124 ;;
    esac
}
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
' >/dev/null && cockpit-validate-contract "${volumes_contract}" "${volumes_out}"; then
    ok "volumes-list-stubbed"
else
    bad "volumes-list-stubbed" "${volumes_out}"
fi

cockpit-volumes-list-du() {
    return 1
}
volumes_out="$(HOME="${vol_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${vol_home}/quadlets" cockpit-module-volumes-list)"
if printf '%s' "${volumes_out}" | jq -e '(.items | length) == 4 and ([.items[].rows[] | select(.id == "size")] == [])' >/dev/null \
    && cockpit-validate-contract "${volumes_contract}" "${volumes_out}"; then
    ok "volumes-list-du-fails"
else
    bad "volumes-list-du-fails" "${volumes_out}"
fi

cockpit-volumes-list-podman() {
    case "${1-} ${2-}" in
        "volume ls") printf '[]\n' ;;
        "ps -a") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
volumes_out="$(HOME="${work}/volumes-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/volumes-none" cockpit-module-volumes-list)"
if [[ "${volumes_out}" == '{"items":[]}' ]]; then
    ok "volumes-list-empty"
else
    bad "volumes-list-empty" "${volumes_out}"
fi

cockpit-volumes-list-podman() {
    case "${1-} ${2-}" in
        "volume ls") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
if volumes_out="$(HOME="${work}/volumes-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/volumes-none" cockpit-module-volumes-list 2>/dev/null)"; then
    bad "volumes-list-ps-fails" "${volumes_out}"
else
    ok "volumes-list-ps-fails"
fi

cockpit-volumes-list-podman() {
    return 1
}
if volumes_out="$(HOME="${work}/volumes-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/volumes-none" cockpit-module-volumes-list 2>/dev/null)"; then
    bad "volumes-list-podman-fails" "${volumes_out}"
else
    ok "volumes-list-podman-fails"
fi

# secrets-list: podman is stubbed. A SecretData field and env values in the stub must never leak.
sec_calls="${work}/secrets.calls"
: > "${sec_calls}"
cockpit-secrets-list-podman() {
    printf '%s\n' "${*}" >> "${sec_calls}"
    case "${1-} ${2-}" in
        "secret ls")
            printf '%s\n' 3c8e1f0a9b7d6c5e4f3a2b1c0 7a1b2c3d4e5f60718293a4b5c 9f8e7d6c5b4a39281706f5e4d 3c8e1f0a9b7d6c5e4f3a2b1c0
            ;;
        "secret inspect")
            [[ "${*}" == "secret inspect -- 3c8e1f0a9b7d6c5e4f3a2b1c0 7a1b2c3d4e5f60718293a4b5c 9f8e7d6c5b4a39281706f5e4d" ]] || return 125
            printf '%s\n' '[
                {"ID":"3c8e1f0a9b7d6c5e4f3a2b1c0","CreatedAt":"2026-10-02T10:15:00.1+02:00","UpdatedAt":"2026-10-02T10:15:00.1+02:00","Spec":{"Name":"db-password","Driver":{"Name":"file","Options":{"path":"/x/filedriver"}},"Labels":{}},"SecretData":"must-never-leak"},
                {"ID":"7a1b2c3d4e5f60718293a4b5c","CreatedAt":"2026-10-18T14:22:00Z","UpdatedAt":"2026-11-01T09:30:00Z","Spec":{"Name":"api-token","Driver":{"Name":"file","Options":{}},"Labels":{}}},
                {"ID":"9f8e7d6c5b4a39281706f5e4d","CreatedAt":"2026-09-20T11:00:00Z","UpdatedAt":"2026-09-20T11:00:00Z","Spec":{"Name":"registry-auth","Driver":{"Name":"pass","Options":{}},"Labels":{}}}
            ]'
            ;;
        "ps -a")
            printf '%s\n' '[{"Id":"c1"},{"Id":"c2"},{"Id":"c1"}]'
            ;;
        "container inspect")
            printf '%s\n' '[
                {"Id":"c1","Name":"shop-db","State":{"Status":"running"},"Config":{"Env":["DB_PASSWORD=must-never-leak"],"CreateCommand":["podman","run","--secret","db-password,type=env,target=DB_PASSWORD","img"]}},
                {"Id":"c2","Name":"db-backup","State":{"Status":"exited"},"Config":{"CreateCommand":["podman","run","--secret=api-token,target=/etc/token","img"],"Secrets":[{"Name":"api-token","ID":"7a1b2c3d4e5f60718293a4b5c"}]}}
            ]'
            ;;
        *)
            return 1
            ;;
    esac
}
secrets_out="$(cockpit-module-secrets-list)"
secrets_contract="$(jq -c '.output' "${API}/modules/secrets-list/capability.json")"
if printf '%s' "${secrets_out}" | jq -e '
    ([.items[].title] == ["api-token","db-password","registry-auth"])
    and ([.items[] | {(.name): [.status, .inUse, .running]}] | add) == {
        "api-token":["In use",true,false],"db-password":["In use",true,true],"registry-auth":["Unused",false,false]}
    and ((.items[] | select(.name == "db-password") | .usedBy) == [
        {"container":"shop-db","containerId":"c1","state":"running","type":"env","target":"DB_PASSWORD"}])
    and ((.items[] | select(.name == "api-token") | .usedBy) == [
        {"container":"db-backup","containerId":"c2","state":"exited","type":"file","target":"/etc/token"}])
    and ((.items[] | select(.name == "db-password") | .rows) == [
        {"id":"driver","label":"Driver","value":"file"},
        {"id":"created","label":"Created","value":"2026-10-02T08:15:00Z"},
        {"id":"updated","label":"Updated","value":"2026-10-02T08:15:00Z"},
        {"id":"used-by","label":"Used by","value":"shop-db (env DB_PASSWORD)"}])
' >/dev/null && cockpit-validate-contract "${secrets_contract}" "${secrets_out}" \
    && [[ "${secrets_out}" != *must-never-leak* && "${secrets_out}" != *SecretData* && "${secrets_out}" != *filedriver* ]] \
    && ! grep -q -- '--showsecret' "${sec_calls}" && grep -qx 'secret ls --quiet --noheading' "${sec_calls}"; then
    ok "secrets-list-stubbed"
else
    bad "secrets-list-stubbed" "${secrets_out}"
fi

# The output contract refuses an item with an extra field such as SecretData.
if cockpit-validate-contract "${secrets_contract}" '{"items":[{"id":"a","title":"a","subtitle":"a","name":"a","driver":"file","created":"","updated":"","status":"Unused","inUse":false,"running":false,"usedBy":[],"rows":[],"SecretData":"x"}]}'; then
    bad "secrets-list-contract-refuses-secret-data" "accepted"
else
    ok "secrets-list-contract-refuses-secret-data"
fi

: > "${sec_calls}"
cockpit-secrets-list-podman() {
    printf '%s\n' "${*}" >> "${sec_calls}"
    case "${1-} ${2-}" in
        "secret ls") printf '' ;;
        *) return 1 ;;
    esac
}
secrets_out="$(cockpit-module-secrets-list)"
if [[ "${secrets_out}" == '{"items":[]}' ]] && ! grep -q '^ps' "${sec_calls}"; then
    ok "secrets-list-empty"
else
    bad "secrets-list-empty" "${secrets_out}"
fi

cockpit-secrets-list-podman() {
    case "${1-} ${2-}" in
        "secret ls") printf 'a1\n' ;;
        "secret inspect") printf '[{"ID":"a1","Spec":{"Name":"a","Driver":{"Name":"file"}}}]\n' ;;
        "ps -a") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
secrets_out="$(cockpit-module-secrets-list)"
if printf '%s' "${secrets_out}" | jq -e '.items | length == 1 and .[0].status == "Unused" and .[0].usedBy == []' >/dev/null \
    && cockpit-validate-contract "${secrets_contract}" "${secrets_out}"; then
    ok "secrets-list-no-containers"
else
    bad "secrets-list-no-containers" "${secrets_out}"
fi

cockpit-secrets-list-podman() {
    case "${1-} ${2-}" in
        "secret ls") printf 'a1\n' ;;
        "secret inspect") printf '[{"ID":"a1","Spec":{"Name":"a","Driver":{"Name":"file"}}}]\n' ;;
        "ps -a") printf '[{"Id":"c1"}]\n' ;;
        *) return 1 ;;
    esac
}
if secrets_out="$(cockpit-module-secrets-list 2>/dev/null)"; then
    bad "secrets-list-inspect-fails" "${secrets_out}"
else
    ok "secrets-list-inspect-fails"
fi

cockpit-secrets-list-podman() {
    return 1
}
if secrets_out="$(cockpit-module-secrets-list 2>/dev/null)"; then
    bad "secrets-list-podman-fails" "${secrets_out}"
else
    ok "secrets-list-podman-fails"
fi

cockpit-secrets-list-podman() {
    case "${1-} ${2-}" in
        "secret ls") printf 'a1\n' ;;
        *) return 1 ;;
    esac
}
if secrets_out="$(cockpit-module-secrets-list 2>/dev/null)"; then
    bad "secrets-list-secret-inspect-fails" "${secrets_out}"
else
    ok "secrets-list-secret-inspect-fails"
fi

# quadlets-list: podman is stubbed.
qls_calls="${work}/quadlets.calls"
: > "${qls_calls}"
cockpit-quadlets-list-podman() {
    printf '%s\n' "${*}" >> "${qls_calls}"
    case "$*" in
        "quadlet ls --format json")
            cat "${repo}/src/test/unit/fixtures/cockpit-quadlets/ls-ok.json"
            ;;
        *)
            return 1
            ;;
    esac
}
qls_out="$(cockpit-module-quadlets-list)"
if printf '%s' "${qls_out}" | jq -e '
    (.items | length) == 8
    and .items[0].id == "backup.kube" and .items[0].type == "kube"
    and .items[4].id == "shop-api.container" and .items[4].title == "shop-api" and .items[4].app == "shop" and .items[4].pod == "shop.pod"
    and .items[6].id == "web.container" and .items[6].unitName == "web.service" and .items[6].status == "active/running"
    and ([.items[].description] | all(. == ""))
' >/dev/null && grep -qx "quadlet ls --format json" "${qls_calls}"; then
    ok "quadlets-list-stubbed"
else
    bad "quadlets-list-stubbed" "${qls_out}"
fi

: > "${qls_calls}"
cockpit-quadlets-list-podman() {
    printf '%s\n' "${*}" >> "${qls_calls}"
    printf '[]\n'
}
qls_out="$(cockpit-module-quadlets-list)"
if [[ "${qls_out}" == '{"items":[]}' ]]; then
    ok "quadlets-list-empty"
else
    bad "quadlets-list-empty" "${qls_out}"
fi

cockpit-quadlets-list-podman() {
    printf 'null\n'
}
qls_out="$(cockpit-module-quadlets-list)"
if [[ "${qls_out}" == '{"items":[]}' ]]; then
    ok "quadlets-list-null"
else
    bad "quadlets-list-null" "${qls_out}"
fi

cockpit-quadlets-list-podman() {
    :
}
qls_out="$(cockpit-module-quadlets-list)"
if [[ "${qls_out}" == '{"items":[]}' ]]; then
    ok "quadlets-list-blank"
else
    bad "quadlets-list-blank" "${qls_out}"
fi

cockpit-quadlets-list-podman() {
    return 1
}
if qls_out="$(cockpit-module-quadlets-list 2>/dev/null)"; then
    bad "quadlets-list-podman-fails" "${qls_out}"
else
    ok "quadlets-list-podman-fails"
fi

cockpit-quadlets-list-podman() {
    printf 'Error: unrecognized command `quadlet`\n' >&2
    return 125
}
if qls_out="$(cockpit-module-quadlets-list 2>/dev/null)"; then
    bad "quadlets-list-unsupported" "${qls_out}"
else
    ok "quadlets-list-unsupported"
fi


# containers-list: podman, systemctl and podman stats are stubbed; Quadlet .container files are real files.
ctr_home="${work}/containers-home"
ctr_stats_args="${work}/containers-stats.args"
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
    case "${*}" in
        *db.service) printf 'ActiveState=active\nLoadState=loaded\nFragmentPath=/run/user/300/systemd/generator/db.service\nSourcePath=%s\n' "${ctr_home}/quadlets/shop.qdl-bundle/db.container" ;;
        *db-backup.service) printf 'ActiveState=inactive\nLoadState=loaded\nFragmentPath=%s\n' "${ctr_home}/.config/systemd/user/db-backup.service" ;;
        *) printf 'ActiveState=inactive\nLoadState=not-found\n' ;;
    esac
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
' >/dev/null && cockpit-validate-contract "${containers_contract}" "${containers_out}" \
    && [[ "$(cat "${ctr_stats_args}")" == "${ctr_db} ${ctr_loose}" ]]; then
    ok "containers-list-stubbed"
else
    bad "containers-list-stubbed" "${containers_out}"
fi

cockpit-containers-list-stats() {
    return 124
}
containers_out="$(HOME="${ctr_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${ctr_home}/quadlets" cockpit-module-containers-list)"
if printf '%s' "${containers_out}" | jq -e '(.items | length) == 3 and ([.items[].groups[].rows[] | select(.id == "cpu" or .id == "memory")] == [])' >/dev/null \
    && cockpit-validate-contract "${containers_contract}" "${containers_out}"; then
    ok "containers-list-stats-fails"
else
    bad "containers-list-stats-fails" "${containers_out}"
fi

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
containers_out="$(HOME="${work}/containers-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/containers-none" cockpit-module-containers-list)"
if [[ "${containers_out}" == '{"items":[]}' && ! -e "${ctr_stats_args}" ]]; then
    ok "containers-list-empty"
else
    bad "containers-list-empty" "${containers_out}"
fi

cockpit-containers-list-podman() {
    case "${1-} ${2-}" in
        "ps -a") printf '[{"Id":"%s","Names":["x"],"State":"exited"}]\n' "${ctr_db}" ;;
        *) return 1 ;;
    esac
}
if containers_out="$(HOME="${work}/containers-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/containers-none" cockpit-module-containers-list 2>/dev/null)"; then
    bad "containers-list-inspect-fails" "${containers_out}"
else
    ok "containers-list-inspect-fails"
fi

cockpit-containers-list-podman() {
    return 1
}
if containers_out="$(HOME="${work}/containers-none" PODSHIFT_PODMAN_QUADLETS_DIR="${work}/containers-none" cockpit-module-containers-list 2>/dev/null)"; then
    bad "containers-list-podman-fails" "${containers_out}"
else
    ok "containers-list-podman-fails"
fi

# inspect: the handler passes args to the session; bad kind or ref never reaches it.
reset_mocks
MODE="emit"
EMIT='{"kind":"volume","ref":"pgdata","found":true,"object":{"Name":"pgdata","Driver":"local"}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"volume","ref":"pgdata"}}'
if expect_code "inspect-mock-session" "OK"; then
    if [[ "$(field '.data.object.Name')" == "pgdata" && "$(field '.data.found')" == "true" && "$(field '.request.args.ref')" == "pgdata" ]] \
        && grep -q -- '--expand-environment=no' "${argv}" && grep -q 'cockpit-run-in-session.sh inspect ' "${argv}" \
        && grep -q 'kind' "${argv}" && grep -q 'pgdata' "${argv}" && ! grep -q 'pgdata' "${log}"; then
        ok "inspect-mock-session"
    else
        bad "inspect-mock-session" "${LAST_OUT} argv $(cat "${argv}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"container","ref":"gone","found":false}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"container","ref":"gone"}}'
if expect_code "inspect-not-found" "OK"; then
    if [[ "$(field '.data.found')" == "false" && "$(field '.data.object')" == "null" ]]; then
        ok "inspect-not-found"
    else
        bad "inspect-not-found" "${LAST_OUT}"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"secret","ref":"3c8e1f0a9b7d6c5e4f3a2b1c0","found":true,"object":{"ID":"3c8e1f0a9b7d6c5e4f3a2b1c0","Spec":{"Name":"db-password"}}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"secret","ref":"3c8e1f0a9b7d6c5e4f3a2b1c0"}}'
if expect_code "inspect-secret-session" "OK"; then
    if [[ "$(field '.data.kind')" == "secret" && "$(field '.data.object.Spec.Name')" == "db-password" ]] && grep -q 'secret' "${argv}"; then
        ok "inspect-secret-session"
    else
        bad "inspect-secret-session" "${LAST_OUT}"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"volume","ref":"pgdata","object":{}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"volume","ref":"pgdata"}}'
expect_code "inspect-output-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "inspect-output-contract"

long_ref="$(printf 'a%.0s' {1..257})"
inspect_bad_n=0
for inspect_case in \
    '{"kind":"pod","ref":"x"}|kind' \
    '{"kind":"","ref":"x"}|kind' \
    '{"ref":"x"}|kind' \
    '{"kind":"volume"}|ref' \
    '{}|kind, ref' \
    '{"kind":"volume","ref":""}|ref' \
    '{"kind":"volume","ref":"-rm"}|ref' \
    '{"kind":"volume","ref":"--all"}|ref' \
    '{"kind":"volume","ref":"a b"}|ref' \
    '{"kind":"volume","ref":"a;b"}|ref' \
    '{"kind":"volume","ref":"a$(id)"}|ref' \
    '{"kind":"volume","ref":"a\nb"}|ref' \
    '{"kind":"volume","ref":1}|ref' \
    "{\"kind\":\"volume\",\"ref\":\"${long_ref}\"}|ref" \
    '{"kind":"volume","ref":"x","all":true}|all' \
    '{"kind":"volume","ref":"x","mode":"zip"}|mode' \
    '{"kind":"volume","ref":"x","mode":""}|mode' \
    '{"kind":"pod","ref":"-x","mode":1}|kind, mode, ref'; do
    inspect_args="${inspect_case%|*}"
    inspect_want="Given arguments are not supported: ${inspect_case##*|}."
    inspect_bad_n=$((inspect_bad_n + 1))
    reset_mocks
    MODE="emit"
    EMIT='{"kind":"volume","ref":"x","found":false}'
    run_serve "{\"apiVersion\":1,\"action\":\"inspect\",\"args\":${inspect_args}}"
    if expect_code "inspect-invalid-args-${inspect_bad_n}" "INVALID_ARGS"; then
        if [[ ! -s "${argv}" && "$(field '.request.args')" == "null" && "$(field '.status.message')" == "${inspect_want}" ]]; then
            ok "inspect-invalid-args-${inspect_bad_n}"
        else
            bad "inspect-invalid-args-${inspect_bad_n}" "${inspect_args}: $(field '.status.message')"
        fi
    fi
done

reset_mocks
MODE="emit"
EMIT='{"kind":"volume","ref":"x","found":false}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"volume","ref":"x","<b>":1}}'
if expect_code "inspect-invalid-args-unnamed" "INVALID_ARGS" && [[ "$(field '.status.message')" == "Given arguments are not supported." ]]; then
    ok "inspect-invalid-args-unnamed"
else
    bad "inspect-invalid-args-unnamed" "$(field '.status.message')"
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"container","ref":"db","found":true,"file":{"path":"/run/user/300/podshift/inspect-Ab12Cd34Ef.json","size":200000}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"container","ref":"db","mode":"file"}}'
if expect_code "inspect-file-mode-session" "OK" && [[ "$(field '.data.file.size')" == "200000" ]] && grep -q 'file' "${argv}"; then
    ok "inspect-file-mode-session"
else
    bad "inspect-file-mode-session" "${LAST_OUT}"
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"container","ref":"db","found":true,"file":{"path":"/etc/shadow","size":1}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"container","ref":"db","mode":"file"}}'
expect_code "inspect-file-path-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "inspect-file-path-contract"

reset_mocks
MODE="emit"
EMIT='{"kind":"image","ref":"big","found":true,"tooLarge":true,"size":300000}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"image","ref":"big"}}'
if expect_code "inspect-too-large-session" "OK" && [[ "$(field '.data.tooLarge')" == "true" && "$(field '.data.size')" == "300000" ]]; then
    ok "inspect-too-large-session"
else
    bad "inspect-too-large-session" "${LAST_OUT}"
fi

reset_mocks
MODE="emit"
EMIT='{"pong":true,"uid":300}'
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
if expect_code "ping-empty-args-through-tunnel" "OK"; then
    if grep -q -- '--expand-environment=no' "${argv}" && grep -q 'cockpit-run-in-session.sh ping \\{\\}' "${argv}"; then
        ok "ping-empty-args-through-tunnel"
    else
        bad "ping-empty-args-through-tunnel" "argv $(cat "${argv}")"
    fi
fi

# inspect module: podman is stubbed with the unit fixtures, one per kind.
ins_fix="${repo}/src/test/unit/fixtures/cockpit-inspect"
ins_calls="${work}/inspect.calls"
: > "${ins_calls}"
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${2-} ${3-} ${4-}" in
        "inspect -- db"|"inspect -- alpine"|"inspect -- pgdata"|"inspect -- podman"|"inspect -- db-password")
            cat "${ins_fix}/${1}.json"
            ;;
        "inspect -- "*)
            printf '[]\n'
            return 125
            ;;
        "exists -- broken")
            return 125
            ;;
        "exists -- "*)
            return 1
            ;;
        *)
            return 2
            ;;
    esac
}
inspect_contract="$(jq -c '.output' "${API}/modules/inspect/capability.json")"
for ins_pair in container:db image:alpine volume:pgdata network:podman secret:db-password; do
    ins_kind="${ins_pair%%:*}"
    ins_ref="${ins_pair#*:}"
    ins_out="$(cockpit-module-inspect "{\"kind\":\"${ins_kind}\",\"ref\":\"${ins_ref}\"}")"
    if printf '%s' "${ins_out}" | jq -e --arg kind "${ins_kind}" --arg ref "${ins_ref}" --argjson want "$(jq -c '.[0]' "${ins_fix}/${ins_kind}.json")" \
        '.kind == $kind and .ref == $ref and .found == true and .object == $want' >/dev/null \
        && cockpit-validate-contract "${inspect_contract}" "${ins_out}" \
        && grep -qx "${ins_kind} inspect -- ${ins_ref}" "${ins_calls}"; then
        ok "inspect-module-${ins_kind}"
    else
        bad "inspect-module-${ins_kind}" "${ins_out}"
    fi
done

ins_out="$(cockpit-module-inspect '{"kind":"volume","ref":"missing"}')"
if [[ "${ins_out}" == '{"kind":"volume","ref":"missing","found":false}' ]] && cockpit-validate-contract "${inspect_contract}" "${ins_out}"; then
    ok "inspect-module-not-found"
else
    bad "inspect-module-not-found" "${ins_out}"
fi

if ins_out="$(cockpit-module-inspect '{"kind":"network","ref":"broken"}' 2>/dev/null)"; then
    bad "inspect-module-podman-fails" "${ins_out}"
else
    ok "inspect-module-podman-fails"
fi

: > "${ins_calls}"
if ins_out="$(cockpit-module-inspect '{"kind":"pod","ref":"db"}' 2>/dev/null)" || [[ -s "${ins_calls}" ]]; then
    bad "inspect-module-bad-kind" "${ins_out}"
else
    ok "inspect-module-bad-kind"
fi
if ins_out="$(cockpit-module-inspect '{"kind":"volume","ref":"-a"}' 2>/dev/null)" || [[ -s "${ins_calls}" ]]; then
    bad "inspect-module-bad-ref" "${ins_out}"
else
    ok "inspect-module-bad-ref"
fi

# inspect module, kind secret: podman is stubbed to print SecretData anyway. It is removed in
# normal and file mode, and --showsecret is never passed.
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${*}" in
        "secret inspect -- db-password")
            printf '%s\n' '[{"ID":"3c8e1f0a9b7d6c5e4f3a2b1c0","Spec":{"Name":"db-password","Driver":{"Name":"file"}},"SecretData":"must-never-leak"}]'
            ;;
        "secret inspect -- "*)
            return 125
            ;;
        "secret exists -- "*)
            return 1
            ;;
        *)
            return 2
            ;;
    esac
}
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect '{"kind":"secret","ref":"db-password"}')"
if printf '%s' "${ins_out}" | jq -e '.kind == "secret" and .found == true and .object.Spec.Name == "db-password" and (.object | has("SecretData") | not)' >/dev/null \
    && [[ "${ins_out}" != *must-never-leak* ]] && cockpit-validate-contract "${inspect_contract}" "${ins_out}" \
    && ! grep -q -- '--showsecret' "${ins_calls}"; then
    ok "inspect-module-secret-no-value"
else
    bad "inspect-module-secret-no-value" "${ins_out}"
fi
sec_rt="${work}/secret-runtime"
mkdir -p "${sec_rt}"
ins_out="$(XDG_RUNTIME_DIR="${sec_rt}" cockpit-module-inspect '{"kind":"secret","ref":"db-password","mode":"file"}')"
ins_path="$(printf '%s' "${ins_out}" | jq -r '.file.path // empty')"
if [[ -f "${ins_path}" ]] && jq -e '.ID == "3c8e1f0a9b7d6c5e4f3a2b1c0" and (has("SecretData") | not)' "${ins_path}" >/dev/null \
    && ! grep -q 'must-never-leak' "${ins_path}" && ! grep -q -- '--showsecret' "${ins_calls}"; then
    ok "inspect-module-secret-file-no-value"
else
    bad "inspect-module-secret-file-no-value" "${ins_out}"
fi
ins_out="$(cockpit-module-inspect '{"kind":"secret","ref":"gone"}')"
if [[ "${ins_out}" == '{"kind":"secret","ref":"gone","found":false}' ]] && cockpit-validate-contract "${inspect_contract}" "${ins_out}"; then
    ok "inspect-module-secret-not-found"
else
    bad "inspect-module-secret-not-found" "${ins_out}"
fi

# inspect module: an image short ID that podman image inspect does not find is resolved through
# podman image ls; a full ID is found directly; no match is still not found.
ins_full="abbc135a7d39c0e8a2fdabbc135a7d39c0e8a2fdabbc135a7d39c0e8a2fd1234"
ins_tagonly="5ee1d0c0ffee5ee1d0c0ffee5ee1d0c0ffee5ee1d0c0ffee5ee1d0c0ffee5ee1"
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${*}" in
        "image inspect -- ${ins_full}"|"image inspect -- docker.io/library/tagonly:1") cat "${ins_fix}/image.json" ;;
        "image ls --format json")
            printf '[{"Id":"%s","Names":["docker.io/library/alpine:latest"]},{"Id":"sha256:%s","Names":["docker.io/library/tagonly:1"]}]\n' \
                "${ins_full}" "${ins_tagonly}"
            ;;
        "image inspect -- "*) printf '[]\n'; return 125 ;;
        "image exists -- "*) return 1 ;;
        *) return 2 ;;
    esac
}
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"abbc135a7d39"}')"
if printf '%s' "${ins_out}" | jq -e --argjson want "$(jq -c '.[0]' "${ins_fix}/image.json")" \
        '. == {kind: "image", ref: "abbc135a7d39", found: true, object: $want}' >/dev/null \
    && cockpit-validate-contract "${inspect_contract}" "${ins_out}" \
    && [[ "$(cat "${ins_calls}")" == "image inspect -- abbc135a7d39"$'\n'"image ls --format json"$'\n'"image inspect -- ${ins_full}" ]]; then
    ok "inspect-module-image-short-id"
else
    bad "inspect-module-image-short-id" "${ins_out} calls $(tr '\n' ';' < "${ins_calls}")"
fi
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect "{\"kind\":\"image\",\"ref\":\"${ins_full}\"}")"
if printf '%s' "${ins_out}" | jq -e --arg ref "${ins_full}" '.ref == $ref and .found == true and (.object | type) == "object"' >/dev/null \
    && [[ "$(cat "${ins_calls}")" == "image inspect -- ${ins_full}" ]]; then
    ok "inspect-module-image-full-id"
else
    bad "inspect-module-image-full-id" "${ins_out} calls $(tr '\n' ';' < "${ins_calls}")"
fi
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"sha256:5ee1d0c0ffee"}')"
if printf '%s' "${ins_out}" | jq -e '.ref == "sha256:5ee1d0c0ffee" and .found == true' >/dev/null \
    && grep -qx "image inspect -- ${ins_tagonly}" "${ins_calls}" \
    && grep -qx "image inspect -- docker.io/library/tagonly:1" "${ins_calls}"; then
    ok "inspect-module-image-tag-fallback"
else
    bad "inspect-module-image-tag-fallback" "${ins_out} calls $(tr '\n' ';' < "${ins_calls}")"
fi
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"0123456789ab"}')"
if [[ "${ins_out}" == '{"kind":"image","ref":"0123456789ab","found":false}' ]] \
    && grep -qx "image ls --format json" "${ins_calls}" && grep -qx "image exists -- 0123456789ab" "${ins_calls}"; then
    ok "inspect-module-image-no-match"
else
    bad "inspect-module-image-no-match" "${ins_out} calls $(tr '\n' ';' < "${ins_calls}")"
fi
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"alpine-gone"}')"
if [[ "${ins_out}" == '{"kind":"image","ref":"alpine-gone","found":false}' ]]; then
    ok "inspect-module-image-name-not-found"
else
    bad "inspect-module-image-name-not-found" "${ins_out}"
fi
ins_rt2="${work}/runtime-image"
mkdir -p "${ins_rt2}"
ins_out="$(XDG_RUNTIME_DIR="${ins_rt2}" cockpit-module-inspect '{"kind":"image","ref":"abbc135a7d39","mode":"file"}')"
ins_path="$(printf '%s' "${ins_out}" | jq -r '.file.path // empty')"
if [[ -f "${ins_path}" ]] && [[ "$(jq -c . "${ins_path}")" == "$(jq -c '.[0]' "${ins_fix}/image.json")" ]] \
    && printf '%s' "${ins_out}" | jq -e '.ref == "abbc135a7d39" and .found == true' >/dev/null; then
    ok "inspect-module-image-short-id-file"
else
    bad "inspect-module-image-short-id-file" "${ins_out}"
fi
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${*}" in
        "image ls --format json") return 125 ;;
        "image inspect -- "*) printf '[]\n'; return 125 ;;
        "image exists -- "*) return 1 ;;
        *) return 2 ;;
    esac
}
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"abbc135a7d39"}')"
if [[ "${ins_out}" == '{"kind":"image","ref":"abbc135a7d39","found":false}' ]]; then
    ok "inspect-module-image-list-fails"
else
    bad "inspect-module-image-list-fails" "${ins_out}"
fi

# inspect module: too-large results and file mode, with podman stubbed and a temporary runtime directory.
ins_big="$(jq -n -c '[{Id: "big", Blob: ("x" * 140000)}]')"
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${2-} ${3-} ${4-}" in
        "inspect -- db") cat "${ins_fix}/${1}.json" ;;
        "inspect -- big") printf '%s\n' "${ins_big}" ;;
        "inspect -- "*) printf '[]\n'; return 125 ;;
        "exists -- "*) return 1 ;;
        *) return 2 ;;
    esac
}
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"big"}')"
ins_want="$(printf '%s' "${ins_big}" | jq --indent 4 '.[0]' | LC_ALL=C wc -c | tr -d '[:space:]')"
if printf '%s' "${ins_out}" | jq -e --argjson want "${ins_want}" '. == {kind: "image", ref: "big", found: true, tooLarge: true, size: $want}' >/dev/null \
    && cockpit-validate-contract "${inspect_contract}" "${ins_out}"; then
    ok "inspect-module-too-large"
else
    bad "inspect-module-too-large" "${ins_out:0:300}"
fi

ins_rt="${work}/runtime"
mkdir -p "${ins_rt}/podshift"
chmod 700 "${ins_rt}/podshift"
: > "${ins_rt}/podshift/inspect-old.json"
: > "${ins_rt}/podshift/keep.txt"
: > "${ins_rt}/podshift/inspect-new.json"
touch -t 202001010000 "${ins_rt}/podshift/inspect-old.json" "${ins_rt}/podshift/keep.txt"
ins_out="$(XDG_RUNTIME_DIR="${ins_rt}" cockpit-module-inspect '{"kind":"image","ref":"big","mode":"file"}')"
ins_path="$(printf '%s' "${ins_out}" | jq -r '.file.path // empty')"
ins_perm=""
[[ -f "${ins_path}" ]] && ins_perm="$(stat -c '%a' "${ins_path}" 2>/dev/null || stat -f '%Lp' "${ins_path}" 2>/dev/null)"
if [[ "${ins_path}" == "${ins_rt}/podshift/inspect-"*.json && "${ins_perm}" == "600" ]] \
    && printf '%s' "${ins_out}" | jq -e --argjson want "${ins_want}" '.kind == "image" and .found == true and .file.size == $want and (has("object") | not)' >/dev/null \
    && [[ "$(LC_ALL=C wc -c < "${ins_path}" | tr -d '[:space:]')" == "${ins_want}" ]] \
    && [[ "$(jq -c . "${ins_path}")" == "$(printf '%s' "${ins_big}" | jq -c '.[0]')" ]] \
    && cockpit-validate-contract "${inspect_contract}" "${ins_out}"; then
    ok "inspect-module-file-mode"
else
    bad "inspect-module-file-mode" "${ins_out} perm ${ins_perm}"
fi
if [[ ! -e "${ins_rt}/podshift/inspect-old.json" && -e "${ins_rt}/podshift/inspect-new.json" && -e "${ins_rt}/podshift/keep.txt" ]]; then
    ok "inspect-module-file-cleanup"
else
    bad "inspect-module-file-cleanup" "$(ls "${ins_rt}/podshift")"
fi

ins_out="$(XDG_RUNTIME_DIR="${ins_rt}" cockpit-module-inspect '{"kind":"container","ref":"db","mode":"file"}')"
ins_path="$(printf '%s' "${ins_out}" | jq -r '.file.path // empty')"
if [[ -f "${ins_path}" ]] && [[ "$(jq -c . "${ins_path}")" == "$(jq -c '.[0]' "${ins_fix}/container.json")" ]]; then
    ok "inspect-module-file-mode-small"
else
    bad "inspect-module-file-mode-small" "${ins_out}"
fi

ins_out="$(XDG_RUNTIME_DIR="${ins_rt}" cockpit-module-inspect '{"kind":"container","ref":"gone","mode":"file"}')"
if [[ "${ins_out}" == '{"kind":"container","ref":"gone","found":false}' ]]; then
    ok "inspect-module-file-mode-not-found"
else
    bad "inspect-module-file-mode-not-found" "${ins_out}"
fi

if ins_out="$(XDG_RUNTIME_DIR="${work}/no-such-runtime" cockpit-module-inspect '{"kind":"container","ref":"db","mode":"file"}' 2>/dev/null)"; then
    bad "inspect-module-file-no-runtime" "${ins_out}"
else
    ok "inspect-module-file-no-runtime"
fi

: > "${ins_calls}"
if ins_out="$(XDG_RUNTIME_DIR="${ins_rt}" cockpit-module-inspect '{"kind":"container","ref":"db","mode":"zip"}' 2>/dev/null)" || [[ -s "${ins_calls}" ]]; then
    bad "inspect-module-bad-mode" "${ins_out}"
else
    ok "inspect-module-bad-mode"
fi

# --- services-list, service-view, service-logs ---
# The handler passes args to the session; a bad unit name never reaches it.
reset_mocks
MODE="emit"
EMIT='{"items":[{"id":"web.service","title":"web.service","subtitle":"Web","source":"quadlet","activeState":"active","subState":"running","since":"2026-11-12T09:02:14Z","unitFileState":"generated","path":"/run/user/300/systemd/generator/web.service","quadletFile":"/home/podshift/.config/containers/systemd/web.container","quadletKind":"container","mainPid":12,"memory":1024}]}'
run_serve '{"apiVersion":1,"action":"services-list","args":{}}'
if expect_code "services-list-mock-session" "OK"; then
    if [[ "$(field '.data.items[0].quadletKind')" == "container" ]] && grep -q 'cockpit-run-in-session.sh services-list ' "${argv}"; then
        ok "services-list-mock-session"
    else
        bad "services-list-mock-session" "${LAST_OUT} argv $(cat "${argv}")"
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
    if [[ "$(field '.data.items[0].title')" == "web" ]] && grep -q 'cockpit-run-in-session.sh quadlets-list ' "${argv}"; then
        ok "quadlets-list-mock-session"
    else
        bad "quadlets-list-mock-session" "${LAST_OUT} argv $(cat "${argv}")"
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
    if [[ "$(field '.data.found')" == "true" && "$(field '.request.args.unit')" == "web.service" ]] && grep -q 'cockpit-run-in-session.sh service-view ' "${argv}" && grep -q 'web.service' "${argv}"; then
        ok "service-view-mock-session"
    else
        bad "service-view-mock-session" "${LAST_OUT} argv $(cat "${argv}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"unit":"web.service","found":true,"quadlet":true,"name":"web.container","path":"/home/podshift/.config/containers/systemd/web.container","kind":"container","text":"[Container]\nImage=nginx\n"}'
run_serve '{"apiVersion":1,"action":"quadlet-view","args":{"unit":"web.service"}}'
if expect_code "quadlet-view-mock-session" "OK"; then
    if [[ "$(field '.data.name')" == "web.container" && "$(field '.request.args.unit')" == "web.service" ]] && grep -q 'cockpit-run-in-session.sh quadlet-view ' "${argv}" && grep -q 'web.service' "${argv}"; then
        ok "quadlet-view-mock-session"
    else
        bad "quadlet-view-mock-session" "${LAST_OUT} argv $(cat "${argv}")"
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
svc_bin="${work}/service-logs-bin"
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
export SVC_ROOT_LOG="${work}/service-logs-root"
rm -f "${SVC_ROOT_LOG}.systemctl" "${SVC_ROOT_LOG}.journalctl"
PATH="${svc_bin}:${PATH}" run_serve '{"apiVersion":1,"action":"service-logs","args":{"unit":"web.service"}}'
if expect_code "service-logs-root-handler" "OK"; then
    if printf '%s' "$(field '.data')" | jq -e '.found == true and .readable == true and .entries == [{"time":"2026-11-12T09:02:14Z","hostname":"podshift","identifier":"web","priority":4,"message":"root read"}]' >/dev/null \
        && [[ "$(cat "${SVC_ROOT_LOG}.journalctl" 2>/dev/null)" == "-n 100 -o json --no-pager _SYSTEMD_USER_UNIT=web.service _UID=300 + USER_UNIT=web.service _UID=300 + OBJECT_SYSTEMD_USER_UNIT=web.service _UID=300" ]] \
        && grep -q -- '^--machine=300@.host --user list-units ' "${SVC_ROOT_LOG}.systemctl" \
        && ! grep -q 'cockpit-run-in-session' "${argv}" 2>/dev/null; then
        ok "service-logs-root-handler"
    else
        bad "service-logs-root-handler" "${LAST_OUT} journalctl $(cat "${SVC_ROOT_LOG}.journalctl" 2>/dev/null) systemctl $(cat "${SVC_ROOT_LOG}.systemctl" 2>/dev/null) argv $(cat "${argv}" 2>/dev/null)"
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
        if [[ ! -s "${argv}" && "$(field '.status.message')" == "${svc_want}" ]]; then
            ok "services-bad-name-${svc_bad_n}"
        else
            bad "services-bad-name-${svc_bad_n}" "${svc_args}: $(field '.status.message')"
        fi
    fi
done

# Module level: systemctl and journalctl are stubbed. Calls are recorded, one per line.
svc_calls="${work}/services.calls"
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
if [[ "${services_out}" == '{"items":[]}' ]] && ! grep -q '^show' "${svc_calls}"; then
    ok "services-list-empty"
else
    bad "services-list-empty" "${services_out}"
fi

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
if printf '%s' "${view_out}" | jq -e '.found == true and .mode == "status" and (.text | startswith("○ old.service"))' >/dev/null \
    && grep -q -- '^status --no-pager --full --lines=10 -- old.service$' "${svc_calls}"; then
    ok "service-view-inactive-status-exit-3"
else
    bad "service-view-inactive-status-exit-3" "${view_out}"
fi

view_out="$(SVC_RC=4 cockpit-module-service-view '{"unit":"web.service","mode":"status"}')"
if [[ "${view_out}" == '{"unit":"web.service","mode":"status","found":false}' ]]; then
    ok "service-view-status-exit-4"
else
    bad "service-view-status-exit-4" "${view_out}"
fi

: > "${svc_calls}"
view_out="$(cockpit-module-service-view '{"unit":"missing.service","mode":"unit"}')"
if [[ "${view_out}" == '{"unit":"missing.service","mode":"unit","found":false}' ]] && ! grep -q '^cat' "${svc_calls}"; then
    ok "service-view-unknown-unit"
else
    bad "service-view-unknown-unit" "${view_out}"
fi

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
if [[ "${logs_out}" == '{"unit":"old.service","found":true,"readable":true,"entries":[]}' ]]; then
    ok "service-logs-empty"
else
    bad "service-logs-empty" "${logs_out}"
fi

: > "${svc_calls}"
logs_out="$(cockpit-module-service-logs '{"unit":"missing.service"}')"
if [[ "${logs_out}" == '{"unit":"missing.service","found":false}' ]] && [[ ! -s "${svc_calls}" ]]; then
    ok "service-logs-unknown-unit"
else
    bad "service-logs-unknown-unit" "${logs_out}"
fi

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
if [[ "${logs_out}" == '{"unit":"old.service","found":true,"readable":true,"entries":[]}' ]] \
    && cockpit-validate-contract "${logs_contract}" "${logs_out}"; then
    ok "service-logs-no-output"
else
    bad "service-logs-no-output" "${logs_out}"
fi

logs_out="$(SVC_JOURNAL_RC=1 SVC_JOURNAL=$'-- No entries --\n' cockpit-module-service-logs '{"unit":"old.service"}')"
if [[ "${logs_out}" == '{"unit":"old.service","found":true,"readable":true,"entries":[]}' ]]; then
    ok "service-logs-no-entries-exit-1"
else
    bad "service-logs-no-entries-exit-1" "${logs_out}"
fi

logs_out="$(SVC_JOURNAL_RC=1 SVC_JOURNAL_ERR=$'No journal files were found.\n' cockpit-module-service-logs '{"unit":"web.service"}')"
if [[ "${logs_out}" == '{"unit":"web.service","found":true,"readable":true,"entries":[]}' ]]; then
    ok "service-logs-no-files"
else
    bad "service-logs-no-files" "${logs_out}"
fi

logs_out="$(SVC_JOURNAL_RC=1 SVC_JOURNAL_ERR=$'Hint: You are currently not seeing messages from other users and the system.\n' cockpit-module-service-logs '{"unit":"web.service"}')"
if [[ "${logs_out}" == '{"unit":"web.service","found":true,"readable":true,"entries":[]}' ]]; then
    ok "service-logs-exit-1-hint"
else
    bad "service-logs-exit-1-hint" "${logs_out}"
fi

logs_out="$(SVC_JOURNAL_ERR=$'No journal files were opened due to insufficient permissions.\n' cockpit-module-service-logs '{"unit":"web.service"}')"
if [[ "${logs_out}" == '{"unit":"web.service","found":true,"readable":false,"error":"JOURNAL_UNREADABLE","reason":"No journal files were opened due to insufficient permissions.","entries":[]}' ]] \
    && cockpit-validate-contract "${logs_contract}" "${logs_out}"; then
    ok "service-logs-no-permission"
else
    bad "service-logs-no-permission" "${logs_out}"
fi

logs_out="$(SVC_JOURNAL_RC=1 SVC_JOURNAL_ERR=$'Failed to open\t/var/log/journal/x/user-300.journal: Permission denied\nHint: more\n' cockpit-module-service-logs '{"unit":"web.service"}')"
if [[ "${logs_out}" == '{"unit":"web.service","found":true,"readable":false,"error":"JOURNAL_UNREADABLE","reason":"Failed to open /var/log/journal/x/user-300.journal: Permission denied","entries":[]}' ]] \
    && cockpit-validate-contract "${logs_contract}" "${logs_out}"; then
    ok "service-logs-permission-denied"
else
    bad "service-logs-permission-denied" "${logs_out}"
fi

logs_out="$(SVC_JOURNAL=$'{"__REALTIME_TIMESTAMP":"1794474134000000","MESSAGE":"kept"}\n' SVC_JOURNAL_ERR=$'Failed to open /x: Permission denied\n' cockpit-module-service-logs '{"unit":"web.service"}')"
if printf '%s' "${logs_out}" | jq -e '.readable == true and (.entries | length) == 1 and .entries[0].message == "kept"' >/dev/null; then
    ok "service-logs-partial-permission"
else
    bad "service-logs-partial-permission" "${logs_out}"
fi

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

# quadlet-view: QV_SOURCE is the SourcePath that systemctl show prints; QV_DIR the Quadlet folder.
qv_dir="${work}/quadlet-view/systemd"
qv_outside="${work}/quadlet-view/outside"
mkdir -p "${qv_dir}/app" "${qv_outside}"
printf '[Container]\nImage=nginx\nSecret=db-pass\n' > "${qv_dir}/web.container"
printf '[Network]\n' > "${qv_dir}/app/net.network"
printf '[Container]\n' > "${qv_outside}/evil.container"
# Temporary links in the mktemp folder, like the capability link cases above.
ln -s "${qv_outside}/evil.container" "${qv_dir}/link.container"
ln -s "${qv_outside}" "${qv_dir}/escape"
quadlet_contract="$(jq -c '.output' "${API}/modules/quadlet-view/capability.json")"
cockpit-quadlet-view-systemctl() {
    printf '%s\n' "$*" >> "${svc_calls}"
    case "${1-}" in
        list-units) printf '%s' "${svc_units}" ;;
        show) printf '%s\n' "${QV_SOURCE-}"; return "${QV_RC:-0}" ;;
        *) return 1 ;;
    esac
}
cockpit-quadlet-view-dir() {
    printf '%s\n' "${QV_DIR-}"
}

: > "${svc_calls}"
qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/web.container" cockpit-module-quadlet-view '{"unit":"web.service"}')"
if printf '%s' "${qv_out}" | jq -e --arg path "${qv_dir}/web.container" '. == {"unit":"web.service","found":true,"quadlet":true,"name":"web.container","path":$path,"kind":"container","text":"[Container]\nImage=nginx\nSecret=db-pass\n"}' >/dev/null \
    && cockpit-validate-contract "${quadlet_contract}" "${qv_out}" \
    && grep -q -- '^show --property=SourcePath --value -- web.service$' "${svc_calls}"; then
    ok "quadlet-view-module"
else
    bad "quadlet-view-module" "${qv_out} calls $(tr '\n' ';' < "${svc_calls}")"
fi

qv_out="$(QV_DIR="${qv_dir}/" QV_SOURCE="${qv_dir}/app/net.network" cockpit-module-quadlet-view '{"unit":"web.service"}')"
if printf '%s' "${qv_out}" | jq -e '.kind == "network" and .name == "net.network" and .text == "[Network]\n"' >/dev/null; then
    ok "quadlet-view-bundle-folder"
else
    bad "quadlet-view-bundle-folder" "${qv_out}"
fi

: > "${svc_calls}"
qv_out="$(QV_DIR="${qv_dir}" cockpit-module-quadlet-view '{"unit":"missing.service"}')"
if [[ "${qv_out}" == '{"unit":"missing.service","found":false}' ]] && ! grep -q '^show' "${svc_calls}"; then
    ok "quadlet-view-unknown-unit"
else
    bad "quadlet-view-unknown-unit" "${qv_out}"
fi

qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="" cockpit-module-quadlet-view '{"unit":"old.service"}')"
if [[ "${qv_out}" == '{"unit":"old.service","found":true,"quadlet":false,"error":"NOT_QUADLET"}' ]] \
    && cockpit-validate-contract "${quadlet_contract}" "${qv_out}"; then
    ok "quadlet-view-not-quadlet"
else
    bad "quadlet-view-not-quadlet" "${qv_out}"
fi

qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/gone.container" cockpit-module-quadlet-view '{"unit":"web.service"}')"
if printf '%s' "${qv_out}" | jq -e '.error == "FILE_NOT_FOUND" and .name == "gone.container" and (has("text") | not)' >/dev/null \
    && cockpit-validate-contract "${quadlet_contract}" "${qv_out}"; then
    ok "quadlet-view-file-not-found"
else
    bad "quadlet-view-file-not-found" "${qv_out}"
fi

qv_n=0
for qv_source in "${qv_outside}/evil.container" "${qv_dir}/../outside/evil.container" "${qv_dir}/link.container" "${qv_dir}/escape/evil.container"; do
    qv_n=$((qv_n + 1))
    qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_source}" cockpit-module-quadlet-view '{"unit":"web.service"}')"
    if printf '%s' "${qv_out}" | jq -e '.error == "OUTSIDE_QUADLET_DIR" and .quadlet == true and (has("text") | not)' >/dev/null \
        && cockpit-validate-contract "${quadlet_contract}" "${qv_out}"; then
        ok "quadlet-view-outside-${qv_n}"
    else
        bad "quadlet-view-outside-${qv_n}" "${qv_source}: ${qv_out}"
    fi
done

qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/web.container" QV_RC=1 cockpit-module-quadlet-view '{"unit":"web.service"}' 2>/dev/null)" && qv_rc=0 || qv_rc=$?
if [[ "${qv_rc}" -ne 0 && -z "${qv_out}" ]]; then
    ok "quadlet-view-show-fails"
else
    bad "quadlet-view-show-fails" "${qv_out}"
fi

: > "${svc_calls}"
if qv_out="$(cockpit-module-quadlet-view '{"unit":"../web.service"}' 2>/dev/null)" || [[ -s "${svc_calls}" ]]; then
    bad "quadlet-view-bad-name" "${qv_out}"
else
    ok "quadlet-view-bad-name"
fi

head -c 140000 /dev/zero | tr '\0' 'x' > "${qv_dir}/big.container"
qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/big.container" cockpit-module-quadlet-view '{"unit":"web.service"}')"
if printf '%s' "${qv_out}" | jq -e '.tooLarge == true and .size == 140000 and (has("text") | not)' >/dev/null \
    && cockpit-validate-contract "${quadlet_contract}" "${qv_out}"; then
    ok "quadlet-view-limit"
else
    bad "quadlet-view-limit" "$(printf '%s' "${qv_out}" | head -c 200)"
fi

if [[ "$(id -u)" -ne 0 ]]; then
    printf '[Container]\n' > "${qv_dir}/locked.container"
    chmod 000 "${qv_dir}/locked.container"
    qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/locked.container" cockpit-module-quadlet-view '{"unit":"web.service"}')"
    chmod 600 "${qv_dir}/locked.container"
    if printf '%s' "${qv_out}" | jq -e '.error == "FILE_UNREADABLE" and (has("text") | not)' >/dev/null; then
        ok "quadlet-view-unreadable"
    else
        bad "quadlet-view-unreadable" "${qv_out}"
    fi
fi
rm -rf "${work}/quadlet-view"


echo "NOTE: ${pass} passed, ${fail} failed. Session success was mocked. Live systemd-run was only checked for a failed tunnel."
if [[ "${fail}" -ne 0 ]]; then
    exit 2
fi
exit 0
