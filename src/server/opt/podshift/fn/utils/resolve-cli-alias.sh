#!/usr/bin/env bash
# @file: resolve-cli-alias.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Resolves a short CLI command name, such as nw, to its long name from aliases.conf.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the long name for a short name in the aliases file, or the name itself when it is not an alias.
# @details:
#   Both the name and the result must be safe command names (lower case words joined by up to two
#   hyphens), so a name can never point outside the module or help directories. The caller passes
#   the aliases file, so the dispatcher and the help renderer each use the path they already know.
# @arg: $1 - command name, long or short.
# @arg: $2 - path of aliases.conf.
# @stdout: the long name, or $1 unchanged when it is not an alias.
# @exitcode: 0 if a safe name was printed, 1 if the name or its long name is not safe (nothing printed).
resolve-cli-alias() {
    local name long
    name="${1}"
    [[ "${name}" =~ ^[a-z][a-z0-9]*(-[a-z][a-z0-9]*){0,2}$ ]] || return 1
    long="$(grep -m1 "^${name}=" "${2}" 2>/dev/null)"
    [[ -n "${long}" ]] && name="${long#*=}"
    [[ "${name}" =~ ^[a-z][a-z0-9]*(-[a-z][a-z0-9]*){0,2}$ ]] || return 1
    echo "${name}"
}
