#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/secret
# @dest-dir: /opt/podshift/cli/modules/secret
# @host-edit: no
# @group: cli
# @category: entry
# @description: Creates, lists, replaces, or removes a Podman secret.
# @details:
#   Runs as the podshift user; podshift switches an admin to that user with `sudo -u podshift -i`.
#   `--replace` overwrites an existing secret. A running container keeps the old value until it is restarted.
# @run-as: podshift
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Refuses a secret name that starts with a dash, such as --help or a mistyped option.
# @arg: $1 - secret name.
# @stderr: the reason when the name is refused.
# @exitcode: 0 if the name may be used, 1 otherwise.
podshift-secret-name() {
    if [[ "${1:-}" == -* ]]; then
        echo "Unknown option: ${1}. See 'podshift --help secret'." >&2
        return 1
    fi
    return 0
}

# @description: Creates, lists, replaces, or removes a Podman secret.
# @details:
#   `--replace` overwrites an existing secret. A running container keeps the old value until it is restarted.
#   The value is never taken as an argument, so it does not land in the shell history or in ps. On a
#   terminal it is typed hidden; otherwise it is read from stdin, without its trailing newlines.
#   A name that starts with a dash is refused as an unknown option before any value is read, and
#   --help or -h shows the help page.
# @arg: $@ - operation: --help, --list, --unset <name>, --replace <name>, or <name>.
# @stdout: the secret list, or one line such as "Saved secret <name>." instead of the Podman secret ID.
# @stderr: errors when a name or value is missing, a name starts with a dash, a value is given as an argument, or Podman fails.
# @exitcode: 0 on success, 1 on failure.
podshift-secret() {
    local name value replace max_args
    replace=0
    max_args=1

    # Help needs no podshift user and no config, so it comes first.
    case "${1:-}" in
        --help|-h)
            # shellcheck source=../../../fn/common/podshift-help.sh
            declare -F podshift-help >/dev/null || source /opt/podshift/fn/common/podshift-help.sh
            podshift-help secret
            return
            ;;
    esac

    # shellcheck source=../../../fn/utils/require-podshift.sh
    declare -F require-podshift >/dev/null || source /opt/podshift/fn/utils/require-podshift.sh
    require-podshift || return 1
    # shellcheck source=../../../fn/rootless/load-rootless-conf.sh
    declare -F load-rootless-conf >/dev/null || source /opt/podshift/fn/rootless/load-rootless-conf.sh || return 1
    load-rootless-conf || return 1

    case "${1:-}" in
        --list|-l)
            podman secret ls || return 1
            return 0
            ;;
        --unset)
            name="${2:-}"
            if [[ -z "${name}" && -t 0 ]]; then
                read -rp "Secret name: " name
            fi
            if [[ -z "${name}" ]]; then
                echo "No secret name provided." >&2
                return 1
            fi
            podshift-secret-name "${name}" || return 1
            podman secret rm "${name}" >/dev/null || {
                echo "Secret ${name} could not be removed." >&2
                return 1
            }
            echo "Removed secret ${name}."
            return 0
            ;;
        --replace)
            replace=1
            max_args=2
            name="${2:-}"
            ;;
        *)
            name="${1:-}"
            ;;
    esac
    podshift-secret-name "${name}" || return 1
    if (( $# > max_args )); then
        echo "A secret value is not taken as an argument, so it stays out of the shell history." >&2
        echo "Type it at the prompt, or send it on stdin: podshift secret ${name} < value-file" >&2
        return 1
    fi

    if [[ -z "${name}" && -t 0 ]]; then
        read -rp "Secret name: " name
    fi
    if [[ -z "${name}" ]]; then
        echo "No secret name provided." >&2
        return 1
    fi
    podshift-secret-name "${name}" || return 1
    if [[ -t 0 ]]; then
        read -rsp "Secret value: " value
        echo
    else
        value="$(cat)"
    fi
    if [[ -z "${value}" ]]; then
        echo "No secret value provided." >&2
        return 1
    fi

    if [[ "${replace}" -eq 1 ]]; then
        printf '%s' "${value}" | podman secret create --replace "${name}" - >/dev/null || {
            echo "Secret ${name} could not be replaced." >&2
            return 1
        }
        echo "Replaced secret ${name}."
        return 0
    fi

    printf '%s' "${value}" | podman secret create "${name}" - >/dev/null || {
        echo "Secret ${name} could not be created. If it already exists, use: podshift secret --replace ${name}" >&2
        return 1
    }
    echo "Saved secret ${name}."
    return 0
}

podshift-secret "$@"
