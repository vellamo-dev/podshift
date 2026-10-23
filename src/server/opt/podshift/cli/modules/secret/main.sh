#!/usr/bin/env bash
# @file: main.sh
# @dir: /opt/podshift/cli/modules/secret
# @group: cli
# @description: Creates, lists, or removes a Podman secret. Runs as the podshift user; root uses `sudo -u podshift -i podshift secret`.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Creates, lists, or removes a Podman secret.
# @param: $@ - operation: --list, --unset <name>, or <name> [<value>].
# @exitcode: 0 on success, 1 on failure.
podshift-secret() {
    local name value

    # shellcheck source=../../../fn/utils/require-podshift.sh
    source /opt/podshift/fn/utils/require-podshift.sh --now || return 1
    # shellcheck source=../../../fn/rootless/load-rootless-conf.sh
    source /opt/podshift/fn/rootless/load-rootless-conf.sh --now || return 1

    case "${1:-}" in
        --list|-l)
            podman secret ls
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
            podman secret rm "${name}"
            return 0
            ;;
        *)
            name="${1:-}"
            value="${2:-}"
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
            printf '%s' "${value}" | podman secret create "${name}" -
            return 0
            ;;
    esac
}

podshift-secret "$@"
