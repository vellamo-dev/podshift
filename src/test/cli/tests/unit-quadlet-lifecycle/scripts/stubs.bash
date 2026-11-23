# Shared setup for the quadlet lifecycle tests: fake podman, systemctl, timeout and logger on PATH.
# Loaded with: load stubs
# The fakes write their calls to ${STUB}/calls.log and logger messages to ${STUB}/logger.log.
#   ${STUB}/exists/<type>-<name>   podman <type> exists <name> returns 0
#   ${STUB}/ps/<filter>            output of podman ps -a --filter <filter> (/ in the filter is _)
#   ${STUB}/fail-install           podman quadlet install fails
#   ${STUB}/fail-rm                podman quadlet rm fails
# podman quadlet rm removes the file or app folder from ${Q}, like the real one.

stubs-setup() {
    local here
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    REPO="$(find-repo-root "${here}")" || return 1
    FN="${REPO}/src/server/opt/podshift/fn"
    STUB="${BATS_TEST_TMPDIR}/stub"
    Q="${BATS_TEST_TMPDIR}/systemd"
    mkdir -p "${STUB}/bin" "${STUB}/exists" "${STUB}/ps" "${Q}"
    : > "${STUB}/calls.log"
    : > "${STUB}/logger.log"
    export STUB Q

    cat > "${STUB}/bin/podman" <<'SH'
#!/usr/bin/env bash
echo "podman $*" >> "${STUB}/calls.log"
case "${1} ${2}" in
    "quadlet install")
        [ -e "${STUB}/fail-install" ] && { echo "Error: a quadlet with that name already exists"; exit 125; }
        exit 0 ;;
    "quadlet rm")
        [ -e "${STUB}/fail-rm" ] && { echo ""; echo "Error: quadlet is busy"; exit 125; }
        target="${*: -1}"
        rm -rf -- "${Q:?}/${target}"
        exit 0 ;;
esac
if [ "${2}" = "exists" ]; then
    [ -e "${STUB}/exists/${1}-${3}" ]
    exit
fi
if [ "${1}" = "ps" ]; then
    filter=""
    while [ $# -gt 0 ]; do
        [ "${1}" = "--filter" ] && filter="${2}"
        shift
    done
    filter="${filter//\//_}"
    [ -f "${STUB}/ps/${filter}" ] && cat "${STUB}/ps/${filter}"
    exit 0
fi
exit 0
SH
    cat > "${STUB}/bin/systemctl" <<'SH'
#!/usr/bin/env bash
echo "systemctl $*" >> "${STUB}/calls.log"
exit 0
SH
    cat > "${STUB}/bin/timeout" <<'SH'
#!/usr/bin/env bash
shift
exec "$@"
SH
    cat > "${STUB}/bin/logger" <<'SH'
#!/usr/bin/env bash
tag=""
while [ $# -gt 0 ]; do
    case "${1}" in
        -t) tag="${2}"; shift 2 ;;
        -p) shift 2 ;;
        *) break ;;
    esac
done
if [ $# -gt 0 ]; then
    echo "${tag}: $*" >> "${STUB}/logger.log"
else
    while IFS= read -r line; do echo "${tag}: ${line}" >> "${STUB}/logger.log"; done
fi
exit 0
SH
    chmod +x "${STUB}/bin/"*
    PATH="${STUB}/bin:${PATH}"
    export PATH
}

# Prints the drop history records as name status [reason], one per line.
history-lines() {
    sed -n 's/^podshift-drop-history: //p' "${STUB}/logger.log" | jq -r '[.name, .status, (.reason // empty)] | join(" ")'
}

# Prints the drop IDs of the drop history records, one per line, in order.
history-ids() {
    sed -n 's/^podshift-drop-history: //p' "${STUB}/logger.log" | jq -r '.id'
}
