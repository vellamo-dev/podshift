#!/usr/bin/env bash
# @file: deploy-files.sh
# @source-dir: src/deployment/fn
# @group: deployment
# @category: step
# @step: PS-DP-FLS
# @description: Deploys non-script files from the source tree into the RPM build root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Only the file types listed in the allowlist (allowed-extensions.conf) are
# copied. Shell scripts are handled separately by deploy-sh-scripts.sh.

set -euo pipefail

if [[ -z "${DIR_296C98A79FFF:-}" ]]; then
    DIR_296C98A79FFF="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_296C98A79FFF
fi

# @description: Deploys non-script files into the build root, filtered by the allowlist.
# @arg: $1 - build root directory.
# @arg: $2 - source tree directory.
# @exitcode: 1 if the allowlist is missing or empty.
deploy-files() {
    local -r step_tag="PS-DP-FLS"
    local path_files path_build conf_file line f base ext
    local -A allowed_ext allowed_exact
    # Source-only documentation: kept in the repo, never shipped in the RPM.
    local -a skip_paths=(
        "usr/bin/readme.md"
        "usr/sbin/readme.md"
    )

    conf_file="${DIR_296C98A79FFF}/../allowed-extensions.conf"
    path_build=$(realpath "$1")
    path_files=$(realpath "$2")
    # shellcheck source=./utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_296C98A79FFF}/utils/print-step.sh"
    print-step-header "${step_tag}" "Deploying files..."

    if [[ ! -f "${conf_file}" ]]; then
        print-step-warn "allowlist file not found: ${conf_file}"
        exit 1
    fi

    # Parse the allowlist into extension and exact-name sets.
    while IFS= read -r line; do
        line="${line%%#*}"            # strip inline comments
        line="${line//[[:space:]]/}"  # drop all whitespace
        [[ -n "${line}" ]] || continue
        if [[ "${line}" == .* ]]; then
            allowed_ext["${line}"]=1
        else
            allowed_exact["${line}"]=1
        fi
    done < "${conf_file}"

    if (( ${#allowed_ext[@]} == 0 && ${#allowed_exact[@]} == 0 )); then
        print-step-warn "allowlist file is empty: ${conf_file}"
        exit 1
    fi

    cd "${path_files}"

    while IFS= read -r f; do
        base="$(basename "${f}")"
        case "${base}" in
            .*) continue ;;   # skip hidden files (e.g. .DS_Store)
        esac
        for skip in "${skip_paths[@]}"; do
            [[ "${f#./}" == "${skip}" ]] && continue 2
        done
        if [[ "${base}" == *.* ]]; then
            ext=".${base##*.}"
            [[ -n "${allowed_ext[${ext}]:-}" ]] || continue
        else
            [[ -n "${allowed_exact[${base}]:-}" ]] || continue
        fi
        install -Dm644 "${f}" "${path_build}/${f#./}"
    done < <(find . -type f)
    print-step-ok
}
