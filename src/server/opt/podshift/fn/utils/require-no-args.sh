#!/usr/bin/env bash
# @file: require-no-args.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Stops a command that takes no arguments, such as a shortcut, when it is given one.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 if no argument follows the name; otherwise prints a note and returns 1.
# @arg: $1 - the command name, as in podshift --help <name>.
# @arg: $@ - the arguments the command was given, after the name.
# @stderr: the note when there is an argument.
# @exitcode: 0 if there is no argument, 1 otherwise.
require-no-args() {
    local name
    name="${1}"
    shift
    (( $# == 0 )) && return 0
    echo "${name} takes no arguments. See 'podshift --help ${name}'." >&2
    return 1
}
