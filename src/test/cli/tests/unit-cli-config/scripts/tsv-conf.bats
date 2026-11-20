#!/usr/bin/env bats
# Tests for read-tsv-conf-lines, write-tsv-conf-lines and load-podshift-conf-runtime on temp files.
# No VM, no network, no root. load-podshift-conf-main is stubbed.
# Run with: ./test unit-cli-config

setup() {
    HERE="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    REPO="${HERE}"
    while [ "${REPO}" != "/" ] && [ ! -f "${REPO}/podshift.spec" ]; do
        REPO="$(dirname "${REPO}")"
    done
    UTILS="${REPO}/src/server/opt/podshift/fn/utils"
    LOADER="${REPO}/src/server/opt/podshift/fn/load-podshift-conf-runtime.sh"
    TSV_FILE="${BATS_TEST_TMPDIR}/tsv.conf"
    MARKER="${BATS_TEST_TMPDIR}/marker"
    {
        printf '%s\n' "# Custom TSV_* variables used by quadlets." ""
        printf '%s\n' "TSV_PLAIN=16" "TSV_QUOTED='example.com'" "TSV_APOS='it'\\''s'" "TSV_EQ='a=b=c'"
        printf '%s\n' "TSV_SUB='\$(touch ${MARKER}.1)'" "TSV_TICK=\`touch ${MARKER}.2\`"
        printf '%s\n' "touch ${MARKER}.3" "export PATH=/nowhere" "TSV_low=1" "TSV_SEMI=x; touch ${MARKER}.4"
        printf '%s' "TSV_LAST='no newline'"
    } > "${TSV_FILE}"
}

@test "read: TSV_ lines are set and exported as data, and nothing is run" {
    run env -i PATH="${PATH}" bash -c '
        source "$1" || exit 1
        read-tsv-conf-lines "$2" || exit 1
        bash -c "printf \"%s|\" \"\${TSV_PLAIN}\" \"\${TSV_QUOTED}\" \"\${TSV_APOS}\" \"\${TSV_EQ}\" \"\${TSV_SUB}\" \"\${TSV_TICK}\" \"\${TSV_SEMI}\" \"\${TSV_LAST}\" \"\${TSV_low-unset}\""
        printf "%s" "${PATH}" | grep -q nowhere && echo PATH-CHANGED
        exit 0
    ' bash "${UTILS}/read-tsv-conf-lines.sh" "${TSV_FILE}"
    echo "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "16|example.com|it's|a=b=c|\$(touch ${MARKER}.1)|\`touch ${MARKER}.2\`|x; touch ${MARKER}.4|no newline|unset|" ]
    [ -z "$(ls "${BATS_TEST_TMPDIR}" | grep marker || true)" ]
}

@test "read: a missing file returns 1 and sets nothing" {
    run bash -c 'source "$1"; read-tsv-conf-lines "$2"' bash "${UTILS}/read-tsv-conf-lines.sh" "${BATS_TEST_TMPDIR}/missing.conf"
    [ "${status}" -eq 1 ]
}

@test "load-podshift-conf-runtime reads tsv.conf as data and runtime.conf wins" {
    printf "TSV_PLAIN='from runtime'\n" > "${BATS_TEST_TMPDIR}/runtime.conf"
    run env -i PATH="${PATH}" TEST_TSV="${TSV_FILE}" TEST_RUNTIME="${BATS_TEST_TMPDIR}/runtime.conf" bash -c '
        set -euo pipefail
        load-podshift-conf-main() {
            PODSHIFT_TSV_CONF="${TEST_TSV}"
            PODSHIFT_RUNTIME_CONF="${TEST_RUNTIME}"
        }
        source "$1"
        load-podshift-conf-runtime
        printf "%s|%s|%s" "${TSV_PLAIN}" "${TSV_APOS}" "${TSV_SUB}"
    ' bash "${LOADER}"
    echo "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "from runtime|it's|\$(touch ${MARKER}.1)" ]
    [ -z "$(ls "${BATS_TEST_TMPDIR}" | grep marker || true)" ]
}

@test "write: valid lines are kept in canonical form and other lines are dropped with a note" {
    run bash -c 'source "$1"; write-tsv-conf-lines "$2" 2>"$3"' bash "${UTILS}/write-tsv-conf-lines.sh" "${TSV_FILE}" "${BATS_TEST_TMPDIR}/err"
    [ "${status}" -eq 0 ]
    expected="# Custom TSV_* variables used by quadlets.

TSV_PLAIN='16'
TSV_QUOTED='example.com'
TSV_APOS='it'\\''s'
TSV_EQ='a=b=c'
TSV_SUB='\$(touch ${MARKER}.1)'
TSV_TICK='\`touch ${MARKER}.2\`'
TSV_SEMI='x; touch ${MARKER}.4'
TSV_LAST='no newline'"
    [ "${output}" = "${expected}" ]
    [ "$(cat "${BATS_TEST_TMPDIR}/err")" = "Dropped 3 invalid line(s) from tsv.conf." ]
    [ -z "$(ls "${BATS_TEST_TMPDIR}" | grep marker || true)" ]
}

@test "write: the named key is left out and a clean file prints no note" {
    printf "# c\nTSV_A='1'\nTSV_B='2'\nTSV_A='3'\n" > "${TSV_FILE}"
    run bash -c 'source "$1"; write-tsv-conf-lines "$2" TSV_A' bash "${UTILS}/write-tsv-conf-lines.sh" "${TSV_FILE}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'# c\nTSV_B=\'2\'' ]
}

@test "write then read: values round trip" {
    run bash -c '
        source "$1"; source "$2"
        write-tsv-conf-lines "$3" > "$3.new" 2>/dev/null
        read-tsv-conf-lines "$3.new"
        printf "%s|%s|%s" "${TSV_APOS}" "${TSV_EQ}" "${TSV_LAST}"
    ' bash "${UTILS}/write-tsv-conf-lines.sh" "${UTILS}/read-tsv-conf-lines.sh" "${TSV_FILE}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "it's|a=b=c|no newline" ]
}

@test "write: a missing file prints nothing" {
    run bash -c 'source "$1"; write-tsv-conf-lines "$2"' bash "${UTILS}/write-tsv-conf-lines.sh" "${BATS_TEST_TMPDIR}/missing.conf"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}
