#!/usr/bin/env bash
# @file: check-tsv-config-name.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Checks that a name can be a custom TSV_* key and is not reserved for PodShift.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the form of a custom TSV_* name and refuses the reserved TSV_NW and TSV_ENV prefixes.
# @details:
#   A valid name is TSV_, then a capital letter, then capital letters, digits or _ (the form
#   ^TSV_[A-Z][A-Z0-9_]*$). The characters are checked against literal lists, not letter ranges,
#   so the result does not depend on the locale. Any name that starts with TSV_NW or TSV_ENV is
#   reserved, so TSV_NW9, TSV_NWORDER and TSV_ENV2 are refused as well as TSV_NW1 and TSV_ENV.
#   On failure one line is printed: a code, a tab and a message. The codes are INVALID_NAME
#   and RESERVED_NAME.
# @arg: $1 - the name to check.
# @stdout: nothing when the name is valid, else CODE<tab>message.
# @exitcode: 0 if the name is valid and not reserved, 1 if not.
check-tsv-config-name() {
    local key rest first
    local -r upper='ABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local -r digits='0123456789'
    key="${1-}"
    rest="${key#TSV_}"
    first="${rest%"${rest#?}"}"
    if [[ "${key}" != TSV_* || -z "${rest}" || -n "${rest//[${upper}${digits}_]/}" || -n "${first//[${upper}]/}" ]]; then
        printf 'INVALID_NAME\tInvalid name '"'"'%s'"'"'. Use TSV_ followed by a capital letter, then capital letters, digits or _.\n' "${key}"
        return 1
    fi
    if [[ "${key}" == TSV_NW* || "${key}" == TSV_ENV* ]]; then
        printf 'RESERVED_NAME\tName '"'"'%s'"'"' is reserved. Names starting with TSV_NW or TSV_ENV are managed by PodShift.\n' "${key}"
        return 1
    fi
    return 0
}
