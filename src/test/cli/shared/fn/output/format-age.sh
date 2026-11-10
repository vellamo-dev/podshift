#!/usr/bin/env bash
# @file: format-age.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Formats an age in seconds as minutes under an hour, otherwise as whole hours.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints an age as minutes under an hour, for example 35m, otherwise as whole hours, for example 3h.
# @arg: $1 - the age in seconds.
# @stdout: the formatted age.
format-age() {
    if (( ${1} < 3600 )); then
        printf '%sm\n' "$(( ${1} / 60 ))"
        return 0
    fi
    printf '%sh\n' "$(( ${1} / 3600 ))"
}
