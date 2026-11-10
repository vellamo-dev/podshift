#!/usr/bin/env bash
# @file: podshift-command-list.sh
# @source-dir: src/test/cli/shared/fn/podshift
# @group: test
# @category: helper
# @description: Lists the PodShift commands: CLI modules and shortcuts.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Lists every CLI module and shortcut in the PodShift source, with the file that defines it.
# @arg: $1 - the PodShift source folder, for example src/server/opt/podshift.
# @stdout: one name<TAB>file line per command, modules first, then root and rootless shortcuts.
podshift-command-list() {
    local base file
    base="${1}"
    for file in "${base}"/cli/modules/*/main.sh; do
        [[ -f "${file}" ]] && printf '%s\t%s\n' "$(basename -- "$(dirname -- "${file}")")" "${file}"
    done
    for file in "${base}"/shortcuts/root/*.sh "${base}"/shortcuts/rootless/*.sh; do
        [[ -f "${file}" ]] && printf '%s\t%s\n' "$(basename -- "${file}" .sh)" "${file}"
    done
}
