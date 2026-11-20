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
# @details:
#   The name and value must pass check-tsv-config-entry with the rules from tsv-rules.conf: the
#   TSV_ name form, no reserved TSV_NW or TSV_ENV prefix, no secret word in the name, a value that
#   is not empty and has no quotes, control characters or trailing backslash, and no known secret
#   format. When the rules cannot be read, nothing is saved.
#   The file is rebuilt with write-tsv-conf-lines: comments, blank lines and valid TSV_ lines are
#   kept in canonical form, other lines are dropped with a note, and the new KEY='value' is
#   appended. The values are then reloaded as data with load-podshift-conf-runtime.
# @arg: $1 - configuration key (TSV_* and not reserved).
# @arg: $2 - value.
# @stderr: the reason on failure, and a note when invalid lines were dropped.
# @exitcode: 0 on success, 1 on failure.
update-tsv-conf() {
    local key value conf_file tmp_file rules problem q esc
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

    # Custom keys and values follow the shared form and secret rules (tsv-rules.conf).
    # shellcheck source=./read-tsv-config-rules.sh
    declare -F read-tsv-config-rules >/dev/null || source "${DIR_7B3E5A9C1D6F}/read-tsv-config-rules.sh"
    rules="$(read-tsv-config-rules)" || return 1
    # shellcheck source=./check-tsv-config-entry.sh
    declare -F check-tsv-config-entry >/dev/null || source "${DIR_7B3E5A9C1D6F}/check-tsv-config-entry.sh"
    if ! problem="$(check-tsv-config-entry "${key}" "${value}" "${rules}")"; then
        echo "${problem#*$'\t'}" >&2
        return 1
    fi

    # Create from the template when missing.
    if [ ! -r "${conf_file}" ]; then
        install -D -m 0644 "${PODSHIFT_RUNTIME_CONF_TEMPLATES}/tsv.conf" "${conf_file}" \
            || { echo "Failed to create ${conf_file} from template." >&2; return 1; }
    fi

    # Rewrite the file from its valid lines without KEY, then append KEY='value' in the same
    # canonical form. Lines that are not comments, blank or TSV_NAME=value are dropped.
    # shellcheck source=./write-tsv-conf-lines.sh
    declare -F write-tsv-conf-lines >/dev/null || source "${DIR_7B3E5A9C1D6F}/write-tsv-conf-lines.sh"
    tmp_file="$(mktemp)"
    write-tsv-conf-lines "${conf_file}" "${key}" > "${tmp_file}" || {
        rm -f "${tmp_file}"
        echo "Failed to read ${conf_file}" >&2
        return 1
    }
    q="'"
    esc="'\\''"
    printf "%s='%s'\n" "${key}" "${value//"${q}"/${esc}}" >> "${tmp_file}"
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
