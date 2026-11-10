#!/usr/bin/env bash
# @file: find-containerfile.sh
# @source-dir: src/test/cli/os-specific/mac/fn
# @group: test
# @category: helper
# @description: Finds a containerfile, looking in the mac folder first.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the path of a containerfile.
# @details:
#   Looks in os-specific/mac/containerfiles/ first, then in shared/containerfiles/.
# @arg: $1 - the file name, for example Dockerfile.rpm-builder.
# @stdout: the path, relative to the repo root.
# @exitcode: 0 if found, 1 if not.
find-containerfile() {
    local dir
    for dir in "src/test/cli/os-specific/mac/containerfiles" "src/test/cli/shared/containerfiles"; do
        if [[ -f "${dir}/${1}" ]]; then
            printf '%s\n' "${dir}/${1}"
            return 0
        fi
    done
    return 1
}
