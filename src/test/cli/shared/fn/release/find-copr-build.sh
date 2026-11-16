#!/usr/bin/env bash
# @file: find-copr-build.sh
# @source-dir: src/test/cli/shared/fn/release
# @group: test
# @category: helper
# @description: Finds the newest Copr build of a package, and its newest successful build for one chroot.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the newest Copr build of a package and its newest build that succeeded in a chroot.
# @details:
#   Uses the public Copr API, no login. The Copr project has the same name as the package, under
#   TST_COPR_OWNER. It looks through the newest TST_COPR_BUILD_LIMIT builds. The state of a build is
#   read for the chroot itself, so a build that failed only in that chroot does not count.
#   A field that has no value is printed as -.
# @arg: $1 - the package, podshift or cockpit-podshift.
# @arg: $2 - the chroot, for example fedora-45-x86_64.
# @stdout: one tab-separated line: newest build id, its state in the chroot, its version, then the id and version of the newest successful build.
# @stderr: why Copr could not be read.
# @exitcode: 0 when Copr answered, 1 on a network error or an answer that is not JSON.
find-copr-build() {
    local package chroot url list rows id version answer state latest_id latest_state latest_version ok_id ok_version
    package="${1}"
    chroot="${2}"
    url="${TST_COPR_API}/build/list?ownername=${TST_COPR_OWNER}&projectname=${package}&packagename=${package}&limit=${TST_COPR_BUILD_LIMIT}"
    if ! list="$(curl -fsSL --max-time 30 --retry 2 "${url}" 2>&1)"; then
        echo "Could not read the Copr build list ${url}: ${list:-no answer}" >&2
        return 1
    fi
    if ! rows="$(jq -r --arg c "${chroot}" '.items | sort_by(-.id) | .[] | select((.chroots // []) | index($c)) | "\(.id)\t\(.source_package.version // "-")"' <<<"${list}" 2>/dev/null)"; then
        echo "The Copr build list is not valid JSON: ${url}" >&2
        return 1
    fi
    latest_id="-"
    latest_state="-"
    latest_version="-"
    ok_id="-"
    ok_version="-"
    while IFS=$'\t' read -r id version; do
        [[ -n "${id}" ]] || continue
        if ! answer="$(curl -fsSL --max-time 30 --retry 2 "${TST_COPR_API}/build-chroot?build_id=${id}&chrootname=${chroot}" 2>&1)"; then
            echo "Could not read the state of Copr build ${id} in ${chroot}: ${answer:-no answer}" >&2
            return 1
        fi
        state="$(jq -r '.state // "-"' <<<"${answer}" 2>/dev/null)" || state="-"
        if [[ "${latest_id}" == "-" ]]; then
            latest_id="${id}"
            latest_state="${state}"
            latest_version="${version}"
        fi
        if [[ "${state}" == "succeeded" ]]; then
            ok_id="${id}"
            ok_version="${version}"
            break
        fi
    done <<<"${rows}"
    printf '%s\t%s\t%s\t%s\t%s\n' "${latest_id}" "${latest_state}" "${latest_version}" "${ok_id}" "${ok_version}"
}
