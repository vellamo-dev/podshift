#!/usr/bin/env bash
# @file: check-release-version.sh
# @source-dir: src/test/cli/shared/fn/release
# @group: test
# @category: helper
# @description: Checks that Copr has built the version that is on the release branch on GitHub.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Compares the spec Version on the release branch with the newest successful Copr build in a chroot.
# @details:
#   Only Version decides the result. A different Release is shown but does not fail. Copr behind
#   GitHub means the build is missing, still running or failed. Copr ahead of GitHub is not expected.
#   Uses read-stable-version, find-copr-build and is-version-at-least.
# @arg: $1 - the package, podshift or cockpit-podshift.
# @arg: $2 - the chroot, for example fedora-45-x86_64.
# @arg: $3 - the run folder, or empty for no log.
# @stdout: the reason first when it fails, then NOTE with both versions and DETAIL lines with the sources.
# @exitcode: 0 when the versions match, 1 on a network error, 2 when Copr is behind or ahead.
check-release-version() {
    local package chroot run_dir stable copr version release url latest_id latest_state latest_version ok_id ok_version copr_version copr_release build_url reason
    package="${1}"
    chroot="${2}"
    run_dir="${3:-}"
    if ! stable="$(read-stable-version "${package}" 2>&1)"; then
        echo "${stable}"
        return 1
    fi
    IFS=$'\t' read -r version release url <<<"${stable}"
    if ! copr="$(find-copr-build "${package}" "${chroot}" 2>&1)"; then
        echo "${copr}"
        return 1
    fi
    IFS=$'\t' read -r latest_id latest_state latest_version ok_id ok_version <<<"${copr}"
    copr_version="${ok_version%-*}"
    copr_release="${ok_version##*-}"
    build_url="${TST_COPR_WEB}/${TST_COPR_OWNER}/${package}/build/${ok_id}/"
    reason=""
    if [[ "${ok_id}" == "-" ]]; then
        reason="No successful Copr build of ${package} for ${chroot}"
    elif [[ "${copr_version}" == "${version}" ]]; then
        reason=""
    elif is-version-at-least "${copr_version}" "${version}"; then
        reason="Copr is ahead of ${TST_RELEASE_BRANCH}: Copr has ${copr_version}, ${TST_RELEASE_BRANCH} has ${version}. Check the ${TST_RELEASE_BRANCH} branch"
    elif [[ "${latest_version%-*}" == "${version}" ]]; then
        reason="Copr is behind ${TST_RELEASE_BRANCH}: build ${latest_id} of ${version} in ${chroot} is not done: ${latest_state}"
    else
        reason="Copr is behind ${TST_RELEASE_BRANCH}: no Copr build of ${version} yet, newest successful is ${copr_version}"
    fi
    if [[ -n "${run_dir}" ]] && declare -F write-log >/dev/null; then
        write-log "${run_dir}" release-version-check "${package}: ${TST_RELEASE_BRANCH} ${version}-${release}, Copr ${ok_version} (build ${ok_id}, ${chroot}), newest build ${latest_id} ${latest_state}${reason:+, FAIL: ${reason}}"
    fi
    [[ -z "${reason}" ]] || echo "${reason}"
    echo "NOTE: ${TST_RELEASE_BRANCH} ${version}, Copr ${ok_version/#-/none}"
    echo "DETAIL: GitHub ${TST_RELEASE_BRANCH}: ${version}-${release} (${url})"
    if [[ "${ok_id}" != "-" ]]; then
        echo "DETAIL: Copr ${chroot}: ${ok_version}, build ${ok_id} succeeded (${build_url})"
    fi
    if [[ "${latest_id}" != "-" && "${latest_id}" != "${ok_id}" ]]; then
        echo "DETAIL: Newest Copr build in ${chroot}: ${latest_version}, build ${latest_id} ${latest_state}"
    fi
    if [[ -z "${reason}" && "${copr_release}" != "${release}" ]]; then
        echo "DETAIL: Release differs: ${TST_RELEASE_BRANCH} ${release}, Copr ${copr_release}"
    fi
    [[ -z "${reason}" ]] || return 2
    return 0
}
