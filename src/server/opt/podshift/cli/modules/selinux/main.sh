#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/selinux
# @dest-dir: /opt/podshift/cli/modules/selinux
# @host-edit: no
# @group: cli
# @category: entry
# @description: Switches SELinux to enforcing when it is in permissive mode.
# @details:
#   If SELinux is already enforcing, the command changes nothing, except that it also sets
#   SELINUX=enforcing in the config file when that file still has another value. If SELinux is
#   disabled, it changes nothing and prints the steps to turn it back on. It asks before it
#   changes anything; --force skips the question.
# @run-as: root
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_818D351B6DB2:-}" ]]; then
    DIR_818D351B6DB2="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_818D351B6DB2
fi

# @description: Dispatches the selinux subcommands.
# @arg: $1 - subcommand (enforce).
# @exitcode: 0 on success, 1 on failure.
podshift-selinux() {
    case "${1:-}" in
        enforce) shift; podshift-selinux-enforce "$@" ;;
        *) echo "Unknown selinux subcommand: ${1:-}. See 'podshift --help selinux'." >&2; return 1 ;;
    esac
}

# @description: Switches SELinux to enforcing, or prints the steps when it is disabled.
# @details:
#   It asks before it changes the running mode or the config file. --force skips the question.
#   PODSHIFT_SELINUX_CONFIG may point at a config file other than /etc/selinux/config, for tests.
# @arg: $@ - an optional --force that skips the confirmation.
# @stdout: the result, or the steps when SELinux is disabled.
# @stderr: errors.
# @exitcode: 0 on success, when already enforcing, or when cancelled; 1 on failure or when disabled.
podshift-selinux-enforce() {
    local force arg mode config answer b n rc
    force=0

    for arg in "$@"; do
        case "${arg}" in
            --force) force=1 ;;
            *) echo "Usage: podshift selinux enforce [--force]" >&2; return 1 ;;
        esac
    done

    # shellcheck source=../../../fn/utils/require-admin.sh
    declare -F require-admin >/dev/null || source /opt/podshift/fn/utils/require-admin.sh
    require-admin || return 1

    if ! command -v getenforce >/dev/null 2>&1; then
        echo "getenforce was not found. Is SELinux installed?" >&2
        return 1
    fi

    mode="$(getenforce 2>/dev/null)" || mode=""
    mode="$(printf '%s' "${mode}" | tr 'A-Z' 'a-z')"
    config="${PODSHIFT_SELINUX_CONFIG:-/etc/selinux/config}"

    # shellcheck source=../../../fn/utils/selinux-config-is-enforcing.sh
    declare -F selinux-config-is-enforcing >/dev/null || source "${DIR_818D351B6DB2}/../../../fn/utils/selinux-config-is-enforcing.sh"

    case "${mode}" in
        enforcing)
            if selinux-config-is-enforcing "${config}"; then
                echo "SELinux is already enforcing. Nothing to do."
                return 0
            fi
            ;;
        permissive) ;;
        disabled)
            echo "SELinux is disabled. Nothing changed." >&2
            echo "Turning it back on needs a full file relabel and a reboot, which can take a while." >&2
            echo "Steps:" >&2
            echo "  1. Set SELINUX=enforcing, or SELINUX=permissive, in /etc/selinux/config" >&2
            echo "  2. Run: touch /.autorelabel" >&2
            echo "  3. Reboot. The relabel runs at boot and can take a long time." >&2
            return 1
            ;;
        *)
            if [[ -n "${mode}" ]]; then
                echo "SELinux mode is unknown (${mode}). Nothing changed." >&2
            else
                echo "Could not read the SELinux mode. Nothing changed." >&2
            fi
            return 1
            ;;
    esac

    if [[ "${force}" -ne 1 ]]; then
        b=""
        n=""
        # shellcheck source=../../../fn/utils/is-interactive-output.sh
        declare -F is-interactive-output >/dev/null || source /opt/podshift/fn/utils/is-interactive-output.sh
        if is-interactive-output 2; then
            b=$'\033[1m'
            n=$'\033[0m'
        fi
        if [[ "${mode}" == "enforcing" ]]; then
            printf -v answer ''
            read -r -p "SELinux is already enforcing, but ${config} is not set to enforcing. Update the file? [${b}y${n}es/${b}c${n}ancel] " answer
        else
            printf -v answer ''
            read -r -p "SELinux is ${mode}. Switch it to enforcing? [${b}y${n}es/${b}c${n}ancel] " answer
        fi
        case "${answer}" in
            yes|y|Y) ;;
            *) echo "Cancelled."; return 0 ;;
        esac
    fi

    # shellcheck source=../../../fn/utils/selinux-write-config.sh
    declare -F selinux-write-config >/dev/null || source "${DIR_818D351B6DB2}/../../../fn/utils/selinux-write-config.sh"
    # shellcheck source=../../../fn/utils/selinux-set-enforcing.sh
    declare -F selinux-set-enforcing >/dev/null || source "${DIR_818D351B6DB2}/../../../fn/utils/selinux-set-enforcing.sh"

    if [[ "${mode}" == "permissive" ]]; then
        rc=0
        selinux-set-enforcing "${config}" || rc=$?
        if [[ "${rc}" -eq 1 ]]; then
            echo "Failed to switch SELinux to enforcing, nothing changed." >&2
            return 1
        fi
        if [[ "${rc}" -eq 2 ]]; then
            echo "SELinux is now enforcing, but ${config} could not be updated. Set SELINUX=enforcing in that file so the mode survives a reboot." >&2
            return 1
        fi
    else
        if ! selinux-write-config "${config}"; then
            return 1
        fi
    fi

    if [[ "${mode}" == "enforcing" ]]; then
        echo "SELinux is already enforcing. ${config} is now set to enforcing so the mode survives a reboot."
    else
        echo "SELinux is now enforcing. The mode is also set in ${config}."
    fi
    return 0
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    podshift-selinux "$@"
fi
