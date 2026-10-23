#!/usr/bin/env bash
# @file: update-podshift-conf.sh
# @dir: /opt/podshift/fn/utils
# @group: utils
# @description: Updates or adds a key-value pair in the runtime configuration.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_FC0087D09FBB:-}" ]]; then
    DIR_FC0087D09FBB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_FC0087D09FBB
fi

# @description: Prints an error message to stderr (yellow).
# @param: $1 - error message
print-conf-error() {
    local message
    message="${1}"
    echo -e "\033[1;33mError:\033[0m ${message}" >&2
}

# @description: Prints a success message to stdout.
# @param: $1 - message
print-conf-ok() {
    local message
    message="${1}"
    echo -e "${message}"
}

# @description: Updates or adds a key-value pair in the runtime configuration.
# @param: $1 - configuration key
# @param: $2 - value
# @exitcode: 0 on success, 1 on non-admin, invalid input, or failure to write the config.
update-podshift-conf() {
    local key value conf_file quoted_value tmp_file
    # shellcheck source=./require-admin.sh
    source "${DIR_FC0087D09FBB}/require-admin.sh"
    require-admin || return 1
    # shellcheck source=../load-podshift-conf-main.sh
    source "${DIR_FC0087D09FBB}/../load-podshift-conf-main.sh" --now
    conf_file="${PODSHIFT_RUNTIME_CONF}"

    if [ "$#" -ne 2 ]; then
        print-conf-error "Invalid inputs. Usage: update-podshift-conf <key> <value>"
        return 1
    fi
    key="${1}"
    value="${2}"

    # Validate the key: uppercase letters, digits, and underscores only.
    if ! [[ "${key}" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
        print-conf-error "Invalid key '${key}'. Expected an uppercase name such as TSV_ENV."
        return 1
    fi

    # Reject control characters (e.g. newlines) that would corrupt the config file.
    if [[ "${value}" =~ [[:cntrl:]] ]]; then
        print-conf-error "Value must not contain control characters."
        return 1
    fi

    # Single-quote the value so the config file can be sourced back safely.
    quoted_value="'${value//\'/\'\\\'\'}'"

    # Ensure the config exists and is readable; re-seed from the template otherwise.
    if [ ! -r "${conf_file}" ]; then
        # shellcheck source=../../assets/tpl/runtime.conf
        sudo install -D -m 0644 "${PODSHIFT_RUNTIME_CONF_TEMPLATES}/runtime.conf" "${conf_file}" \
            || { print-conf-error "Failed to create ${conf_file} from template."; return 1; }
    fi

    # Rewrite the file: drop any existing KEY= line, then append KEY=<quoted value>.
    tmp_file="$(mktemp)"
    # grep -v exits 1 when the config had only that key (temp stays empty), which is fine.
    grep -v "^${key}=" "${conf_file}" > "${tmp_file}" 2>/dev/null || true
    printf '%s=%s\n' "${key}" "${quoted_value}" >> "${tmp_file}"
    sudo install -m 0644 "${tmp_file}" "${conf_file}" || {
        rm -f "${tmp_file}"
        print-conf-error "Failed to write ${conf_file}"
        return 1
    }
    rm -f "${tmp_file}"

    print-conf-ok "Updated ${key}."

    # Reload the updated runtime config into the current shell.
    # shellcheck source=../load-podshift-conf-runtime.sh
    source "${DIR_FC0087D09FBB}/../load-podshift-conf-runtime.sh" --now
}

# Executes only when called or sourced with --set
case "${1:-}" in
    --set) update-podshift-conf "$2" "$3" ;;
esac
