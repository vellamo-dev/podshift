#!/usr/bin/env bash
# @file: cockpit-read-request.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Reads one request from stdin within fixed size and waiting-time bounds.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reads the request body from stdin with a size bound and a time bound.
# @details:
#   Reading stops when stdin ends, the size bound is passed, or the waiting time is over. Nothing
#   is printed on failure.
# @stdout: the request bytes when they fit the bounds.
# @exitcode: 0 when the body is non-empty and within the bound, 1 when stdin is empty, 2 when the body is larger than 65536 bytes, 3 when the 5 second wait ends first.
cockpit-read-request() {
    local max_bytes wait_seconds tmp start size pid
    # Fixed request bounds: 65536 bytes and 5 seconds.
    max_bytes=65536
    wait_seconds=5
    tmp="$(mktemp)" || return 1
    : >"${tmp}"
    # Bash 3.2 read -t returns 1 at once when a pipe has no data yet. That is
    # the same status as end of file, so a timed read cannot tell them apart.
    # dd bs=1 reads one byte per record on both GNU and BSD, so a short pipe
    # read does not finish the copy early. It blocks while the writer stays open.
    # An explicit stdin redirect is required. Without job control, Bash points a
    # background command at /dev/null when no redirection is written on it.
    dd bs=1 count=$((max_bytes + 1)) of="${tmp}" <&0 2>/dev/null &
    pid=$!
    start="${SECONDS}"
    while kill -0 "${pid}" 2>/dev/null; do
        if (( SECONDS - start >= wait_seconds )); then
            kill -TERM "${pid}" 2>/dev/null || true
            sleep 0.1
            kill -KILL "${pid}" 2>/dev/null || true
            wait "${pid}" 2>/dev/null || true
            rm -f "${tmp}"
            return 3
        fi
        sleep 0.1
    done
    wait "${pid}" 2>/dev/null || true
    size="$(wc -c < "${tmp}" | tr -d '[:space:]')"
    if [[ -z "${size}" || "${size}" == "0" ]]; then
        rm -f "${tmp}"
        return 1
    fi
    if (( size > max_bytes )); then
        rm -f "${tmp}"
        return 2
    fi
    cat -- "${tmp}"
    rm -f "${tmp}"
    return 0
}
