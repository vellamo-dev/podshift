#!/usr/bin/env bats
# Stubbed tests for podshift config set and --unset. No VM, no network, no root.
# The caller checks and load-podshift-conf-main are stubbed, and PODSHIFT_TSV_CONF points at a temp file.
# Run with: ./test unit-cli-config

setup() {
    local here repo
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    repo="$(find-repo-root "${here}")" || return 1
    SCRIPT="${repo}/src/server/opt/podshift/cli/modules/config/main.sh"
    TSV_FILE="${BATS_TEST_TMPDIR}/tsv.conf"
    RULES_FILE="${repo}/src/server/opt/podshift/conf/tsv-rules.conf"
    TEMPLATES="${repo}/src/server/opt/podshift/assets/tpl"
    SECRET="Secrets don't belong in config. Use a Podman secret instead."
    printf '# Custom TSV_* variables used by quadlets.\nTSV_KEEP='"'"'kept'"'"'\n' > "${TSV_FILE}"
}

# Runs podshift-config as the given caller: podshift, root or other.
run_config() {
    local caller
    caller="${1}"
    shift
    run env PATH="/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin" \
        CALLER="${caller}" \
        TEST_TSV="${TSV_FILE}" \
        TEST_RULES="${TEST_RULES-${RULES_FILE}}" \
        TEST_TEMPLATES="${TEMPLATES}" \
        TEST_RUNTIME="${BATS_TEST_TMPDIR}/runtime.conf" \
        bash -c '
            is-admin() { [ "${CALLER}" = root ]; }
            is-podshift() { [ "${CALLER}" = podshift ]; }
            require-podshift() { [ "${CALLER}" = podshift ] || { echo "Unauthorised. podshift user required." >&2; return 1; }; }
            # Root runs as itself; the test is not root, so sudo only runs the command.
            sudo() { "$@"; }
            load-podshift-conf-main() {
                PODSHIFT_TSV_CONF="${TEST_TSV}"
                PODSHIFT_TSV_RULES_CONF="${TEST_RULES}"
                PODSHIFT_RUNTIME_CONF="${TEST_RUNTIME}"
                PODSHIFT_RUNTIME_CONF_TEMPLATES="${TEST_TEMPLATES}"
                PODSHIFT_SYSTEM_CONFIG_KEYS="PODSHIFT_NW_INITIALIZER,PODSHIFT_NW_DEVICE"
            }
            source "$1" || exit 1
            shift
            podshift-config "$@"
        ' bash "${SCRIPT}" "$@"
}

key_lines() {
    grep -c "^${1}=" "${TSV_FILE}" || true
}

@test "set: a new key is saved single-quoted" {
    run_config podshift TSV_APP_DOMAIN example.com
    echo "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Updated TSV_APP_DOMAIN." ]
    grep -qx "TSV_APP_DOMAIN='example.com'" "${TSV_FILE}"
    grep -qx "TSV_KEEP='kept'" "${TSV_FILE}"
}

@test "set: an existing key is replaced, not repeated" {
    run_config podshift TSV_KEEP new
    [ "${status}" -eq 0 ]
    [ "$(key_lines TSV_KEEP)" = "1" ]
    grep -qx "TSV_KEEP='new'" "${TSV_FILE}"
}

@test "set: invalid names are refused" {
    local key
    for key in TSV_app TSV_ TSV_1A APP_NAME; do
        run_config podshift "${key}" x
        echo "${output}"
        [ "${status}" -eq 1 ]
        [[ "${output}" == "Invalid name '${key}'."* ]]
    done
    [ "$(wc -l < "${TSV_FILE}" | tr -d ' ')" = "2" ]
}

@test "set: names starting with TSV_NW or TSV_ENV are refused" {
    local key
    for key in TSV_NW1 TSV_NW9 TSV_NWORDER TSV_ENV2; do
        run_config podshift "${key}" x
        echo "${output}"
        [ "${status}" -eq 1 ]
        [ "${output}" = "Name '${key}' is reserved. Names starting with TSV_NW or TSV_ENV are managed by PodShift." ]
        [ "$(key_lines "${key}")" = "0" ]
    done
}

@test "set: secret names are refused, whole words only" {
    local key
    for key in TSV_DB_PASSWORD TSV_API_TOKEN TSV_API_KEY TSV_SECRET; do
        run_config podshift "${key}" x
        [ "${status}" -eq 1 ]
        [ "${output}" = "${SECRET}" ]
        [ "$(key_lines "${key}")" = "0" ]
    done
    for key in TSV_PASSAGE TSV_KEYBOARD TSV_TOKENIZER_MODEL; do
        run_config podshift "${key}" x
        [ "${status}" -eq 0 ]
    done
}

@test "set: refused values change nothing" {
    local value
    run_config podshift TSV_APP ""
    [ "${status}" -eq 1 ]
    [ "${output}" = "Value must not be empty." ]
    for value in 'a"b' "it's" 'end\' $'a\nb'; do
        run_config podshift TSV_APP "${value}"
        [ "${status}" -eq 1 ]
        [[ "${output}" == "Value must not contain quotes"* ]]
    done
    run_config podshift TSV_APP "gh""p_abcdefghijABCDEFGHIJ0123456789abcdef"
    [ "${status}" -eq 1 ]
    [ "${output}" = "${SECRET}" ]
    [ "$(key_lines TSV_APP)" = "0" ]
}

@test "set: a digest or UUID value is saved" {
    run_config podshift TSV_IMAGE "quay.io/app@sha256:e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
    [ "${status}" -eq 0 ]
    run_config podshift TSV_ID "550e8400-e29b-41d4-a716-446655440000"
    [ "${status}" -eq 0 ]
    [ "$(key_lines TSV_IMAGE)" = "1" ]
    [ "$(key_lines TSV_ID)" = "1" ]
}

@test "set: missing rules file saves nothing" {
    TEST_RULES="${BATS_TEST_TMPDIR}/missing.conf" run_config podshift TSV_APP ok
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"Cannot read the config rules file"* ]]
    [ "$(key_lines TSV_APP)" = "0" ]
}

@test "set: another user is unauthorised" {
    run_config other TSV_APP ok
    [ "${status}" -eq 1 ]
    [ "${output}" = "Unauthorised. Root or podshift user required." ]
}

@test "unset: removes the key and keeps the rest" {
    printf "TSV_APP='a'\nTSV_OTHER='b'\nTSV_APP='c'\n" >> "${TSV_FILE}"
    run_config podshift --unset TSV_APP
    echo "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "Removed TSV_APP." ]
    [ "$(key_lines TSV_APP)" = "0" ]
    grep -qx "TSV_OTHER='b'" "${TSV_FILE}"
    grep -qx "TSV_KEEP='kept'" "${TSV_FILE}"
    grep -q "^# Custom TSV_" "${TSV_FILE}"
}

@test "unset: a key that is not set is an error" {
    run_config podshift --unset TSV_NOPE
    [ "${status}" -eq 1 ]
    [ "${output}" = "TSV_NOPE is not set." ]
}

@test "unset: reserved and invalid names are refused" {
    local key
    printf "TSV_NW9='x'\n" >> "${TSV_FILE}"
    for key in TSV_NW1 TSV_NW9 TSV_ENV2; do
        run_config podshift --unset "${key}"
        [ "${status}" -eq 1 ]
        [[ "${output}" == "Name '${key}' is reserved."* ]]
    done
    [ "$(key_lines TSV_NW9)" = "1" ]
    run_config podshift --unset 'TSV_a.*'
    [ "${status}" -eq 1 ]
    [[ "${output}" == "Invalid name 'TSV_a.*'."* ]]
}

@test "unset: a key with a secret name saved earlier can be removed" {
    printf "TSV_DB_PASSWORD='old'\n" >> "${TSV_FILE}"
    run_config podshift --unset TSV_DB_PASSWORD
    [ "${status}" -eq 0 ]
    [ "$(key_lines TSV_DB_PASSWORD)" = "0" ]
}

@test "unset: root and other users are unauthorised" {
    local caller
    for caller in root other; do
        run_config "${caller}" --unset TSV_KEEP
        [ "${status}" -eq 1 ]
        [ "${output}" = "Unauthorised. Only the podshift user may remove custom TSV_* keys." ]
    done
    [ "$(key_lines TSV_KEEP)" = "1" ]
}

@test "unset: a missing or extra argument prints the usage" {
    run_config podshift --unset
    [ "${status}" -eq 1 ]
    [ "${output}" = "Usage: config --unset <key>" ]
    run_config podshift --unset TSV_KEEP extra
    [ "${status}" -eq 1 ]
    [ "${output}" = "Usage: config --unset <key>" ]
}

@test "set: a hand-added bad line is dropped on the next save, with a note, and never run" {
    printf 'touch %s\nTSV_HAND=hand\n' "${BATS_TEST_TMPDIR}/marker" >> "${TSV_FILE}"
    run_config podshift TSV_APP ok
    echo "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" = $'Dropped 1 invalid line(s) from tsv.conf.\nUpdated TSV_APP.' ]
    ! grep -q "^touch" "${TSV_FILE}"
    grep -qx "TSV_HAND='hand'" "${TSV_FILE}"
    grep -qx "TSV_APP='ok'" "${TSV_FILE}"
    grep -qx "TSV_KEEP='kept'" "${TSV_FILE}"
    [ ! -e "${BATS_TEST_TMPDIR}/marker" ]
}

@test "unset: a hand-added bad line is dropped with a note" {
    printf 'export PATH=/nowhere\nTSV_APP=a\n' >> "${TSV_FILE}"
    run_config podshift --unset TSV_APP
    [ "${status}" -eq 0 ]
    [ "${output}" = $'Dropped 1 invalid line(s) from tsv.conf.\nRemoved TSV_APP.' ]
    ! grep -q "PATH" "${TSV_FILE}"
    grep -qx "TSV_KEEP='kept'" "${TSV_FILE}"
}

@test "set: TSV_ENV is refused for every caller, root included" {
    local caller
    : > "${BATS_TEST_TMPDIR}/runtime.conf"
    for caller in root podshift other; do
        run_config "${caller}" TSV_ENV prod
        echo "${output}"
        [ "${status}" -eq 1 ]
        [ "${output}" = "TSV_ENV is set with: sudo podshift env --set <tag>" ]
    done
    [ ! -s "${BATS_TEST_TMPDIR}/runtime.conf" ]
    [ "$(key_lines TSV_ENV)" = "0" ]
}

@test "unset: TSV_ENV is refused for every caller, root included" {
    local caller
    printf "TSV_ENV='dev'\n" > "${BATS_TEST_TMPDIR}/runtime.conf"
    for caller in root podshift other; do
        run_config "${caller}" --unset TSV_ENV
        [ "${status}" -eq 1 ]
        [ "${output}" = "TSV_ENV is set with: sudo podshift env --set <tag>" ]
    done
    [ "$(cat "${BATS_TEST_TMPDIR}/runtime.conf")" = "TSV_ENV='dev'" ]
}

@test "set: root is still refused for a key outside the system keys" {
    run_config root TSV_APP x
    [ "${status}" -eq 1 ]
    [ "${output}" = "Invalid key 'TSV_APP'. Root may only set: PODSHIFT_NW_INITIALIZER,PODSHIFT_NW_DEVICE" ]
}

@test "set: root saves a system key in the runtime config" {
    # BSD install has no -D, so the file is there already and the template is not used.
    printf "# runtime\n" > "${BATS_TEST_TMPDIR}/runtime.conf"
    run_config root PODSHIFT_NW_DEVICE eth0
    [ "${status}" -eq 0 ]
    [ "${output}" = "Updated PODSHIFT_NW_DEVICE." ]
    grep -qx "PODSHIFT_NW_DEVICE='eth0'" "${BATS_TEST_TMPDIR}/runtime.conf"
}

@test "get: a saved key is printed" {
    run_config podshift TSV_KEEP
    [ "${status}" -eq 0 ]
    [ "${output}" = "TSV_KEEP='kept'" ]
}

@test "get: a key with pattern characters is refused" {
    run_config podshift 'TSV_.*'
    [ "${status}" -eq 1 ]
    [ "${output}" = "Invalid key 'TSV_.*'. A key has only letters, digits and underscores." ]
}
