#!/usr/bin/env bash
# @file: example-image-lines.sh
# @source-dir: src/test/cli/shared/fn/vm
# @group: test
# @category: helper
# @description: Reads the example image lists and files.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the usable lines of an image unmanaged.list: no blank lines, no comments.
# @arg: $1 - path of unmanaged.list.
# @stdout: one image reference per line.
# @exitcode: 0 if the file was read, 1 if it is missing.
example-image-lines() {
    local file line
    file="${1}"
    [[ -f "${file}" ]] || return 1
    while IFS= read -r line || [[ -n "${line}" ]]; do
        line="${line#"${line%%[![:space:]]*}"}"
        line="${line%"${line##*[![:space:]]}"}"
        [[ -n "${line}" && "${line}" != \#* ]] || continue
        printf '%s\n' "${line}"
    done < "${file}"
    return 0
}

# @description: Prints every image reference the example image folder uses.
# @details:
#   The Image= value of each example-*.image and example-*.container file, then each line of
#   unmanaged.list. Each reference is printed once, in that order.
# @arg: $1 - the example images folder.
# @stdout: one image reference per line.
# @exitcode: 0 always.
example-image-refs() {
    local dir file ref
    local -a seen
    dir="${1}"
    seen=()
    while IFS= read -r ref; do
        [[ -n "${ref}" ]] || continue
        [[ " ${seen[*]-} " == *" ${ref} "* ]] && continue
        seen+=("${ref}")
        printf '%s\n' "${ref}"
    done < <(
        for file in "${dir}"/example-*.image "${dir}"/example-*.container; do
            [[ -f "${file}" ]] || continue
            sed -n 's/^Image=//p' "${file}" | tail -n 1
        done
        example-image-lines "${dir}/unmanaged.list" 2>/dev/null
    )
    return 0
}
