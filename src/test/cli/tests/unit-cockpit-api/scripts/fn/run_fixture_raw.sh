#!/usr/bin/env bash
# @file: run_fixture_raw.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Runs the handler on the demo fixture as it is.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the handler on the demo fixture as it is.
run_fixture_raw() {
    local payload errfile
    payload="${1}"
    errfile="$(mktemp)"
    LAST_OUT="$(
        printf '%s' "${payload}" | PATH="${WORK}:${PATH}" COCKPIT_TEST_LOG="${LOG}" \
            FIXTURE="${fix}" RAN="${WORK}/ran" \
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
                        fields)
                            [[ "${action}" == "demo" ]] || return 1
                            printf "demo\tcockpit-module-demo\t%s\troot\n" "${FIXTURE}"
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
