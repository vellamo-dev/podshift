#!/usr/bin/env bash
# @file: podshift.sh
# @source-dir: src/server/opt/podshift/cli
# @dest-dir: /opt/podshift/cli
# @host-edit: no
# @group: cli
# @category: entry
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
# @arg: $1 - command name.
# @stdout: podshift, root or unknown.
# @exitcode: 0 always.
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
# @arg: $1 - caller (podshift/root/other).
# @arg: $2 - command name.
# @arg: $3+ - command arguments.
# @stderr: a note when the caller may not run it.
# @exitcode: 1 when the caller may not run it; otherwise the process is replaced.
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
# @arg: $1 - caller (root/other).
# @arg: $2 - command name.
# @arg: $3+ - command arguments.
# @stderr: a note when the caller is not root.
# @exitcode: 1 when the caller is not root; otherwise the process is replaced.
podshift-run-root() {
    local user cmd
    user="${1}"; cmd="${2}"
    shift 2
    case "${user}" in
        root) exec "/usr/sbin/${cmd}" "$@" ;;
        *)    echo "Unauthorised: ${cmd} needs root." >&2; return 1 ;;
    esac
}

# @description: Resolves a module by long or short name and runs it, as the podshift user when the module needs it.
# @details:
#   A module tagged "@run-as: podshift" (quadlet, secret) is started with "sudo -u podshift -i" when
#   an admin calls it, the same switch as for the rootless shortcuts. Any other caller runs it as
#   itself, and the module refuses a caller it does not accept.
# @arg: $1 - module name.
# @arg: $2+ - module arguments.
# @exitcode: 1 if no module matched; otherwise the process is replaced.
podshift-run-module() {
    local name long cli_dir main run_as
    name="${1}"
    cli_dir="/opt/podshift/cli"
    main=""

    # Long name: the module directory itself.
    if [[ -x "${cli_dir}/modules/${name}/main.sh" ]]; then
        main="${cli_dir}/modules/${name}/main.sh"
    else
        # Short name: resolved from aliases.conf.
        # shellcheck source=../fn/utils/resolve-cli-alias.sh
        declare -F resolve-cli-alias >/dev/null || source /opt/podshift/fn/utils/resolve-cli-alias.sh
        if long="$(resolve-cli-alias "${name}" "${cli_dir}/aliases.conf")" && [[ -x "${cli_dir}/modules/${long}/main.sh" ]]; then
            main="${cli_dir}/modules/${long}/main.sh"
        fi
    fi
    [[ -n "${main}" ]] || return 1

    run_as="$(grep -m1 '^# @run-as: ' "${main}" 2>/dev/null)"
    run_as="${run_as#*: }"
    if [[ "${run_as}" == "podshift" && "$(podshift-user)" == "root" ]]; then
        exec sudo -u podshift -i "${main}" "${@:2}"
    fi
    exec "${main}" "${@:2}"
}

# @description: Shows the help page of a command, or of the long name of an alias such as hc.
# @details:
#   Only commands have a Markdown page in doc/help, so the plain text pages (the main help and its
#   notes) are not shown here. Nothing of the command runs.
# @arg: $1 - command name or alias.
# @stdout: the help page.
# @stderr: a note for an unknown command.
# @exitcode: 0 after the help page, 1 for an unknown command.
podshift-command-help() {
    local name long
    name="${1}"
    # shellcheck source=../fn/utils/resolve-cli-alias.sh
    declare -F resolve-cli-alias >/dev/null || source /opt/podshift/fn/utils/resolve-cli-alias.sh
    if long="$(resolve-cli-alias "${name}" /opt/podshift/cli/aliases.conf)" && [[ -f "/opt/podshift/doc/help/${long}.md" ]]; then
        # shellcheck source=../fn/common/podshift-help.sh
        declare -F podshift-help >/dev/null || source /opt/podshift/fn/common/podshift-help.sh
        podshift-help "${long}"
        return
    fi
    echo "Unknown command: ${1}. See 'podshift --help'." >&2
    return 1
}

# @description: Dispatches a subcommand to a module or a shortcut.
# @arg: $@ - an optional --plain, then the subcommand and its arguments.
# @stderr: a note for an unknown command.
# @exitcode: 0 after help or the version or a command's help page, 1 for an unknown command or a refused caller; a module or shortcut replaces the process.
podshift-dispatch() {
    local cmd user realm
    # --plain before the command: plain output for every module, see is-interactive-output.
    if [[ "${1:-}" == "--plain" ]]; then
        export PODSHIFT_PLAIN="true"
        shift
    fi
    cmd="${1:-}"

    case "${cmd}" in
        ""|--help|-h) declare -F podshift-help >/dev/null || source /opt/podshift/fn/common/podshift-help.sh; podshift-help "${2:-podshift}"; return ;;
        --version|-v) declare -F podshift-version >/dev/null || source /opt/podshift/fn/common/podshift-version.sh; podshift-version; return ;;
        podshift)      echo "Unknown command: podshift. See 'podshift --help'." >&2; return 1 ;;
    esac

    # <command> --help or -h shows the help page and never runs the command, a module or a shortcut.
    if [[ "${2:-}" == "--help" || "${2:-}" == "-h" ]]; then
        podshift-command-help "${cmd}"
        return
    fi

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
