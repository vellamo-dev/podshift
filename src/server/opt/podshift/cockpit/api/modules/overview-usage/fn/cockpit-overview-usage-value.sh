#!/usr/bin/env bash
# @file: cockpit-overview-usage-value.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-usage/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-usage/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Formats a usage count, or prints nothing when an argument is missing.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_61A40F05224C:-}" ]]; then
    DIR_61A40F05224C="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_61A40F05224C
fi

# @description: Formats a usage count, or prints nothing when an argument is missing.
# @arg: $1 - a total, or the in-use count when $2 is also given.
# @arg: $2 - optional total count.
# @stdout: a value such as 3 or 3 / 5, or nothing.
# @exitcode: 0 always.
cockpit-overview-usage-value() {
    local text
    # shellcheck source=../../../fn/overview/cockpit-overview-count.sh
    declare -F cockpit-overview-count >/dev/null || source "${DIR_61A40F05224C}/../../../fn/overview/cockpit-overview-count.sh"
    if text="$(cockpit-overview-count "$@")"; then
        printf '%s\n' "${text}"
    fi
}
