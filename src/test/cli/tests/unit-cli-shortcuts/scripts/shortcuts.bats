#!/usr/bin/env bats
# Stubbed tests for the shortcuts in shortcuts/root and shortcuts/rootless: they take no arguments.
# Each shortcut runs from a copy that points at the source tree. podman, systemctl and sudo are fakes,
# and the caller checks and the rootless config are stubbed; every call is logged, so a test can show
# that a refused shortcut ran nothing. Run with: ./test unit-cli-shortcuts

setup() {
    local here repo file
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    repo="$(find-repo-root "${here}")" || return 1
    COPY="${BATS_TEST_TMPDIR}/shortcuts"
    mkdir -p "${COPY}"
    SHORTCUTS=()
    for file in "${repo}"/src/server/opt/podshift/shortcuts/root/*.sh "${repo}"/src/server/opt/podshift/shortcuts/rootless/*.sh; do
        sed "s|/opt/podshift/|${repo}/src/server/opt/podshift/|g" "${file}" > "${COPY}/$(basename "${file}")"
        SHORTCUTS+=("$(basename "${file}" .sh)")
    done
    STUB="${BATS_TEST_TMPDIR}/stub"
    mkdir -p "${STUB}/bin"
    : > "${STUB}/calls.log"
    export STUB
    local tool
    for tool in podman systemctl sudo; do
        printf '#!/usr/bin/env bash\necho "%s $*" >> "${STUB}/calls.log"\nexit 0\n' "${tool}" > "${STUB}/bin/${tool}"
    done
    chmod +x "${STUB}/bin/"*
}

# Runs one shortcut copy: $1 is its name, the rest are its arguments.
run_shortcut() {
    local name
    name="${1}"
    shift
    # The path goes in SHORTCUT, so that with no arguments the shortcut also gets none.
    run env PATH="${STUB}/bin:/usr/bin:/bin:/opt/homebrew/bin" SHORTCUT="${COPY}/${name}.sh" bash -c '
        require-podshift() { echo "require-podshift" >> "${STUB}/calls.log"; }
        require-admin() { echo "require-admin" >> "${STUB}/calls.log"; }
        load-rootless-conf() { echo "load-rootless-conf" >> "${STUB}/calls.log"; }
        source "${SHORTCUT}" "$@"
    ' bash "$@"
}

@test "there are 15 shortcuts" {
    [ "${#SHORTCUTS[@]}" -eq 15 ]
}

@test "every shortcut refuses an argument before any check or command runs" {
    local name arg
    for name in "${SHORTCUTS[@]}"; do
        for arg in --help -h --all x; do
            run_shortcut "${name}" "${arg}"
            [ "${status}" -eq 1 ]
            [ "${output}" = "${name} takes no arguments. See 'podshift --help ${name}'." ]
        done
        run_shortcut "${name}" ""
        [ "${status}" -eq 1 ]
    done
    [ ! -s "${STUB}/calls.log" ]
}

@test "without arguments every shortcut runs its check and then podman or systemctl" {
    local name
    for name in "${SHORTCUTS[@]}"; do
        : > "${STUB}/calls.log"
        run_shortcut "${name}"
        [ "${status}" -eq 0 ]
        grep -qE '^(podman|systemctl) ' "${STUB}/calls.log"
        grep -qE '^require-(podshift|admin)$' "${STUB}/calls.log"
    done
}

@test "update without arguments runs podman auto-update and nothing else" {
    run_shortcut update
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "$(printf 'require-podshift\nload-rootless-conf\npodman auto-update')" ]
}
