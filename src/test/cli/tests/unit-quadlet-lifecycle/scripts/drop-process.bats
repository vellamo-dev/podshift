#!/usr/bin/env bats
# Stubbed tests for podshift-drop-process: a file that vanishes during the scan, and settings without fallbacks.
# stat is faked: an old time for every file, the byte count for -c %s, and for a file named gone.* it
# deletes the file and fails, as if another process took it between find and stat.
# Run with: ./test unit-quadlet-lifecycle

setup() {
    load stubs
    stubs-setup
    SERVICE="${FN}/service/drop-process.sh"
    DROP="${BATS_TEST_TMPDIR}/drop"
    TRASH="${BATS_TEST_TMPDIR}/trash"
    QUEUE="${BATS_TEST_TMPDIR}/validation-queue"
    mkdir -p "${DROP}" "${TRASH}" "${QUEUE}"
    export DROP TRASH QUEUE
    cat > "${STUB}/bin/stat" <<'SH'
#!/usr/bin/env bash
format="${2}"
file="${*: -1}"
case "${file##*/}" in
    gone.*)
        rm -f -- "${file}"
        exit 1
        ;;
esac
[ -e "${file}" ] || exit 1
case "${format}" in
    %Y) echo 1000 ;;
    %s) wc -c < "${file}" | tr -d '[:space:]'; echo ;;
    *) exit 1 ;;
esac
SH
    chmod +x "${STUB}/bin/stat"
}

# Runs podshift-drop-process with main.conf stubbed; SETTLE and MAX_KB set the two settings.
run_drop() {
    run bash -c '
        load-podshift-conf-main() {
            PODSHIFT_DROP_DIR="${DROP}"
            PODSHIFT_TRASH_DIR="${TRASH}"
            PODSHIFT_QUADLET_VALIDATION_QUEUE_DIR="${QUEUE}"
            PODSHIFT_DROP_MAX_BUNDLE_SIZE="${MAX_KB-50}"
            PODSHIFT_DROP_QUADLET_EXTENSIONS=".container,.volume,.network,.image"
            PODSHIFT_DROP_SETTLE="${SETTLE-2}"
        }
        source "$1"
        podshift-drop-process
    ' bash "${SERVICE}"
}

@test "a file that vanishes between find and stat is skipped and the others are still handled" {
    printf '[Container]\nImage=x\n' > "${DROP}/a.container"
    printf '[Container]\nImage=y\n' > "${DROP}/gone.container"
    printf '[Container]\nImage=z\n' > "${DROP}/web.container"
    run_drop
    [ "${status}" -eq 0 ]
    [ -f "${QUEUE}/a.container" ]
    [ -f "${QUEUE}/web.container" ]
    [ ! -e "${QUEUE}/gone.container" ]
    [ ! -e "${DROP}/a.container" ]
    [ ! -e "${DROP}/web.container" ]
    grep -q 'podshift-drop-process: skipping gone.container, it is gone' "${STUB}/logger.log"
    [ "$(history-lines)" = "a.container accepted"$'\n'"web.container accepted" ]
}

@test "a missing settle or bundle size setting stops the run without a fallback" {
    printf '[Container]\nImage=x\n' > "${DROP}/a.container"
    SETTLE="" run_drop
    [ "${status}" -eq 0 ]
    [ -f "${DROP}/a.container" ]
    grep -q 'PODSHIFT_DROP_SETTLE is not set' "${STUB}/logger.log"
    MAX_KB="" run_drop
    [ -f "${DROP}/a.container" ]
}
