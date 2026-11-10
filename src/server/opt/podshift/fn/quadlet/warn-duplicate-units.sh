#!/usr/bin/env bash
# @file: warn-duplicate-units.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Logs a warning for every unit file of an item that has the same name as one already installed elsewhere.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_48B0C52D6741:-}" ]]; then
    DIR_48B0C52D6741="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_48B0C52D6741
fi

# @description: Logs a warning for each duplicate unit file and never blocks the install.
# @details:
#   It never touches a unit. The duplicates come from find-duplicate-units; a replace of the same
#   item or application gives none. Each one is one line with the tag podshift-qdl-install and the
#   level warn.
# @arg: $1 - staged quadlet file or bundle folder, named by its original name.
# @arg: $2 - directory where Podman installs quadlets.
# @exitcode: 0 always.
warn-duplicate-units() {
    local existing
    # shellcheck source=./find-duplicate-units.sh
    declare -F find-duplicate-units >/dev/null || source "${DIR_48B0C52D6741}/find-duplicate-units.sh"
    while IFS= read -r existing; do
        [[ -n "${existing}" ]] || continue
        logger -t podshift-qdl-install -p warn "duplicate unit name $(basename "${existing}"): already installed as ${existing}, both make the same systemd unit"
    done < <(find-duplicate-units "${1-}" "${2-}")
    return 0
}
