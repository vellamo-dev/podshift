#!/usr/bin/env bats
# Stubbed tests for podshift quadlet rm and the remove queue service (podshift-qdl-remove).
# The caller check, the config loaders and remove-item are stubbed. No VM, no network, no root.
# Run with: ./test unit-quadlet-lifecycle

setup() {
    load stubs
    stubs-setup
    CLI="${REPO}/src/server/opt/podshift/cli/modules/quadlet/main.sh"
    SERVICE="${FN}/service/qdl-remove.sh"
    QUEUE="${BATS_TEST_TMPDIR}/remove-queue"
    mkdir -p "${QUEUE}"
    export QUEUE
}

# Runs podshift-quadlet with stubs; RM_RC sets the remove-item status.
run_cli() {
    run bash -c '
        require-podshift() { [ "${CALLER:-podshift}" = podshift ] || { echo "Unauthorised. podshift user required." >&2; return 1; }; }
        load-rootless-conf() { return 0; }
        podshift-help() { echo "help $*"; }
        load-podshift-conf-main() { PODSHIFT_PODMAN_QUADLETS_DIR="${Q}"; PODSHIFT_QUADLET_STOP_TIMEOUT=120; }
        remove-item() { echo "remove-item $*" >> "${STUB}/calls.log"; [ "${RM_RC:-0}" -eq 0 ] || echo "used by web.container"; return "${RM_RC:-0}"; }
        source "$1" || exit 1
        shift
        podshift-quadlet "$@"
    ' bash "${CLI}" "$@"
}

@test "--help shows the quadlet help" {
    run_cli --help
    [ "${status}" -eq 0 ]
    [ "${output}" = "help quadlet" ]
    [ ! -s "${STUB}/calls.log" ]
}

@test "rm --yes removes without asking" {
    run_cli rm web.network --yes
    [ "${status}" -eq 0 ]
    [ "${output}" = "Removed web.network." ]
    [ "$(cat "${STUB}/calls.log")" = "remove-item web.network ${Q} 0 120" ]
}

@test "rm --volumes passes the volumes flag" {
    run_cli rm shop --volumes -y
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "remove-item shop ${Q} 1 120" ]
}

@test "a no at the prompt removes nothing" {
    run_cli rm web.network <<< "n"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Not removed." ]]
    [ ! -s "${STUB}/calls.log" ]
}

@test "a refused removal prints the reason and returns 1" {
    RM_RC=3 run_cli rm front.network --yes
    [ "${status}" -eq 1 ]
    [ "${output}" = "front.network was not removed: used by web.container" ]
}

@test "a missing name, two names, an unknown option or subcommand return 1" {
    run_cli rm
    [ "${status}" -eq 1 ]
    run_cli rm a.network b.network
    [ "${status}" -eq 1 ]
    run_cli rm a.network --force
    [ "${status}" -eq 1 ]
    run_cli ls
    [ "${status}" -eq 1 ]
    [ ! -s "${STUB}/calls.log" ]
}

@test "another caller than podshift is refused" {
    CALLER=root run_cli rm web.network --yes
    [ "${status}" -eq 1 ]
    [ ! -s "${STUB}/calls.log" ]
}

@test "the service handles the queue oldest first, keeps a marker while removing and skips hidden files" {
    printf 'volumes=1\n' > "${QUEUE}/shop"
    touch -t 202601010100 "${QUEUE}/shop"
    printf 'volumes=0\n' > "${QUEUE}/web.network"
    touch -t 202601010200 "${QUEUE}/web.network"
    : > "${QUEUE}/.request.abc123"
    run bash -c '
        load-podshift-conf-main() { PODSHIFT_QUADLET_REMOVE_QUEUE_DIR="${QUEUE}"; PODSHIFT_PODMAN_QUADLETS_DIR="${Q}"; PODSHIFT_QUADLET_STOP_TIMEOUT=60; }
        remove-item() { [ -e "${QUEUE}/${1}" ] && echo "request still there" >> "${STUB}/calls.log"; [ -e "${QUEUE}/.removing.${1}" ] || echo "no marker" >> "${STUB}/calls.log"; echo "remove-item $*" >> "${STUB}/calls.log"; return 1; }
        source "$1"
        podshift-qdl-remove
    ' bash "${SERVICE}"
    [ "${status}" -eq 0 ]
    [ "$(cat "${STUB}/calls.log")" = "remove-item shop ${Q} 1 60"$'\n'"remove-item web.network ${Q} 0 60" ]
    [ -e "${QUEUE}/.request.abc123" ]
    [ ! -e "${QUEUE}/shop" ]
    [ ! -e "${QUEUE}/.removing.shop" ]
    [ ! -e "${QUEUE}/.removing.web.network" ]
}

@test "the service deletes markers left by a stopped run before it starts" {
    : > "${QUEUE}/.removing.web.container"
    run bash -c '
        load-podshift-conf-main() { PODSHIFT_QUADLET_REMOVE_QUEUE_DIR="${QUEUE}"; PODSHIFT_PODMAN_QUADLETS_DIR="${Q}"; PODSHIFT_QUADLET_STOP_TIMEOUT=60; }
        remove-item() { echo "remove-item $*" >> "${STUB}/calls.log"; return 0; }
        source "$1"
        podshift-qdl-remove
    ' bash "${SERVICE}"
    [ "${status}" -eq 0 ]
    [ ! -e "${QUEUE}/.removing.web.container" ]
    [ ! -s "${STUB}/calls.log" ]
}
