#!/usr/bin/env bash
# @file: systemd-run.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/mocks
# @group: test
# @category: helper
# @description: Mock of systemd-run for the handler cases; the mode comes from COCKPIT_TEST_SYSTEMD_MODE.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
printf '%q ' "$@" >> "${COCKPIT_TEST_ARGV}"
printf '\n' >> "${COCKPIT_TEST_ARGV}"
# systemctl stop looks up systemd-run on PATH. Only the handler invocation may sleep or write.
if [[ "$*" != *cockpit-run-in-session.sh* ]]; then
    exit 0
fi
# The action arguments arrive on stdin, never as a word. Keep them for the cases and hand them on in run mode.
stdin_data="$(cat)"
printf '%s\n' "${stdin_data}" >> "${COCKPIT_TEST_STDIN:-/dev/null}"
# Real systemd-run --pipe fails on a named FIFO or a regular file as stdout or stderr. An anonymous pipe or a terminal works.
# A FIFO with a filesystem name is named. Linux shows pipe:[n] for an anonymous pipe, and lsof on macOS shows ->0x.
for fd in 1 2; do
    fd_bad=""
    if [[ -f "/dev/fd/${fd}" ]]; then
        fd_bad=1
    elif [[ -p "/dev/fd/${fd}" ]]; then
        if [[ -e "/proc/$$/fd/${fd}" ]]; then
            fd_name="$(readlink "/proc/$$/fd/${fd}" 2>/dev/null)"
        else
            fd_name="$(lsof -a -p "$$" -d "${fd}" -Fn 2>/dev/null | sed -n 's/^n//p')"
        fi
        case "${fd_name}" in
            /*) fd_bad=1 ;;
        esac
    fi
    if [[ -n "${fd_bad}" ]]; then
        printf 'Failed to start transient service unit: Failed to set unit properties: Bad message\n' >&2
        exit 1
    fi
done
case "${COCKPIT_TEST_SYSTEMD_MODE:-fail}" in
    emit)
        printf '\034%s' "${COCKPIT_TEST_EMIT}"
        exit "${COCKPIT_TEST_EMIT_RC:-0}"
        ;;
    oversize)
        sleep 60 &
        printf '%s\n' "$!" > "${COCKPIT_TEST_CHILD}"
        printf '\034'
        dd if=/dev/zero bs=140000 count=1 2>/dev/null | tr '\0' 'A'
        wait
        ;;
    timeout)
        sleep 60 &
        printf '%s\n' "$!" > "${COCKPIT_TEST_CHILD}"
        printf '\034{"pong":true,"uid":300}'
        wait
        ;;
    stray)
        printf '\034LEAKED-MODULE-OUTPUT'
        exit 0
        ;;
    twovalue)
        printf '\034{"pong":true}{"pong":false}'
        exit 0
        ;;
    nonzero)
        printf '\nError: module boom\001x\nsecond line\n' >&2
        printf '\034{"pong":true,"uid":300}'
        exit 4
        ;;
    baduid)
        printf '\034{"pong":true,"uid":999}'
        exit 0
        ;;
    run)
        while [[ $# -gt 0 ]]; do
            if [[ "${1}" == "bash" ]]; then
                exec "$@" <<<"${stdin_data}"
            fi
            shift
        done
        exit 1
        ;;
    *)
        printf 'mock: tunnel failed\n' >&2
        exit 1
        ;;
esac
