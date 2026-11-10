#!/usr/bin/env bash
# @file: fill-staged-item.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Fills the ${TSV_NAME} variables in a staged quadlet file or bundle folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_8EAC39C99439:-}" ]]; then
    DIR_8EAC39C99439="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_8EAC39C99439
fi

# @description: Fills the TSV variables of a staged file or folder and checks that none are left.
# @details:
#   Runs fill-tsv-vars on the file, or on every file of the folder, then checks each file again
#   with is-tsv-var-used. The TSV_ values must already be loaded in the shell. A file that still
#   has a ${TSV_NAME} is a failure: the names (never the values) are logged.
# @arg: $1 - staged quadlet file or bundle folder.
# @exitcode: 0 if every variable was filled, 1 if a file could not be filled or a variable is left.
fill-staged-item() {
    local item file names left
    local -a files
    item="${1}"

    # shellcheck source=./fill-tsv-vars.sh
    declare -F fill-tsv-vars >/dev/null || source "${DIR_8EAC39C99439}/fill-tsv-vars.sh"
    # shellcheck source=./is-tsv-var-used.sh
    declare -F is-tsv-var-used >/dev/null || source "${DIR_8EAC39C99439}/is-tsv-var-used.sh"
    # shellcheck source=./list-tsv-vars.sh
    declare -F list-tsv-vars >/dev/null || source "${DIR_8EAC39C99439}/list-tsv-vars.sh"

    mapfile -t files < <(find "${item}" -type f | LC_ALL=C sort)

    for file in "${files[@]}"; do
        if ! fill-tsv-vars "${file}"; then
            logger -t podshift-qdl-install -p err "failed to fill variables in $(basename "${file}")"
            return 1
        fi
    done

    left=0
    for file in "${files[@]}"; do
        if is-tsv-var-used "${file}"; then
            names="$(list-tsv-vars "${file}" | tr '\n' ' ')"
            logger -t podshift-qdl-install -p err "$(basename "${file}"): variables without a value: ${names% }"
            left=1
        fi
    done
    return "${left}"
}
