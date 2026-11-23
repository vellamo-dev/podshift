#!/usr/bin/env bash
# @file: cockpit-overview-usage-quadlet-counts.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-usage/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-usage/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Counts installed Quadlet files of every known type.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_D8F9E78D7367:-}" ]]; then
    DIR_D8F9E78D7367="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_D8F9E78D7367
fi

# @description: Counts installed Quadlet files of every known type.
# @details:
#   Looks at regular files in the installed-quadlet directory (maxdepth 1). The value is
#   the number of installed Quadlet files of every known type.
# @arg: $1 - all to count every quadlet type.
# @stdout: a value such as 3 or 0, or nothing when the directory cannot be read.
# @exitcode: 0 always.
cockpit-overview-usage-quadlet-counts() {
    local mode dir file all name
    # shellcheck source=./cockpit-overview-usage-quadlet-dir.sh
    declare -F cockpit-overview-usage-quadlet-dir >/dev/null || source "${DIR_D8F9E78D7367}/cockpit-overview-usage-quadlet-dir.sh"
    # shellcheck source=./cockpit-overview-usage-value.sh
    declare -F cockpit-overview-usage-value >/dev/null || source "${DIR_D8F9E78D7367}/cockpit-overview-usage-value.sh"
    mode="${1-}"
    [[ "${mode}" == "all" ]] || return 0
    dir="$(cockpit-overview-usage-quadlet-dir)"
    [[ -n "${dir}" && -d "${dir}" ]] || return 0
    all=0
    # -P: do not follow a symlink when naming the starting directory.
    while IFS= read -r file; do
        [[ -n "${file}" ]] || continue
        name="${file##*/}"
        case "${name}" in
            *.container|*.kube|*.pod|*.volume|*.network|*.image|*.build)
                all=$((all + 1))
                ;;
        esac
    done < <(find -P "${dir}" -maxdepth 1 -type f ! -name '.*' \( \
        -name '*.container' -o -name '*.kube' -o -name '*.pod' -o \
        -name '*.volume' -o -name '*.network' -o -name '*.image' -o -name '*.build' \
        \) 2>/dev/null | LC_ALL=C sort)
    cockpit-overview-usage-value "${all}"
}
