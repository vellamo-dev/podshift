#!/usr/bin/env bash
# @file: get-original-name.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Gives the original name of a quadlet item, without the collision suffix.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Removes a trailing all-digits collision suffix from the last part of the path.
# @details:
#   Takes the last part of the path and removes a trailing all-digits suffix, the collision rename
#   added by date +%s%N (web.container.1761612345123456789 becomes web.container,
#   app.qdl-bundle.1761612345123456789 becomes app.qdl-bundle). A name without that suffix is
#   printed as it is.
# @arg: $1 - file or folder name, or path.
# @stdout: the original name.
# @exitcode: 0 always.
get-original-name() {
    local name
    name="$(basename -- "${1-}")"
    [[ "${name}" =~ ^(.+)\.[0-9]+$ ]] && name="${BASH_REMATCH[1]}"
    printf '%s\n' "${name}"
    return 0
}
