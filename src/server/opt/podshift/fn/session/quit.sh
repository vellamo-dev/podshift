#!/usr/bin/env bash
# @file: quit.sh
# @source-dir: src/server/opt/podshift/fn/session
# @dest-dir: /opt/podshift/fn/session
# @host-edit: no
# @group: session
# @category: helper
# @description: Defines quit, which clears the bash command history and exits the shell.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_EF5844B12FE2:-}" ]]; then
    DIR_EF5844B12FE2="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_EF5844B12FE2
fi

# @description: Clears the bash command history and exits the shell.
quit() {
    # shellcheck source=./hcl.sh
    declare -F hcl >/dev/null || source "${DIR_EF5844B12FE2}/hcl.sh"
    hcl
    exit
}
