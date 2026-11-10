#!/usr/bin/env bash
# @file: health-render-group.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @description: Prints the title of one group of health checks.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the group title from groups.conf, or the group key when it has none.
# @arg: $1 - the group key, for example host.
# @arg: $2 - path to groups.conf, which maps group keys to titles.
# @stdout: an empty line and the group title.
# @exitcode: 0 always.
health-render-group() {
    local group groups_conf title
    group="${1}"
    groups_conf="${2}"
    title="$(grep -m1 "^${group}=" "${groups_conf}" 2>/dev/null)"
    title="${title#*=}"
    printf '\n    %s:\n' "${title:-${group}}"
    return 0
}
