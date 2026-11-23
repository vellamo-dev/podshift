#!/usr/bin/env bash
# @file: cockpit-overview-usage-count-lines.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-usage/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-usage/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Counts unique non-empty lines on stdin.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Counts unique non-empty lines on stdin.
# @stdout: a non-negative integer.
# @exitcode: 0 always.
cockpit-overview-usage-count-lines() {
    awk 'NF { if (!seen[$0]++) n++ } END { print n+0 }'
}
