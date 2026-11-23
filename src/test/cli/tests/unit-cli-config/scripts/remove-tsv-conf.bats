#!/usr/bin/env bats
# Stubbed tests for remove-tsv-conf (src/server/opt/podshift/fn/utils/remove-tsv-conf.sh) on a temp tsv.conf.
# require-podshift and load-podshift-conf-main are stubbed. Run with: ./test unit-cli-config

setup() {
    local here repo
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    repo="$(find-repo-root "${here}")" || return 1
    SCRIPT="${repo}/src/server/opt/podshift/fn/utils/remove-tsv-conf.sh"
    TSV_FILE="${BATS_TEST_TMPDIR}/tsv.conf"
    printf "# Custom TSV_* variables used by quadlets.\nTSV_KEEP='kept'\nTSV_APP='a'\nTSV_APP='b'\n" > "${TSV_FILE}"
}

# Runs remove-tsv-conf as the podshift user (CALLER=podshift) or as another user.
run_remove() {
    local caller
    caller="${1}"
    shift
    run env PATH="/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin" CALLER="${caller}" TEST_TSV="${TEST_TSV-${TSV_FILE}}" \
        bash -c '
            require-podshift() { [ "${CALLER}" = podshift ] || { echo "Unauthorised." >&2; return 1; }; }
            load-podshift-conf-main() { PODSHIFT_TSV_CONF="${TEST_TSV}"; }
            source "$1" || exit 9
            shift
            remove-tsv-conf "$@"
        ' bash "${SCRIPT}" "$@"
}

@test "every line of the key is removed, the rest is kept, and the file is 0644" {
    chmod 600 "${TSV_FILE}"
    run_remove podshift TSV_APP
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    ! grep -q '^TSV_APP=' "${TSV_FILE}"
    grep -qx "TSV_KEEP='kept'" "${TSV_FILE}"
    grep -q '^# Custom TSV_' "${TSV_FILE}"
    [ "$(ls -l "${TSV_FILE}" | cut -c1-10)" = "-rw-r--r--" ]
}

@test "a key that is not set returns 2 and changes nothing" {
    local before
    before="$(cat "${TSV_FILE}")"
    run_remove podshift TSV_NOPE
    [ "${status}" -eq 2 ]
    [ "${output}" = "TSV_NOPE is not set." ]
    [ "$(cat "${TSV_FILE}")" = "${before}" ]
}

@test "a missing tsv.conf returns 2" {
    TEST_TSV="${BATS_TEST_TMPDIR}/missing.conf" run_remove podshift TSV_APP
    [ "${status}" -eq 2 ]
    [ "${output}" = "TSV_APP is not set." ]
    [ ! -e "${BATS_TEST_TMPDIR}/missing.conf" ]
}

@test "a reserved name is refused and changes nothing" {
    printf "TSV_NW1='x'\n" >> "${TSV_FILE}"
    run_remove podshift TSV_NW1
    [ "${status}" -eq 1 ]
    [[ "${output}" == "Name 'TSV_NW1' is reserved."* ]]
    grep -qx "TSV_NW1='x'" "${TSV_FILE}"
}

@test "another user is refused and changes nothing" {
    run_remove other TSV_APP
    [ "${status}" -eq 1 ]
    [ "$(grep -c '^TSV_APP=' "${TSV_FILE}")" = "2" ]
}

@test "no key or an extra argument prints the usage" {
    run_remove podshift
    [ "${status}" -eq 1 ]
    [ "${output}" = "Invalid inputs. Usage: remove-tsv-conf <key>" ]
    run_remove podshift TSV_APP extra
    [ "${status}" -eq 1 ]
    [ "$(grep -c '^TSV_APP=' "${TSV_FILE}")" = "2" ]
}
