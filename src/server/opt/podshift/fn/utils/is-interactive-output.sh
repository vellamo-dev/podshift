#!/usr/bin/env bash
# @file: is-interactive-output.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Tells whether output goes to a person at a terminal, so colors and a spinner can be used.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Output is plain when it is not a terminal, or when PODSHIFT_PLAIN=true, NO_COLOR, CI or TERM=dumb is set.
# @arg: $1 - optional file descriptor to test, 1 (standard output, the default) or 2 (standard error).
# @exitcode: 0 if interactive, 1 if plain.
is-interactive-output() {
    local fd
    fd="${1:-1}"
    [[ "${PODSHIFT_PLAIN:-}" == "true" ]] && return 1
    [[ -n "${NO_COLOR:-}" || -n "${CI:-}" || "${TERM:-}" == "dumb" ]] && return 1
    [[ -t "${fd}" ]]
}
