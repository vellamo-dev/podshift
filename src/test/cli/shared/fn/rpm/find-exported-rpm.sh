#!/usr/bin/env bash
# @file: find-exported-rpm.sh
# @source-dir: src/test/cli/shared/fn/rpm
# @group: test
# @category: helper
# @description: Finds the exported RPM package.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the absolute path of the one binary RPM in the share folder.
# @details:
#   Source RPMs are ignored.
# @arg: $1 - the share folder, absolute or relative to the repo root.
# @stdout: the path.
# @stderr: the problem, if there is no RPM or more than one.
# @exitcode: 0 if exactly one was found, 1 otherwise.
find-exported-rpm() {
    local dir files
    dir="${1}"
    [[ "${dir}" == /* ]] || dir="${PWD}/${dir}"
    files=()
    while IFS= read -r file; do
        files+=("${file}")
    done < <(find "${dir}" -maxdepth 1 -name '*.rpm' ! -name '*.src.rpm' 2>/dev/null | sort)
    if (( ${#files[@]} != 1 )); then
        echo "Expected one RPM in ${1}, found ${#files[@]}" >&2
        return 1
    fi
    printf '%s\n' "${files[0]}"
}
