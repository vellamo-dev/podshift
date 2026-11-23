#!/usr/bin/env bash
# @file: update-podshift-conf.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Updates or adds a key-value pair in the runtime configuration.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_FC0087D09FBB:-}" ]]; then
    DIR_FC0087D09FBB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_FC0087D09FBB
fi

# @description: Updates or adds a key-value pair in the runtime configuration.
# @details:
#   Errors go to stderr, with a yellow "Error:" only when stderr is a terminal. The file is written
#   with install, through sudo only when the caller is not root (an admin with sudo rights).
# @arg: $1 - configuration key
# @arg: $2 - value
# @stdout: "Updated <key>." on success.
# @stderr: the error, when the update fails.
# @exitcode: 0 on success, 1 on non-admin, invalid input, or failure to write the config.
update-podshift-conf() {
    local key value conf_file quoted_value tmp_file error
    local -a as_root
    # shellcheck source=./require-admin.sh
    declare -F require-admin >/dev/null || source "${DIR_FC0087D09FBB}/require-admin.sh"
    require-admin || return 1
    # shellcheck source=./is-interactive-output.sh
    declare -F is-interactive-output >/dev/null || source "${DIR_FC0087D09FBB}/is-interactive-output.sh"
    error="Error:"
    if is-interactive-output 2; then
        error=$'\033[1;33mError:\033[0m'
    fi
    as_root=()
    [[ "${EUID}" -eq 0 ]] || as_root=(sudo)
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_FC0087D09FBB}/../load-podshift-conf-main.sh"
    load-podshift-conf-main
    conf_file="${PODSHIFT_RUNTIME_CONF}"

    if [ "$#" -ne 2 ]; then
        printf '%s %s\n' "${error}" "Invalid inputs. Usage: update-podshift-conf <key> <value>" >&2
        return 1
    fi
    key="${1}"
    value="${2}"

    # Validate the key: uppercase letters, digits, and underscores only.
    if ! [[ "${key}" =~ ^[A-Z][A-Z0-9_]*$ ]]; then
        printf '%s %s\n' "${error}" "Invalid key '${key}'. Expected an uppercase name such as TSV_ENV." >&2
        return 1
    fi

    # Reject control characters (e.g. newlines) that would corrupt the config file.
    if [[ "${value}" =~ [[:cntrl:]] ]]; then
        printf '%s %s\n' "${error}" "Value must not contain control characters." >&2
        return 1
    fi

    # Single-quote the value so the config file can be sourced back safely.
    quoted_value="'${value//\'/\'\\\'\'}'"

    # Ensure the config exists and is readable; re-seed from the template otherwise.
    if [ ! -r "${conf_file}" ]; then
        # shellcheck source=../../assets/tpl/runtime.conf
        "${as_root[@]}" install -D -m 0644 "${PODSHIFT_RUNTIME_CONF_TEMPLATES}/runtime.conf" "${conf_file}" \
            || { printf '%s %s\n' "${error}" "Failed to create ${conf_file} from template." >&2; return 1; }
    fi

    # Rewrite the file: drop any existing KEY= line, then append KEY=<quoted value>.
    tmp_file="$(mktemp)" || {
        printf '%s %s\n' "${error}" "Failed to create a temp file for ${conf_file}" >&2
        return 1
    }
    # grep -v exits 1 when the config had only that key (temp stays empty), which is fine.
    grep -v "^${key}=" "${conf_file}" > "${tmp_file}" 2>/dev/null || true
    printf '%s=%s\n' "${key}" "${quoted_value}" >> "${tmp_file}"
    "${as_root[@]}" install -m 0644 "${tmp_file}" "${conf_file}" || {
        rm -f "${tmp_file}"
        printf '%s %s\n' "${error}" "Failed to write ${conf_file}" >&2
        return 1
    }
    rm -f "${tmp_file}"

    printf 'Updated %s.\n' "${key}"

    # Reload the updated runtime config into the current shell.
    # shellcheck source=../load-podshift-conf-runtime.sh
    declare -F load-podshift-conf-runtime >/dev/null || source "${DIR_FC0087D09FBB}/../load-podshift-conf-runtime.sh"
    load-podshift-conf-runtime
}
