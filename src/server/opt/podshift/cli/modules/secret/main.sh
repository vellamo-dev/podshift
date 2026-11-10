#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/secret
# @dest-dir: /opt/podshift/cli/modules/secret
# @host-edit: no
# @group: cli
# @category: entry
# @description: Creates, lists, replaces, or removes a Podman secret.
# @details:
#   Runs as the podshift user; root uses `sudo -u podshift -i podshift secret`.
#   `--replace` overwrites an existing secret. A running container keeps the old value until it is restarted.
# @run-as: podshift
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Creates, lists, replaces, or removes a Podman secret.
# @details:
#   `--replace` overwrites an existing secret. A running container keeps the old value until it is restarted.
# @arg: $@ - operation: --list, --unset <name>, --replace <name> [<value>], or <name> [<value>].
# @stderr: errors when a name or value is missing, or when Podman fails.
# @exitcode: 0 on success, 1 on failure.
podshift-secret() {
    local name value replace
    replace=0

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
            if [[ -z "${name}" ]]; then
                read -rp "Secret name: " name
            fi
            if [[ -z "${name}" ]]; then
                echo "No secret name provided." >&2
                return 1
            fi
            podman secret rm "${name}" || {
                echo "Secret ${name} could not be removed." >&2
                return 1
            }
            return 0
            ;;
        --replace)
            replace=1
            name="${2:-}"
            value="${3:-}"
            ;;
        *)
            name="${1:-}"
            value="${2:-}"
            ;;
    esac

    if [[ -z "${name}" ]]; then
        read -rp "Secret name: " name
    fi
    if [[ -z "${name}" ]]; then
        echo "No secret name provided." >&2
        return 1
    fi
    if [[ -z "${value}" ]]; then
        read -rsp "Secret value: " value
        echo
    fi
    if [[ -z "${value}" ]]; then
        echo "No secret value provided." >&2
        return 1
    fi

    if [[ "${replace}" -eq 1 ]]; then
        printf '%s' "${value}" | podman secret create --replace "${name}" - || {
            echo "Secret ${name} could not be replaced." >&2
            return 1
        }
        return 0
    fi

    printf '%s' "${value}" | podman secret create "${name}" - || {
        echo "Secret ${name} could not be created. If it already exists, use: podshift secret --replace ${name}" >&2
        return 1
    }
    return 0
}

podshift-secret "$@"
