#!/usr/bin/env bash
# @file: podshift.sh
# @dir: /opt/podshift/cli
# @group: cli
# @description: PodShift command dispatcher.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the caller realm: podshift, root, or other.
# @exitcode: 0 on success, 1 if the helpers cannot be sourced.
podshift-user() {
    source /opt/podshift/fn/utils/is-podshift.sh || return 1
    source /opt/podshift/fn/utils/is-admin.sh || return 1
    if is-podshift; then
        echo podshift
    elif is-admin; then
        echo root
    else
        echo other
    fi
}

# @description: Prints the realm a shortcut belongs to: podshift, root, or unknown.
# @param: $1 - command name.
podshift-realm() {
    local link target
    for link in "/usr/bin/${1}" "/usr/sbin/${1}"; do
        [[ -L "${link}" ]] || continue
        target="$(readlink "${link}")"
        case "${target}" in
            */shortcuts/root/*)     echo root; return 0 ;;
            */shortcuts/rootless/*) echo podshift; return 0 ;;
            */cli/*)                echo podshift; return 0 ;;
        esac
    done
    echo unknown
}

# @description: Runs a podshift-realm (rootless) command for the caller.
# @param: $1 - caller (podshift/root/other).
# @param: $2 - command name.
# @param: $3+ - command arguments.
podshift-run-podshift() {
    local user cmd
    user="${1}"; cmd="${2}"
    shift 2
    case "${user}" in
        podshift) exec "/usr/bin/${cmd}" "$@" ;;
        root)     exec sudo -u podshift -i "/usr/bin/${cmd}" "$@" ;;
        *)        echo "Unauthorised: ${cmd} needs the podshift user or root." >&2; return 1 ;;
    esac
}

# @description: Runs a root-realm command for the caller.
# @param: $1 - caller (root/other).
# @param: $2 - command name.
# @param: $3+ - command arguments.
podshift-run-root() {
    local user cmd
    user="${1}"; cmd="${2}"
    shift 2
    case "${user}" in
        root) exec "/usr/sbin/${cmd}" "$@" ;;
        *)    echo "Unauthorised: ${cmd} needs root." >&2; return 1 ;;
    esac
}

# @description: Resolves a module by long or short name and runs it.
# @param: $1 - module name.
# @param: $2+ - module arguments.
# @exitcode: 1 if no module matched; otherwise the process is replaced.
podshift-run-module() {
    local name long cli_dir
    name="${1}"
    cli_dir="/opt/podshift/cli"

    # Long name: the module directory itself.
    if [[ -x "${cli_dir}/modules/${name}/main.sh" ]]; then
        exec "${cli_dir}/modules/${name}/main.sh" "${@:2}"
    fi

    # Short name: one grep in aliases.conf.
    long="$(grep -m1 "^${name}=" "${cli_dir}/aliases.conf" 2>/dev/null)"
    long="${long#*=}"
    if [[ "${long}" =~ ^[a-z][a-z0-9]*(-[a-z][a-z0-9]*){0,2}$ && -x "${cli_dir}/modules/${long}/main.sh" ]]; then
        exec "${cli_dir}/modules/${long}/main.sh" "${@:2}"
    fi

    return 1
}

# @description: Dispatches a subcommand to a module or a shortcut.
# @param: $@ - subcommand and its arguments.
podshift-dispatch() {
    local cmd user realm
    cmd="${1:-}"

    case "${cmd}" in
        ""|--help|-h) source /opt/podshift/fn/common/podshift-help.sh "${2:-help-usage-guide}"; return ;;
        --version|-v) source /opt/podshift/fn/common/podshift-version.sh --now; return ;;
        podshift)      echo "Unknown command: podshift. See 'podshift --help'." >&2; return 1 ;;
    esac

    # A module: a safe name that resolves to a directory or an alias.
    if [[ "${cmd}" =~ ^[a-z][a-z0-9]*(-[a-z][a-z0-9]*){0,2}$ ]]; then
        podshift-run-module "${cmd}" "${@:2}"
    fi

    # Fall back to the shortcuts.
    user="$(podshift-user)"
    realm="$(podshift-realm "${cmd}")"

    case "${realm}" in
        podshift) podshift-run-podshift "${user}" "${cmd}" "${@:2}" ;;
        root)     podshift-run-root "${user}" "${cmd}" "${@:2}" ;;
        unknown)  echo "Unknown command: ${cmd}. See 'podshift --help'." >&2; return 1 ;;
    esac
}

podshift-dispatch "$@"
