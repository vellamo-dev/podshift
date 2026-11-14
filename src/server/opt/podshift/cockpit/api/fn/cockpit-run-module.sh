#!/usr/bin/env bash
# @file: cockpit-run-module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Runs one resolved module in its declared realm with bounded time and output.
# @details:
#   Captures stdout, checks the exit status and requires exactly one JSON value.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_22B830488942:-}" ]]; then
    DIR_22B830488942="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_22B830488942
fi

# @description: Runs the dispatch entry for one action in its declared realm and prints its JSON value.
# @details:
#   Output is captured as it arrives, up to 131072 bytes after a podshift session marker, with a 10
#   second wall-clock bound (120 seconds for health-check) that includes the session tunnel and descendant processes. A missing
#   session marker with a failed tunnel is REALM_UNAVAILABLE, and the systemd-run diagnostics are
#   then printed to stderr. Timeout, size, nonzero status and output that is not one JSON value are
#   internal failures. Module bytes are not printed on failure.
# @arg: $1 - action name.
# @arg: $2 - action arguments as one JSON object, already checked against the input contract; {} when empty. The module function gets it as its first argument.
# @stdout: the module JSON value on success.
# @stderr: a fixed diagnostic, with no module body.
# @exitcode: 0 on success, 10 when the podshift session could not be entered, 11 on an internal failure, 12 when output exceeded the bound, 13 when the time bound was exceeded.
cockpit-run-module() {
    local action args work rc
    action="${1:-}"
    args="${2:-}"
    [[ -n "${args}" ]] || args='{}'
    work="$(mktemp -d 2>/dev/null)" || {
        printf 'podshift-api: could not create a work directory\n' >&2
        return 11
    }
    (
        set +e
        max_bytes=131072
        timeout_s=10
        if [[ "${action}" == "health-check" ]]; then
            timeout_s=120
        fi
        # shellcheck source=./cockpit-dispatch-action.sh
        declare -F cockpit-dispatch-action >/dev/null || source "${DIR_22B830488942}/cockpit-dispatch-action.sh"
        # shellcheck source=./cockpit-enter-session.sh
        declare -F cockpit-enter-session >/dev/null || source "${DIR_22B830488942}/cockpit-enter-session.sh"
        # shellcheck source=./cockpit-stop-process-tree.sh
        declare -F cockpit-stop-process-tree >/dev/null || source "${DIR_22B830488942}/cockpit-stop-process-tree.sh"
        resolved="$(cockpit-dispatch-action lookup "${action}" 2>/dev/null)" || exit 11
        canonical="$(printf '%s' "${resolved}" | jq -r '.action')" || exit 11
        [[ "${canonical}" == "${action}" ]] || exit 11
        fn_name="$(printf '%s' "${resolved}" | jq -r '.function')" || exit 11
        module_dir="$(printf '%s' "${resolved}" | jq -r '.directory')" || exit 11
        realm="$(printf '%s' "${resolved}" | jq -r '.realm')" || exit 11
        case "${realm}" in
            root|podshift) ;;
            *) exit 11 ;;
        esac
        rest="${fn_name#cockpit-module-}"
        [[ -n "${rest}" && "${rest}" != "${fn_name}" ]] || exit 11
        case "${rest}" in
            *[!abcdefghijklmnopqrstuvwxyz0123456789-]*) exit 11 ;;
        esac
        case "${module_dir}" in
            /*) ;;
            *) exit 11 ;;
        esac
        [[ -f "${module_dir}/module.sh" && ! -L "${module_dir}/module.sh" ]] || exit 11
        if [[ "${realm}" == "podshift" ]]; then
            max_capture=$((max_bytes + 1))
        else
            max_capture="${max_bytes}"
        fi
        mkfifo "${work}/fifo" || exit 11
        # The leader file is written by the session process itself. setsid may fork, so $! is not a reliable group id.
        : >"${work}/leader"
        if command -v setsid >/dev/null 2>&1; then
            if [[ "${realm}" == "podshift" ]]; then
                setsid --wait bash -c 'printf "%s\n" "$$" > "$4"; source "$1"; cockpit-enter-session "$2" "$3" "$5"' _ \
                    "${DIR_22B830488942}/cockpit-enter-session.sh" "${action}" "${work}/unit" "${work}/leader" "${args}" \
                    >"${work}/fifo" 2>"${work}/err" &
            else
                setsid --wait bash -c 'printf "%s\n" "$$" > "$3"; source "$1"; "$2" "$4"' _ \
                    "${module_dir}/module.sh" "${fn_name}" "${work}/leader" "${args}" \
                    >"${work}/fifo" 2>"${work}/err" &
            fi
        else
            if [[ "${realm}" == "podshift" ]]; then
                bash -c 'printf "%s\n" "$$" > "$4"; source "$1"; cockpit-enter-session "$2" "$3" "$5"' _ \
                    "${DIR_22B830488942}/cockpit-enter-session.sh" "${action}" "${work}/unit" "${work}/leader" "${args}" \
                    >"${work}/fifo" 2>"${work}/err" &
            else
                bash -c 'printf "%s\n" "$$" > "$3"; source "$1"; "$2" "$4"' _ \
                    "${module_dir}/module.sh" "${fn_name}" "${work}/leader" "${args}" \
                    >"${work}/fifo" 2>"${work}/err" &
            fi
        fi
        starter=$!
        : >"${work}/out"
        # dd, not read -t. On Bash 3.2, read -t returns 1 immediately when a
        # pipe has no data yet, and that status is also used for end of file.
        # bs=1 is one byte per record on GNU and BSD dd, so the copy stops only
        # at the count or when the writer closes.
        dd bs=1 count=$((max_capture + 1)) of="${work}/out" <"${work}/fifo" 2>/dev/null &
        reader=$!
        prod=""
        waited=0
        while (( waited < 50 )); do
            if [[ -s "${work}/leader" ]]; then
                prod="$(head -n 1 "${work}/leader")"
                break
            fi
            if ! kill -0 "${starter}" 2>/dev/null && ! kill -0 "${reader}" 2>/dev/null; then
                break
            fi
            sleep 0.05
            waited=$((waited + 1))
        done
        case "${prod}" in
            ''|*[!0123456789]*) prod="${starter}" ;;
        esac
        : >"${work}/timed_out"
        deadline=$((SECONDS + timeout_s))
        (
            sleep "${timeout_s}"
            printf '1\n' > "${work}/timed_out"
        ) &
        watchdog=$!
        timed_out=0
        oversized=0
        while kill -0 "${reader}" 2>/dev/null; do
            if [[ -s "${work}/timed_out" ]] || (( SECONDS >= deadline )); then
                timed_out=1
                break
            fi
            size="$(wc -c < "${work}/out" | tr -d '[:space:]')"
            if [[ -n "${size}" ]] && (( size > max_capture )); then
                oversized=1
                break
            fi
            sleep 0.1
        done
        if [[ -s "${work}/timed_out" ]]; then
            timed_out=1
        fi
        size="$(wc -c < "${work}/out" | tr -d '[:space:]')"
        if [[ -n "${size}" ]] && (( size > max_capture )); then
            oversized=1
        fi
        # Stop the flag sleeper before it can do anything else.
        cockpit-stop-process-tree "${watchdog}" >/dev/null 2>&1 || true
        wait "${watchdog}" 2>/dev/null || true
        if [[ "${timed_out}" -eq 1 || "${oversized}" -eq 1 ]]; then
            if [[ -s "${work}/unit" ]]; then
                unit="$(head -n 1 "${work}/unit")"
                case "${unit}" in
                    podshift-api-*)
                        if command -v systemctl >/dev/null 2>&1; then
                            if command -v timeout >/dev/null 2>&1; then
                                timeout 2 systemctl --machine=podshift@.host --user stop "${unit}.service" >/dev/null 2>&1 || true
                            else
                                systemctl --machine=podshift@.host --user stop "${unit}.service" >/dev/null 2>&1 || true
                            fi
                        fi
                        ;;
                esac
            fi
            # Record descendants while the parent is still alive. Killing the
            # parent first makes macOS reparent them to pid 1, and the tree walk
            # then cannot see them.
            cockpit-stop-process-tree "${prod}" >/dev/null 2>&1 || true
            if [[ "${starter}" != "${prod}" ]]; then
                cockpit-stop-process-tree "${starter}" >/dev/null 2>&1 || true
            fi
            kill -TERM "${reader}" "${prod}" "${starter}" 2>/dev/null || true
            sleep 0.1
            kill -KILL "${reader}" "${prod}" "${starter}" 2>/dev/null || true
            wait "${reader}" 2>/dev/null || true
            wait "${starter}" 2>/dev/null || true
            if [[ "${timed_out}" -eq 1 ]]; then
                printf 'podshift-api: module run exceeded the time bound\n' >&2
                exit 13
            fi
            printf 'podshift-api: module output exceeded the size bound\n' >&2
            exit 12
        fi
        wait "${reader}" 2>/dev/null || true
        wait "${starter}" 2>/dev/null
        prod_rc=$?
        if [[ "${timed_out}" -eq 1 ]]; then
            printf 'podshift-api: module run exceeded the time bound\n' >&2
            exit 13
        fi
        if [[ "${oversized}" -eq 1 ]]; then
            printf 'podshift-api: module output exceeded the size bound\n' >&2
            exit 12
        fi
        size="$(wc -c < "${work}/out" | tr -d '[:space:]')"
        if (( size > max_capture )); then
            printf 'podshift-api: module output exceeded the size bound\n' >&2
            exit 12
        fi
        if [[ "${realm}" == "podshift" ]]; then
            first="$(dd bs=1 count=1 < "${work}/out" 2>/dev/null || true)"
            if [[ "${first}" != $'\034' ]]; then
                if [[ "${prod_rc}" -ne 0 ]]; then
                    printf 'podshift-api: podshift session could not be entered\n' >&2
                    # No marker means no module ran, so stderr holds only systemd-run diagnostics.
                    head -c 2000 "${work}/err" 2>/dev/null | sed 's/^/podshift-api: systemd-run: /' >&2
                    exit 10
                fi
                printf 'podshift-api: module output was not one JSON value\n' >&2
                exit 11
            fi
            tail -c +2 "${work}/out" > "${work}/data"
        else
            cp "${work}/out" "${work}/data"
        fi
        data_size="$(wc -c < "${work}/data" | tr -d '[:space:]')"
        if (( data_size > max_bytes )); then
            printf 'podshift-api: module output exceeded the size bound\n' >&2
            exit 12
        fi
        if [[ "${prod_rc}" -ne 0 ]]; then
            printf 'podshift-api: module failed\n' >&2
            exit 11
        fi
        if ! jq -e -s 'length == 1' < "${work}/data" >/dev/null 2>&1; then
            printf 'podshift-api: module output was not one JSON value\n' >&2
            exit 11
        fi
        compact="$(jq -c -s '.[0]' < "${work}/data" 2>/dev/null)" || exit 11
        printf '%s\n' "${compact}"
        exit 0
    ) && rc=0 || rc=$?
    rm -rf "${work}"
    return "${rc}"
}
