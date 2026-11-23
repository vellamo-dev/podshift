#!/usr/bin/env bats
# Stubbed tests for the podshift dispatcher (src/server/opt/podshift/cli/podshift.sh): <command> --help shows help.
# A copy of the dispatcher points at the source tree. sudo, podman, dnf and systemctl are fakes that log any call,
# so a test can show that nothing ran. Run with: ./test unit-cli-secret

setup() {
    local here repo
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    repo="$(find-repo-root "${here}")" || return 1
    HELP_DIR="${repo}/src/server/opt/podshift/doc/help"
    DISPATCH="${BATS_TEST_TMPDIR}/podshift.sh"
    sed "s|/opt/podshift/|${repo}/src/server/opt/podshift/|g" "${repo}/src/server/opt/podshift/cli/podshift.sh" > "${DISPATCH}"
    STUB="${BATS_TEST_TMPDIR}/stub"
    mkdir -p "${STUB}/bin"
    : > "${STUB}/calls.log"
    export STUB
    local tool
    for tool in sudo podman dnf systemctl; do
        printf '#!/usr/bin/env bash\necho "%s $*" >> "${STUB}/calls.log"\nexit 0\n' "${tool}" > "${STUB}/bin/${tool}"
    done
    chmod +x "${STUB}/bin/"*
}

# Runs the dispatcher copy with the fakes first on PATH; stdout is not a terminal, so pages are printed with cat.
run_podshift() {
    run env PATH="${STUB}/bin:/usr/bin:/bin:/opt/homebrew/bin" bash "${DISPATCH}" "$@"
}

@test "a shortcut with --help shows its page and runs nothing" {
    local cmd
    for cmd in containers images update; do
        run_podshift "${cmd}" --help
        [ "${status}" -eq 0 ]
        [ "${output}" = "$(cat "${HELP_DIR}/${cmd}.md")" ]
    done
    [ ! -s "${STUB}/calls.log" ]
}

@test "a module with --help or -h shows its page and runs nothing" {
    local cmd
    for cmd in secret update-self network quadlet health-check; do
        run_podshift "${cmd}" --help
        [ "${status}" -eq 0 ]
        [ "${output}" = "$(cat "${HELP_DIR}/${cmd}.md")" ]
        run_podshift "${cmd}" -h
        [ "${status}" -eq 0 ]
        [ "${output}" = "$(cat "${HELP_DIR}/${cmd}.md")" ]
    done
    [ ! -s "${STUB}/calls.log" ]
}

@test "an alias with --help shows the page of its long name" {
    run_podshift hc --help
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(cat "${HELP_DIR}/health-check.md")" ]
    run_podshift nw -h
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(cat "${HELP_DIR}/network.md")" ]
}

@test "--plain before the command keeps <command> --help working" {
    run_podshift --plain containers --help
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(cat "${HELP_DIR}/containers.md")" ]
}

@test "an unknown command with --help is still an error" {
    local cmd
    for cmd in nosuch note-env-var-conf Bad_Name; do
        run_podshift "${cmd}" --help
        [ "${status}" -eq 1 ]
        [ "${output}" = "Unknown command: ${cmd}. See 'podshift --help'." ]
    done
    [ ! -s "${STUB}/calls.log" ]
}

@test "podshift --help <command> is unchanged" {
    run_podshift --help secret
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(cat "${HELP_DIR}/secret.md")" ]
    run_podshift --help
    [ "${status}" -eq 0 ]
    [[ "${output}" == "podshift: "* ]]
}

@test "podshift --help <alias> shows the page of its long name" {
    run_podshift --help nw
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(cat "${HELP_DIR}/network.md")" ]
    run_podshift --help hc
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(cat "${HELP_DIR}/health-check.md")" ]
    [ ! -s "${STUB}/calls.log" ]
}

@test "podshift --help with an unknown id or alias is still an error" {
    local id
    for id in xx nosuch Bad_Name; do
        run_podshift --help "${id}"
        [ "${status}" -eq 1 ]
        [ "${output}" = "Unknown command. An invalid id '${id}' provided." ]
    done
}

@test "podshift --help still shows the plain text notes" {
    run_podshift --help note-env-var-conf
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(cat "${HELP_DIR}/note-env-var-conf.txt")" ]
}

@test "--help later on the line is passed to the command, not taken as help" {
    run_podshift nosuch arg --help
    [ "${status}" -eq 1 ]
    [ "${output}" = "Unknown command: nosuch. See 'podshift --help'." ]
}

# Runs the dispatcher copy with stdout on a pseudo terminal, so the Markdown path uses glow.
run_podshift_tty() {
    local cmd
    printf -v cmd '%q ' env PATH="${STUB}/bin:/usr/bin:/bin:/opt/homebrew/bin" bash "${DISPATCH}" "$@"
    if script --version >/dev/null 2>&1; then
        run script -qec "${cmd}" /dev/null
    else
        run script -q /dev/null bash -c "${cmd}"
    fi
}

@test "a help page on a terminal is shown with glow at a fixed width of 80" {
    command -v script >/dev/null 2>&1 || skip "script is not installed"
    printf '#!/usr/bin/env bash\necho "glow $*" >> "${STUB}/calls.log"\nexit 0\n' > "${STUB}/bin/glow"
    chmod +x "${STUB}/bin/glow"
    run_podshift_tty --help nw
    [ "${status}" -eq 0 ]
    # One glow call, with the width before the network page.
    [ "$(wc -l < "${STUB}/calls.log")" -eq 1 ]
    grep -qx "glow -w 80 /.*/doc/help/network\.md" "${STUB}/calls.log"
}
