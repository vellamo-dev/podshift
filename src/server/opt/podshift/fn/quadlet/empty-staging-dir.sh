#!/usr/bin/env bash
# @file: empty-staging-dir.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Empties the quadlet staging directory.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes everything inside the staging directory and keeps the directory itself.
# @details:
#   Removes everything inside the staging directory, hidden files too, and keeps the directory
#   itself. It refuses an empty path, the root, and anything that is not a directory.
# @arg: $1 - staging directory.
# @exitcode: 0 if the directory is now empty, 1 if it was refused or something could not be removed.
empty-staging-dir() {
    local staging_dir
    staging_dir="${1-}"
    [[ -n "${staging_dir}" && "${staging_dir}" != "/" && -d "${staging_dir}" ]] || return 1
    find "${staging_dir}" -mindepth 1 -maxdepth 1 -exec rm -rf -- {} + 2>/dev/null || return 1
    return 0
}
