#!/usr/bin/env bash
# @file: run_serve_api.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Runs the handler of another API folder on a payload, as run_serve does.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the handler of another API folder on a payload, as run_serve does.
run_serve_api() {
    local api_dir payload errfile
    api_dir="${1}"
    payload="${2-}"
    errfile="$(mktemp)"
    LAST_OUT="$(
        printf '%s' "${payload}" | PATH="${WORK}:${PATH}" \
            COCKPIT_TEST_ARGV="${ARGV}" \
            COCKPIT_TEST_STDIN="${STDIN}" \
            COCKPIT_TEST_LOG="${LOG}" \
            COCKPIT_TEST_CHILD="${CHILD}" \
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
