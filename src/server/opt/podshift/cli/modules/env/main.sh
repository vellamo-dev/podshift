#!/usr/bin/env bash
# @file: main.sh
# @dir: /opt/podshift/cli/modules/env
# @group: cli
# @description: Prints, lists, or sets the PodShift environment tag.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints, lists, or sets the PodShift environment tag (TSV_ENV).
# @param: $1 - optional --set operation; $2 - optional tag value.
# @exitcode: 0 on success, 1 on failure.
podshift-env() {
    local value

    # shellcheck source=../../../fn/load-podshift-conf-main.sh
    source /opt/podshift/fn/load-podshift-conf-main.sh --now || return 1
    # shellcheck source=../../../fn/load-podshift-conf-runtime.sh
    source /opt/podshift/fn/load-podshift-conf-runtime.sh --now || return 1

    case "${1:-}" in
        --set)
            if [[ -z "${2:-}" ]]; then
                echo "${PODSHIFT_ENV_TYPES}" | tr ',' '\n'
                return 0
            fi
            value="${2}"
            if ! [[ "${value}" =~ ^[a-zA-Z0-9_][a-zA-Z0-9._-]{0,127}$ ]]; then
                echo "Invalid tag '${value}'. Use only a-z, A-Z, 0-9, _, ., -" >&2
                return 1
            fi
            # shellcheck source=../../../fn/utils/update-podshift-conf.sh
            source /opt/podshift/fn/utils/update-podshift-conf.sh --set TSV_ENV "${value}"
            ;;
        *)
            echo "TSV_ENV=${TSV_ENV:-}"
            ;;
    esac
}

podshift-env "$@"
