#!/usr/bin/env bash
# @file: build-or-reuse-image.sh
# @source-dir: src/test/cli/shared/fn/image
# @group: test
# @category: helper
# @description: Builds a test image, or reuses it if it is new enough.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reuses the image if reuse is on and it is new enough, otherwise builds it.
# @details:
#   A build uses the containerfile, with the Fedora version as a build argument.
# @arg: $1 - the run folder.
# @arg: $2 - the log name.
# @arg: $3 - the image with its tag.
# @arg: $4 - the containerfile name, found with find-containerfile.
# @arg: $5 - reuse the image (true or false).
# @arg: $6 - the oldest image that may be reused, in hours.
# @arg: $7 - build without the build cache (true or false).
# @stdout: NOTE with what happened and why, for example "reused, 35m old" or "built, no image", and the build output.
# @exitcode: 0 if the image is ready, 1 if the containerfile is missing or the build failed.
build-or-reuse-image() {
    local run_dir log img file reuse max_hours no_cache path age shown reason flags note
    run_dir="${1}"
    log="${2}"
    img="${3}"
    file="${4}"
    reuse="${5}"
    max_hours="${6}"
    no_cache="${7}"
    age="$(image-age "${img}")"
    shown=""
    [[ -z "${age}" ]] || shown="$(format-age "${age}")"
    reason=""
    [[ "${reuse}" == "true" ]] || reason="reuse off"
    [[ -n "${reason}" || -n "${age}" ]] || reason="no image"
    [[ -n "${reason}" || "${age}" -lt $(( max_hours * 3600 )) ]] || reason="${shown} old, max ${max_hours}h"
    if [[ -z "${reason}" ]]; then
        write-log "${run_dir}" "${log}" "Image ${img}: reused, ${shown} old, max ${max_hours}h"
        echo "NOTE: reused, ${shown} old"
        return 0
    fi
    if ! path="$(find-containerfile "${file}")"; then
        write-log "${run_dir}" "${log}" "Image ${img}: containerfile ${file} not found"
        echo "The containerfile ${file} was not found"
        return 1
    fi
    flags=()
    [[ "${no_cache}" != "true" ]] || flags=(--no-cache)
    if ! container-cli build "${flags[@]}" --build-arg "FEDORA_VERSION=${TST_FEDORA_VERSION}" -t "${img}" -f "${path}" "${path%/*}"; then
        write-log "${run_dir}" "${log}" "Image ${img}: build failed (${reason})"
        echo "The image ${img} could not be built"
        return 1
    fi
    note="built, ${reason}${flags[*]:+, no cache}"
    write-log "${run_dir}" "${log}" "Image ${img}: ${note}, from ${path}"
    echo "NOTE: ${note}"
}
