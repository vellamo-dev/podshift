#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/config
# @dest-dir: /opt/podshift/cli/modules/config
# @host-edit: no
# @group: cli
# @category: entry
# @description: Gets, lists, or sets PodShift runtime configuration.
# @run-as: any
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Gets, lists, or sets runtime configuration.
# @arg: $@ - (none) list, <key> get, or <key> <value> set.
# @exitcode: 0 on success, 1 on failure.
podshift-config() {
    local key value caller

    # shellcheck source=../../../fn/utils/is-admin.sh
    source /opt/podshift/fn/utils/is-admin.sh
    # shellcheck source=../../../fn/utils/is-podshift.sh
    source /opt/podshift/fn/utils/is-podshift.sh
    # shellcheck source=../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source /opt/podshift/fn/load-podshift-conf-main.sh
    load-podshift-conf-main

    if is-admin; then
        caller=root
    elif is-podshift; then
        caller=podshift
    else
        caller=other
    fi

    case "$#" in
        0)
            # List both config sources.
            cat "${PODSHIFT_TSV_CONF}" 2>/dev/null
            cat "${PODSHIFT_RUNTIME_CONF}" 2>/dev/null
            return 0
            ;;
        1)
            # Get a single key from either source.
            key="${1}"
            grep -h "^${key}=" "${PODSHIFT_TSV_CONF}" "${PODSHIFT_RUNTIME_CONF}" 2>/dev/null \
                || echo "${key} is not set"
            return 0
            ;;
        2)
            # Set a key: root may set system keys, the podshift user may set custom TSV_* keys.
            key="${1}"
            value="${2}"
            case "${caller}" in
                root)
                    if [[ ",${PODSHIFT_SYSTEM_CONFIG_KEYS}," != *",${key},"* ]]; then
                        echo "Invalid key '${key}'. Root may only set: ${PODSHIFT_SYSTEM_CONFIG_KEYS}" >&2
                        return 1
                    fi
                    # shellcheck source=../../../fn/utils/update-podshift-conf.sh
                    declare -F update-podshift-conf >/dev/null || source /opt/podshift/fn/utils/update-podshift-conf.sh
                    update-podshift-conf "${key}" "${value}"
                    ;;
                podshift)
                    if [[ "${key}" != TSV_* ]] || [[ ",${PODSHIFT_SYSTEM_CONFIG_KEYS}," == *",${key},"* ]]; then
                        echo "Invalid key '${key}'. Custom keys must start with TSV_ and not be reserved." >&2
                        return 1
                    fi
                    # shellcheck source=../../../fn/utils/update-tsv-conf.sh
                    declare -F update-tsv-conf >/dev/null || source /opt/podshift/fn/utils/update-tsv-conf.sh
                    update-tsv-conf "${key}" "${value}"
                    ;;
                *)
                    echo "Unauthorised. Root or podshift user required." >&2
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Usage: config [<key> [<value>]]" >&2
            return 1
            ;;
    esac
}

podshift-config "$@"
