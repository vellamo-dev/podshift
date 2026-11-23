#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/server/opt/podshift/cli/modules/config
# @dest-dir: /opt/podshift/cli/modules/config
# @host-edit: no
# @group: cli
# @category: entry
# @description: Gets, lists, sets, or removes PodShift runtime configuration.
# @run-as: any
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_6D9F9C6E360C:-}" ]]; then
    DIR_6D9F9C6E360C="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_6D9F9C6E360C
fi

# @description: Gets, lists, sets, or removes runtime configuration.
# @details:
#   Root may set the system keys in PODSHIFT_SYSTEM_CONFIG_KEYS. The podshift user may set and
#   remove custom TSV_* keys; update-tsv-conf and remove-tsv-conf check the name, the reserved
#   TSV_NW and TSV_ENV prefixes and the secret rules.
#   TSV_ENV is refused for set and --unset, for every caller, root included: it is set with
#   podshift env --set, which checks the tag and calls update-podshift-conf directly.
# @arg: $@ - (none) list, <key> get, <key> <value> set, or --unset <key> remove.
# @stderr: the reason on failure.
# @exitcode: 0 on success, 1 on failure.
podshift-config() {
    local key value caller rc found

    # shellcheck source=../../../fn/utils/is-admin.sh
    declare -F is-admin >/dev/null || source "${DIR_6D9F9C6E360C}/../../../fn/utils/is-admin.sh"
    # shellcheck source=../../../fn/utils/is-podshift.sh
    declare -F is-podshift >/dev/null || source "${DIR_6D9F9C6E360C}/../../../fn/utils/is-podshift.sh"
    # shellcheck source=../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_6D9F9C6E360C}/../../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main

    if is-admin; then
        caller=root
    elif is-podshift; then
        caller=podshift
    else
        caller=other
    fi

    if [[ "${1:-}" == "--unset" ]]; then
        # Remove a custom TSV_* key: only the podshift user, only from tsv.conf.
        if [[ "$#" -ne 2 ]]; then
            echo "Usage: config --unset <key>" >&2
            return 1
        fi
        key="${2}"
        if [[ "${key}" == "TSV_ENV" ]]; then
            echo "TSV_ENV is set with: sudo podshift env --set <tag>" >&2
            return 1
        fi
        if [[ "${caller}" != "podshift" ]]; then
            echo "Unauthorised. Only the podshift user may remove custom TSV_* keys." >&2
            return 1
        fi
        # shellcheck source=../../../fn/utils/remove-tsv-conf.sh
        declare -F remove-tsv-conf >/dev/null || source "${DIR_6D9F9C6E360C}/../../../fn/utils/remove-tsv-conf.sh"
        remove-tsv-conf "${key}" && rc=0 || rc=$?
        if [[ "${rc}" -ne 0 ]]; then
            return 1
        fi
        echo "Removed ${key}."
        return 0
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
            # The key goes into a grep pattern, so only a plain name is looked up.
            if [[ ! "${key}" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
                echo "Invalid key '${key}'. A key has only letters, digits and underscores." >&2
                return 1
            fi
            # grep exits 2 when one of the files is missing, even with a match, so the output decides.
            found="$(grep -h "^${key}=" "${PODSHIFT_TSV_CONF}" "${PODSHIFT_RUNTIME_CONF}" 2>/dev/null)" || true
            if [[ -n "${found}" ]]; then
                printf '%s\n' "${found}"
            else
                echo "${key} is not set"
            fi
            return 0
            ;;
        2)
            # Set a key: root may set system keys, the podshift user may set custom TSV_* keys.
            key="${1}"
            value="${2}"
            # TSV_ENV goes through podshift env --set, which checks the tag.
            if [[ "${key}" == "TSV_ENV" ]]; then
                echo "TSV_ENV is set with: sudo podshift env --set <tag>" >&2
                return 1
            fi
            case "${caller}" in
                root)
                    if [[ ",${PODSHIFT_SYSTEM_CONFIG_KEYS}," != *",${key},"* ]]; then
                        echo "Invalid key '${key}'. Root may only set: ${PODSHIFT_SYSTEM_CONFIG_KEYS}" >&2
                        return 1
                    fi
                    # shellcheck source=../../../fn/utils/update-podshift-conf.sh
                    declare -F update-podshift-conf >/dev/null || source "${DIR_6D9F9C6E360C}/../../../fn/utils/update-podshift-conf.sh"
                    update-podshift-conf "${key}" "${value}"
                    ;;
                podshift)
                    # update-tsv-conf checks the name, the reserved prefixes and the secret rules.
                    # shellcheck source=../../../fn/utils/update-tsv-conf.sh
                    declare -F update-tsv-conf >/dev/null || source "${DIR_6D9F9C6E360C}/../../../fn/utils/update-tsv-conf.sh"
                    update-tsv-conf "${key}" "${value}" || return 1
                    echo "Updated ${key}."
                    ;;
                *)
                    echo "Unauthorised. Root or podshift user required." >&2
                    return 1
                    ;;
            esac
            ;;
        *)
            echo "Usage: config [<key> [<value>]] | config --unset <key>" >&2
            return 1
            ;;
    esac
}

if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    podshift-config "$@"
fi
