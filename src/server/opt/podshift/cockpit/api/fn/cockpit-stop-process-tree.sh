#!/usr/bin/env bash
# @file: cockpit-stop-process-tree.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Stops a process and the descendants that are still in its tree.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Sends TERM, then KILL, to a process and all of its descendants.
# @details:
#   Descendants are found from parent links. A process-group signal is sent only when this process
#   is the group leader, so the caller's group is left alone.
# @arg: $1 - root process id.
# @stderr: a fixed note when the id is not usable.
# @exitcode: 0 after the signals are sent, 1 when the id is empty, not decimal, or is this shell, pid 0 or pid 1.
cockpit-stop-process-tree() {
    local root pid ppid pgid ch rest member found guard
    local -a queue
    root="${1:-}"
    case "${root}" in
        ''|*[!0123456789]*)
            printf 'podshift-api: process id is not usable\n' >&2
            return 1
            ;;
    esac
    if [[ "${root}" == "0" || "${root}" == "1" || "${root}" == "$$" ]]; then
        printf 'podshift-api: process id is not usable\n' >&2
        return 1
    fi
    queue=("${root}")
    guard=0
    while (( guard < 30 )); do
        guard=$((guard + 1))
        found=0
        while read -r pid ppid; do
            pid="${pid//[[:space:]]/}"
            ppid="${ppid//[[:space:]]/}"
            case "${pid}" in
                ''|*[!0123456789]*) continue ;;
            esac
            case "${ppid}" in
                ''|*[!0123456789]*) continue ;;
            esac
            member=0
            for ch in "${queue[@]}"; do
                [[ "${ch}" == "${ppid}" ]] && member=1
            done
            [[ "${member}" -eq 1 ]] || continue
            member=0
            for ch in "${queue[@]}"; do
                [[ "${ch}" == "${pid}" ]] && member=1
            done
            if [[ "${member}" -eq 0 && "${pid}" != "0" && "${pid}" != "1" && "${pid}" != "$$" ]]; then
                queue+=("${pid}")
                found=1
            fi
        done < <(ps -ax -o pid=,ppid= 2>/dev/null || true)
        [[ "${found}" -eq 1 ]] || break
    done
    pgid="$(ps -o pgid= -p "${root}" 2>/dev/null | tr -d '[:space:]' || true)"
    if [[ "${pgid}" == "${root}" ]]; then
        kill -TERM -- "-${pgid}" 2>/dev/null || true
    fi
    rest=${#queue[@]}
    while (( rest > 0 )); do
        rest=$((rest - 1))
        kill -TERM "${queue[${rest}]}" 2>/dev/null || true
    done
    sleep 0.2
    guard=0
    while (( guard < 10 )); do
        guard=$((guard + 1))
        found=0
        while read -r pid ppid; do
            pid="${pid//[[:space:]]/}"
            ppid="${ppid//[[:space:]]/}"
            case "${pid}" in
                ''|*[!0123456789]*) continue ;;
            esac
            case "${ppid}" in
                ''|*[!0123456789]*) continue ;;
            esac
            member=0
            for ch in "${queue[@]}"; do
                [[ "${ch}" == "${ppid}" ]] && member=1
            done
            [[ "${member}" -eq 1 ]] || continue
            member=0
            for ch in "${queue[@]}"; do
                [[ "${ch}" == "${pid}" ]] && member=1
            done
            if [[ "${member}" -eq 0 && "${pid}" != "0" && "${pid}" != "1" && "${pid}" != "$$" ]]; then
                queue+=("${pid}")
                found=1
            fi
        done < <(ps -ax -o pid=,ppid= 2>/dev/null || true)
        [[ "${found}" -eq 1 ]] || break
    done
    rest=${#queue[@]}
    while (( rest > 0 )); do
        rest=$((rest - 1))
        kill -KILL "${queue[${rest}]}" 2>/dev/null || true
    done
    if [[ "${pgid}" == "${root}" ]]; then
        kill -KILL -- "-${pgid}" 2>/dev/null || true
    fi
    return 0
}
