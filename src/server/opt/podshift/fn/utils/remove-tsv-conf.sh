#!/usr/bin/env bash
# @file: remove-tsv-conf.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Removes a custom TSV_* key from the podshift user's config.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_71D41F67B1E9:-}" ]]; then
    DIR_71D41F67B1E9="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_71D41F67B1E9
fi

# @description: Removes every KEY= line of one custom TSV_* key from tsv.conf.
# @details:
#   The name must pass check-tsv-config-name, so the reserved TSV_NW and TSV_ENV prefixes are
#   refused. The secret rules are not checked, so a key saved before them can still be removed.
#   A key with no KEY= line in the file is not set, and nothing is written. Running Quadlets are
#   not changed: their values were filled in when they were installed.
#   The rest of the file is rebuilt with write-tsv-conf-lines, so other lines that are not
#   comments, blank or TSV_NAME=value are dropped, with a note on stderr.
# @arg: $1 - configuration key (TSV_* and not reserved).
# @stderr: the reason on failure, and a note when invalid lines were dropped.
# @exitcode: 0 when the key was removed, 1 on failure, 2 when the key is not set.
remove-tsv-conf() {
    local key conf_file problem tmp_file
    # shellcheck source=./require-podshift.sh
    declare -F require-podshift >/dev/null || source "${DIR_71D41F67B1E9}/require-podshift.sh"
    require-podshift || return 1
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_71D41F67B1E9}/../load-podshift-conf-main.sh"
    load-podshift-conf-main
    conf_file="${PODSHIFT_TSV_CONF:-}"

    if [ "$#" -ne 1 ]; then
        echo "Invalid inputs. Usage: remove-tsv-conf <key>" >&2
        return 1
    fi
    key="${1}"

    # shellcheck source=./check-tsv-config-name.sh
    declare -F check-tsv-config-name >/dev/null || source "${DIR_71D41F67B1E9}/check-tsv-config-name.sh"
    if ! problem="$(check-tsv-config-name "${key}")"; then
        echo "${problem#*$'\t'}" >&2
        return 1
    fi

    if [[ -z "${conf_file}" || ! -f "${conf_file}" ]] || ! grep -q "^${key}=" "${conf_file}" 2>/dev/null; then
        echo "${key} is not set." >&2
        return 2
    fi

    # Rewrite the file from its valid lines without the KEY= lines. Lines that are not comments,
    # blank or TSV_NAME=value are dropped with a note.
    # shellcheck source=./write-tsv-conf-lines.sh
    declare -F write-tsv-conf-lines >/dev/null || source "${DIR_71D41F67B1E9}/write-tsv-conf-lines.sh"
    tmp_file="$(mktemp)"
    write-tsv-conf-lines "${conf_file}" "${key}" > "${tmp_file}" || {
        rm -f "${tmp_file}"
        echo "Failed to read ${conf_file}" >&2
        return 1
    }
    install -m 0644 "${tmp_file}" "${conf_file}" || {
        rm -f "${tmp_file}"
        echo "Failed to write ${conf_file}" >&2
        return 1
    }
    rm -f "${tmp_file}"
    return 0
}
