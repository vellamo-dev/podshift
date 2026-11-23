#!/usr/bin/env bats
# Stubbed tests for podshift secret: the value comes only from a prompt or stdin, never from an argument.
# The caller check and the rootless config are stubbed; podman is a fake that logs its arguments and stdin.
# Run with: ./test unit-cli-secret

setup() {
    local here
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    REPO="$(find-repo-root "${here}")" || return 1
    CLI="${REPO}/src/server/opt/podshift/cli/modules/secret/main.sh"
    STUB="${BATS_TEST_TMPDIR}/stub"
    mkdir -p "${STUB}/bin"
    : > "${STUB}/calls.log"
    export STUB
    cat > "${STUB}/bin/podman" <<'SH'
#!/usr/bin/env bash
echo "podman $*" >> "${STUB}/calls.log"
if [ "${*: -1}" = "-" ]; then
    printf 'stdin=%s\n' "$(cat)" >> "${STUB}/calls.log"
fi
# Podman prints the secret ID on stdout.
echo 0123456789abcdef0123456789
exit 0
SH
    chmod +x "${STUB}/bin/podman"
    PATH="${STUB}/bin:${PATH}"
}

# Runs podshift-secret with the stubs; stdin comes from the caller.
run_secret() {
    run bash -c '
        require-podshift() { return 0; }
        load-rootless-conf() { return 0; }
        podshift-help() { echo "help page: $1"; }
        MODULE="$1"
        shift
        source "${MODULE}" "$@"
    ' bash "${CLI}" "${@}"
}

@test "a value on stdin creates the secret and prints its name, not the Podman ID" {
    run_secret db-password <<< "s3cret"
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "podman secret create db-password -"$'\n'"stdin=s3cret" ]
    [ "${output}" = "Saved secret db-password." ]
}

@test "a value given as an argument is refused and never reaches podman" {
    run_secret db-password s3cret < /dev/null
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"not taken as an argument"* ]]
    [ ! -s "${STUB}/calls.log" ]
}

@test "--replace reads the value from stdin and refuses an argument value" {
    run_secret --replace db-password <<< "n3w"
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "podman secret create --replace db-password -"$'\n'"stdin=n3w" ]
    [ "${output}" = "Replaced secret db-password." ]
    : > "${STUB}/calls.log"
    run_secret --replace db-password n3w < /dev/null
    [ "${status}" -eq 1 ]
    [ ! -s "${STUB}/calls.log" ]
}

@test "without a terminal a missing name or value is refused" {
    run_secret < /dev/null
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"No secret name provided."* ]]
    run_secret db-password < /dev/null
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"No secret value provided."* ]]
    [ ! -s "${STUB}/calls.log" ]
}

@test "--unset removes the named secret" {
    run_secret --unset db-password < /dev/null
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "podman secret rm db-password" ]
    [ "${output}" = "Removed secret db-password." ]
}

@test "--help and -h show the help page and never reach podman, even with a value on stdin" {
    local option
    for option in --help -h; do
        run_secret "${option}" <<< "s3cret"
        [ "${status}" -eq 0 ]
        [ "${output}" = "help page: secret" ]
    done
    [ ! -s "${STUB}/calls.log" ]
}

@test "a name that starts with a dash is refused as an unknown option before a value is read" {
    local name
    for name in --lst -x --help-me; do
        run_secret "${name}" <<< "s3cret"
        [ "${status}" -eq 1 ]
        [ "${output}" = "Unknown option: ${name}. See 'podshift --help secret'." ]
    done
    run_secret --lst extra <<< "s3cret"
    [ "${status}" -eq 1 ]
    [ "${output}" = "Unknown option: --lst. See 'podshift --help secret'." ]
    [ ! -s "${STUB}/calls.log" ]
}

@test "--replace and --unset refuse a name that starts with a dash" {
    local option
    for option in --replace --unset; do
        run_secret "${option}" -x <<< "s3cret"
        [ "${status}" -eq 1 ]
        [ "${output}" = "Unknown option: -x. See 'podshift --help secret'." ]
        run_secret "${option}" --help <<< "s3cret"
        [ "${status}" -eq 1 ]
        [ "${output}" = "Unknown option: --help. See 'podshift --help secret'." ]
    done
    [ ! -s "${STUB}/calls.log" ]
}
