#!/usr/bin/env bash
# @file: read-tsv-config-rules.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints the secret rules for custom TSV_* keys from tsv-rules.conf.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_F8AFB038CAF9:-}" ]]; then
    DIR_F8AFB038CAF9="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_F8AFB038CAF9
fi

# @description: Prints the rule lines of PODSHIFT_TSV_RULES_CONF, without comments and empty lines.
# @details:
#   The path comes from main.conf. A missing setting or an unreadable file, or a file with no
#   word rule, is a failure, so a caller refuses to save instead of skipping the secret check.
# @stdout: the rule lines.
# @stderr: the reason when the rules cannot be read.
# @exitcode: 0 when the rules were printed, 1 otherwise.
read-tsv-config-rules() {
    local file rules
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_F8AFB038CAF9}/../load-podshift-conf-main.sh"
    load-podshift-conf-main
    file="${PODSHIFT_TSV_RULES_CONF:-}"
    if [[ -z "${file}" ]]; then
        echo "PODSHIFT_TSV_RULES_CONF is not set." >&2
        return 1
    fi
    if [[ ! -f "${file}" || ! -r "${file}" ]]; then
        echo "Cannot read the config rules file ${file}." >&2
        return 1
    fi
    rules="$(grep -v -e '^#' -e '^[[:space:]]*$' -- "${file}" 2>/dev/null)" || rules=""
    if [[ "${rules}" != *"word "* ]]; then
        echo "The config rules file ${file} has no word rules." >&2
        return 1
    fi
    printf '%s\n' "${rules}"
    return 0
}
