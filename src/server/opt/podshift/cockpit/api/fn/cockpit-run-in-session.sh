#!/usr/bin/env bash
# @file: cockpit-run-in-session.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: entry
# @description: Internal entry that cockpit-enter-session starts inside the podshift session.
# @details:
#   Requires UID 300, resolves the action through the dispatch map and prints only that module's
#   data.
# @warning: Do not source this file from the root process. Sourcing it does not change identity. cockpit-enter-session launches it as its own process inside the session.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_7CB42E0E6E57:-}" ]]; then
    DIR_7CB42E0E6E57="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7CB42E0E6E57
fi

# @description: Runs one module as the podshift user and prints only its data.
# @details:
#   Requires effective UID 300, resolves the action through the dispatch map and sources the
#   module. No envelope is written and nothing is logged. The action arguments arrive on stdin as one
#   JSON object, {} when empty, and the module function gets them as its first argument. They are
#   never a command line word.
# @arg: $1 - action name.
# @stdout: the module data on success.
# @stderr: a fixed note when the process is not uid 300.
# @exitcode: 0 when the module ran, 1 when the uid, the action or the module is refused.
cockpit-session-run() {
    local action args resolved canonical fn_name module_dir realm rest
    if [[ "${EUID}" -ne 300 ]]; then
        printf 'podshift-api: session entry requires uid 300\n' >&2
        return 1
    fi
    action="${1:-}"
    args="$(cat)"
    [[ -n "${args}" ]] || args='{}'
    # shellcheck source=./cockpit-dispatch-action.sh
    declare -F cockpit-dispatch-action >/dev/null || source "${DIR_7CB42E0E6E57}/cockpit-dispatch-action.sh"
    resolved="$(cockpit-dispatch-action fields "${action}" 2>/dev/null)" || return 1
    IFS=$'\t' read -r canonical fn_name module_dir realm <<<"${resolved}" || return 1
    [[ "${canonical}" == "${action}" ]] || return 1
    [[ "${realm}" == "podshift" ]] || return 1
    rest="${fn_name#cockpit-module-}"
    [[ -n "${rest}" && "${rest}" != "${fn_name}" ]] || return 1
    case "${rest}" in
        *[!abcdefghijklmnopqrstuvwxyz0123456789-]*) return 1 ;;
    esac
    case "${module_dir}" in
        /*) ;;
        *) return 1 ;;
    esac
    [[ -f "${module_dir}/module.sh" && ! -L "${module_dir}/module.sh" ]] || return 1
    # shellcheck source=/dev/null
    source "${module_dir}/module.sh"
    declare -F "${fn_name}" >/dev/null || return 1
    "${fn_name}" "${args}"
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    set -euo pipefail
    cockpit-session-run "$@"
fi
