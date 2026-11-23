#!/usr/bin/env bash
# @file: 032-handler-fixtures.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: Retired, deprecated and broken fixtures, and a live systemd-run that must fail closed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# retired and deprecated fixtures, root realm, so the session tunnel is not used
fix="${WORK}/fixture"
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
touch "${WORK}/ran"
rm -f "${WORK}/ran"
reset_mocks
run_fixture deprecated '{"apiVersion":1,"action":"demo","args":{}}'
if expect_code "deprecated-runs" "OK"; then
    [[ "$(field '.data.ok')" == "true" && ! -s "${ARGV}" ]]
    expect_status "deprecated-runs" $? "${LAST_OUT}"
fi
reset_mocks
run_fixture retired '{"apiVersion":1,"action":"demo","args":{}}'
if expect_code "retired-stops" "ACTION_RETIRED"; then
    if [[ "$(field '.data')" == "null" && ! -f "${WORK}/ran" ]]; then
        ok "retired-stops"
    else
        bad "retired-stops" "data $(field '.data') ran=$([[ -f ${WORK}/ran ]] && echo yes || echo no)"
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
    [[ ! -f "${WORK}/ran" ]]
    expect_status "retired-does-not-run" $? "module ran"
fi

# broken metadata does not run the module
printf '%s\n' '{' > "${fix}/capability.json"
reset_mocks
run_fixture_raw '{"apiVersion":1,"action":"demo","args":{}}'
if expect_code "broken-metadata" "INTERNAL"; then
    [[ ! -f "${WORK}/ran" && "$(field '.data')" == "null" ]]
    expect_status "broken-metadata" $? "module ran or data leaked"
fi

# real systemd-run cannot enter podshift@.host here. This is a live command, and it must fail closed.
reset_mocks
real_start="${SECONDS}"
real_err="$(mktemp)"
LAST_OUT="$(
    printf '%s' '{"apiVersion":1,"action":"ping","args":{}}' | PATH="${PATH}" COCKPIT_TEST_LOG="${LOG}" \
        bash -c 'set +e; source "$1"; cockpit-serve 0; exit $?' _ "${API}/main.sh" 2>"${real_err}"
)"
LAST_RC=$?
LAST_ERR="$(cat "${real_err}" 2>/dev/null || true)"
rm -f "${real_err}"
real_elapsed=$((SECONDS - real_start))
if expect_code "live-tunnel-unavailable" "REALM_UNAVAILABLE"; then
    [[ "${real_elapsed}" -lt 8 ]]
    expect_status "live-tunnel-unavailable" $? "elapsed ${real_elapsed}"
fi

