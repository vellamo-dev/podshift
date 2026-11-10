#!/usr/bin/env bash
# @file: format-duration.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Formats a duration in seconds as 6s or 2m 05s.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Formats seconds as 6s or 2m 05s.
# @arg: $1 - the seconds.
# @stdout: the formatted time.
format-duration() {
    local secs
    secs="${1}"
    if ((secs < 60)); then
        printf '%ss' "${secs}"
    else
        printf '%sm %02ds' "$((secs / 60))" "$((secs % 60))"
    fi
}
