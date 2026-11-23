#!/usr/bin/env bash
# @file: 031-handler-pipes-logging.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: Pipes like real systemd-run, time and process bounds, logging and arguments on stdin.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# The mock must refuse a named FIFO or a regular file, as real systemd-run does, or the pipe fix is not tested.
reset_mocks
fifo_dir="${WORK}/fifo-check"
mkdir -p "${fifo_dir}"
mkfifo "${fifo_dir}/fifo"
cat "${fifo_dir}/fifo" >/dev/null &
fc_reader=$!
COCKPIT_TEST_ARGV="${ARGV}" COCKPIT_TEST_SYSTEMD_MODE="emit" COCKPIT_TEST_EMIT='{}' \
    "${WORK}/systemd-run" bash cockpit-run-in-session.sh ping </dev/null >"${fifo_dir}/fifo" 2>/dev/null
fc_named=$?
wait "${fc_reader}" 2>/dev/null
COCKPIT_TEST_ARGV="${ARGV}" COCKPIT_TEST_SYSTEMD_MODE="emit" COCKPIT_TEST_EMIT='{}' \
    "${WORK}/systemd-run" bash cockpit-run-in-session.sh ping </dev/null 2>/dev/null | cat >/dev/null
fc_anon="${PIPESTATUS[0]}"
COCKPIT_TEST_ARGV="${ARGV}" COCKPIT_TEST_SYSTEMD_MODE="emit" COCKPIT_TEST_EMIT='{}' \
    "${WORK}/systemd-run" bash cockpit-run-in-session.sh ping </dev/null 2>"${fifo_dir}/err" | cat >/dev/null
fc_errfile="${PIPESTATUS[0]}"
rm -rf "${fifo_dir}"
[[ "${fc_named}" -ne 0 && "${fc_errfile}" -ne 0 && "${fc_anon}" -eq 0 ]]
expect_status "mock-refuses-fifo-or-file" $? "named=${fc_named} errfile=${fc_errfile} anonymous=${fc_anon}"

reset_mocks
MODE="nonzero"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "module-nonzero" "INTERNAL" && [[ "$(field '.status.code')" != "REALM_UNAVAILABLE" ]] && ok "module-nonzero"
if grep -q 'action=ping code=INTERNAL duration_ms=[0-9]* reason=module detail=Error: module boom x$' "${LOG}" && ! grep -q 'second line' "${LOG}"; then
    ok "log-reason-module-detail"
else
    bad "log-reason-module-detail" "$(cat "${LOG}")"
fi

reset_mocks
MODE="stray"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "module-stray" "INTERNAL" && ! printf '%s%s' "${LAST_OUT}" "${LAST_ERR}" | grep -q 'LEAKED-MODULE-OUTPUT' && grep -q ' reason=output$' "${LOG}" && ok "module-stray"

reset_mocks
MODE="twovalue"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "module-two-values" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "module-two-values"

reset_mocks
MODE="baduid"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
expect_code "output-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ! printf '%s%s' "${LAST_OUT}" "${LAST_ERR}" | grep -q '999' && grep -q ' reason=contract$' "${LOG}" && ok "output-contract"

reset_mocks
MODE="run"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
if expect_code "session-script-through-tunnel" "INTERNAL"; then
    if grep -q -- '--machine=podshift@.host' "${ARGV}" && grep -q -- '--user' "${ARGV}" && grep -q -- '--wait' "${ARGV}" && grep -q -- '--pipe' "${ARGV}" && grep -q -- '--quiet' "${ARGV}" && grep -q -- '--collect' "${ARGV}" && grep -q 'cockpit-run-in-session.sh' "${ARGV}"; then
        ok "session-script-through-tunnel"
    else
        bad "session-script-through-tunnel" "argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
MODE="oversize"
over_start="${SECONDS}"
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
over_elapsed=$((SECONDS - over_start))
over_child=""
[[ -f "${CHILD}" ]] && over_child="$(cat "${CHILD}")"
if expect_code "output-bound" "INTERNAL"; then
    if [[ "${over_elapsed}" -lt 5 && -n "${over_child}" ]] && ! still_alive "${over_child}" && grep -q ' reason=size$' "${LOG}"; then
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
[[ -f "${CHILD}" ]] && time_child="$(cat "${CHILD}")"
if expect_code "time-bound" "INTERNAL"; then
    if [[ "${time_elapsed}" -ge 8 && "${time_elapsed}" -le 20 && -n "${time_child}" ]] && ! still_alive "${time_child}" && grep -q ' reason=timeout$' "${LOG}"; then
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
PATH="${WORK}:${PATH}" COCKPIT_TEST_LOG="${LOG}" COCKPIT_TEST_LOGGER_FAIL="" cockpit-log-request "${secret}" "OK;rm" "12ms" >/dev/null
if grep -q 'action=unknown-action code=INTERNAL duration_ms=0' "${LOG}" && ! grep -q "${secret}" "${LOG}"; then
    ok "log-sanitises"
else
    bad "log-sanitises" "$(cat "${LOG}")"
fi
# the reason is one of a fixed list; a detail is only kept with a reason, cut to one line
reset_mocks
PATH="${WORK}:${PATH}" COCKPIT_TEST_LOG="${LOG}" cockpit-log-request ping INTERNAL 5 "bogus" "leak-one" >/dev/null
PATH="${WORK}:${PATH}" COCKPIT_TEST_LOG="${LOG}" cockpit-log-request ping INTERNAL 5 "" "leak-two" >/dev/null
PATH="${WORK}:${PATH}" COCKPIT_TEST_LOG="${LOG}" cockpit-log-request ping INTERNAL 5 "timeout" "" >/dev/null
if [[ "$(grep -c 'action=ping code=INTERNAL duration_ms=5$' "${LOG}")" -eq 2 ]] \
    && grep -q 'action=ping code=INTERNAL duration_ms=5 reason=timeout$' "${LOG}" \
    && ! grep -q 'leak-' "${LOG}"; then
    ok "log-reason-list"
else
    bad "log-reason-list" "$(cat "${LOG}")"
fi
reset_mocks
LOGGER_FAIL=1
MODE="emit"
EMIT='{"pong":true,"uid":300}'
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
if expect_code "log-failure-keeps-json" "OK"; then
    printf '%s' "${LAST_ERR}" | grep -q 'journal logging failed'
    expect_status "log-failure-keeps-json" $? "stderr ${LAST_ERR}"
fi

# The session unit has a fixed description, and the arguments go on stdin, never on a command line.
reset_mocks
MODE="emit"
EMIT='{"key":"TSV_APP","ok":true}'
run_serve '{"apiVersion":1,"action":"config-set","args":{"key":"TSV_APP","value":"ARGS-ONLY-ON-STDIN"}}'
if expect_code "session-args-on-stdin" "OK"; then
    if grep -qF -- '--description=PodShift\ Cockpit\ API\ request ' "${ARGV}" \
        && ! grep -q 'ARGS-ONLY-ON-STDIN' "${ARGV}" && grep -q 'ARGS-ONLY-ON-STDIN' "${STDIN}"; then
        ok "session-args-on-stdin"
    else
        bad "session-args-on-stdin" "argv $(cat "${ARGV}") stdin $(cat "${STDIN}")"
    fi
fi

# A root-realm module gets its arguments on stdin too; its own command line never holds them.
ARGFIX="${WORK}/argfix"
mkdir -p "${ARGFIX}"
cat > "${ARGFIX}/module.sh" << 'EOF2'
#!/usr/bin/env bash
cockpit-module-demo() {
    ps -o command= -p "$$" > "${ARGFIX_CMD}" 2>/dev/null
    printf '{"got":%s}\n' "${1}"
}
EOF2
argfix_out="$(ARGFIX_DIR="${ARGFIX}" ARGFIX_CMD="${ARGFIX}/cmd" bash -c '
    set +e
    source "$1"
    cockpit-dispatch-action() {
        [[ "${1:-}" == "fields" && "${2:-}" == "demo" ]] || return 1
        printf "demo\tcockpit-module-demo\t%s\troot\n" "${ARGFIX_DIR}"
    }
    cockpit-run-module demo "{\"token\":\"ARGS-ONLY-ON-STDIN\"}"
' _ "${API}/fn/cockpit-run-module.sh" 2>/dev/null)"
if [[ "${argfix_out}" == '{"got":{"token":"ARGS-ONLY-ON-STDIN"}}' && -s "${ARGFIX}/cmd" ]] \
    && ! grep -q 'ARGS-ONLY-ON-STDIN' "${ARGFIX}/cmd"; then
    ok "root-args-on-stdin"
else
    bad "root-args-on-stdin" "out ${argfix_out} cmd $(cat "${ARGFIX}/cmd" 2>/dev/null)"
fi
rm -rf "${ARGFIX}"

