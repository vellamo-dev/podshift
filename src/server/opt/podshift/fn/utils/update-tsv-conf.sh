#!/usr/bin/env bash
# @file: update-tsv-conf.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Updates or adds a custom TSV_* key-value pair in the podshift user's config.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_7B3E5A9C1D6F:-}" ]]; then
    DIR_7B3E5A9C1D6F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7B3E5A9C1D6F
fi

# @description: Updates or adds a custom TSV_* key-value pair.
# @arg: $1 - configuration key (TSV_* and not reserved).
# @arg: $2 - value.
# @exitcode: 0 on success, 1 on failure.
update-tsv-conf() {
    local key value conf_file quoted_value tmp_file
    # shellcheck source=./require-podshift.sh
    declare -F require-podshift >/dev/null || source "${DIR_7B3E5A9C1D6F}/require-podshift.sh"
    require-podshift || return 1
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_7B3E5A9C1D6F}/../load-podshift-conf-main.sh"
    load-podshift-conf-main
    conf_file="${PODSHIFT_TSV_CONF}"

    if [ "$#" -ne 2 ]; then
        echo "Invalid inputs. Usage: update-tsv-conf <key> <value>" >&2
        return 1
    fi
    key="${1}"
    value="${2}"

    # Custom keys must start with TSV_ and must not be reserved system keys.
    if [[ "${key}" != TSV_* ]] || [[ ",${PODSHIFT_SYSTEM_CONFIG_KEYS}," == *",${key},"* ]]; then
        echo "Invalid key '${key}'. Custom keys must start with TSV_ and not be reserved." >&2
        return 1
    fi

    # Reject control characters (e.g. newlines) that would corrupt the config file.
    if [[ "${value}" =~ [[:cntrl:]] ]]; then
        echo "Value must not contain control characters." >&2
        return 1
    fi

    # Single-quote the value so the config file can be sourced back safely.
    quoted_value="'${value//\'/\'\\\'\'}'"

    # Create from the template when missing.
    if [ ! -r "${conf_file}" ]; then
        install -D -m 0644 "${PODSHIFT_RUNTIME_CONF_TEMPLATES}/tsv.conf" "${conf_file}" \
            || { echo "Failed to create ${conf_file} from template." >&2; return 1; }
    fi

    # Rewrite the file: drop any existing KEY= line, then append KEY=<quoted value>.
    tmp_file="$(mktemp)"
    grep -v "^${key}=" "${conf_file}" > "${tmp_file}" 2>/dev/null || true
    printf '%s=%s\n' "${key}" "${quoted_value}" >> "${tmp_file}"
    install -m 0644 "${tmp_file}" "${conf_file}" || {
        rm -f "${tmp_file}"
        echo "Failed to write ${conf_file}" >&2
        return 1
    }
    rm -f "${tmp_file}"

    # Reload the updated runtime configuration into the current shell.
    # shellcheck source=../load-podshift-conf-runtime.sh
    declare -F load-podshift-conf-runtime >/dev/null || source "${DIR_7B3E5A9C1D6F}/../load-podshift-conf-runtime.sh"
    load-podshift-conf-runtime
}
