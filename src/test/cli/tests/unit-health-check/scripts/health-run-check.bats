#!/usr/bin/env bats
# Unit test for health-run-check (src/server/opt/podshift/cli/modules/health-check/fn/health-run-check.sh).
# timeout, systemd-run and systemctl are fakes that log their calls. Run with: ./test unit-health-check

setup() {
    source "${TST_PODSHIFT_DIR}/cli/modules/health-check/fn/health-run-check.sh"
    STUB="${BATS_TEST_TMPDIR}/stub"
    mkdir -p "${STUB}/bin"
    : > "${STUB}/calls.log"
    export STUB
    cat > "${STUB}/bin/timeout" <<'SH'
#!/usr/bin/env bash
echo "timeout $*" >> "${STUB}/calls.log"
[ -e "${STUB}/hang" ] && [ "${1}" = "10" ] && exit 124
shift
exec "$@"
SH
    cat > "${STUB}/bin/systemd-run" <<'SH'
#!/usr/bin/env bash
echo "systemd-run $*" >> "${STUB}/calls.log"
echo "check output"
SH
    cat > "${STUB}/bin/systemctl" <<'SH'
#!/usr/bin/env bash
echo "systemctl $*" >> "${STUB}/calls.log"
SH
    chmod +x "${STUB}/bin/"*
    PATH="${STUB}/bin:${PATH}"
}

@test "a check in the podshift session runs in its own named unit" {
    run health-run-check podshift-session /x/check.sh
    [ "${status}" -eq 0 ]
    [ "${output}" = "check output" ]
    grep -q '^systemd-run --unit=podshift-health-[0-9]*-[0-9]* --machine=podshift@.host --user ' "${STUB}/calls.log"
    ! grep -q '^systemctl' "${STUB}/calls.log"
}

@test "a timed-out check in the podshift session has its unit stopped" {
    local unit
    : > "${STUB}/hang"
    run health-run-check podshift-session /x/check.sh
    [ "${status}" -eq 124 ]
    unit="$(sed -n 's/^timeout 10 systemd-run --unit=\([^ ]*\) .*/\1/p' "${STUB}/calls.log")"
    [ -n "${unit}" ]
    grep -qx "timeout 2 systemctl --machine=podshift@.host --user stop ${unit}.service" "${STUB}/calls.log"
}
