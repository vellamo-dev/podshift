#!/usr/bin/env bash
# @file: is-valid-cli-name.sh
# @source-dir: src/test/cli/shared/fn/podshift
# @group: test
# @category: helper
# @description: Checks a PodShift CLI module or alias name.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that a name is lowercase letters and digits, starts with a letter, and has at most three parts joined by dashes.
# @arg: $1 - the name.
# @exitcode: 0 if valid, 1 otherwise.
is-valid-cli-name() {
    [[ "${1}" =~ ^[a-z][a-z0-9]*(-[a-z][a-z0-9]*){0,2}$ ]]
}
