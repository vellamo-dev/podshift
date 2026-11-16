#!/usr/bin/env bash
# @file: read-stable-version.sh
# @source-dir: src/test/cli/shared/fn/release
# @group: test
# @category: helper
# @description: Reads the released version of a package from its spec on GitHub.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints Version, Release and the URL of <package>.spec on the release branch on GitHub.
# @details:
#   Reads https://raw.githubusercontent.com/<TST_RELEASE_GITHUB_OWNER>/<package>/<TST_RELEASE_BRANCH>/<package>.spec
#   with curl. No git is used. GitHub may serve a copy that is a few minutes old.
# @arg: $1 - the package, podshift or cockpit-podshift. The repository and the spec have the same name.
# @stdout: version, release and URL, separated by tabs, for example 0.15.3 1 https://...
# @stderr: why the spec could not be read.
# @exitcode: 0 when the spec was read, 1 on a network error or when the spec has no Version line.
read-stable-version() {
    local package url spec version release
    package="${1}"
    url="https://raw.githubusercontent.com/${TST_RELEASE_GITHUB_OWNER}/${package}/${TST_RELEASE_BRANCH}/${package}.spec"
    if ! spec="$(curl -fsSL --max-time 30 --retry 2 "${url}" 2>&1)"; then
        echo "Could not read ${url}: ${spec:-no answer}" >&2
        return 1
    fi
    version="$(printf '%s\n' "${spec}" | sed -n 's/^Version:[[:space:]]*//p' | head -n 1 | tr -d '[:space:]')"
    release="$(printf '%s\n' "${spec}" | sed -n 's/^Release:[[:space:]]*//p' | head -n 1 | sed 's/%{?dist}//' | tr -d '[:space:]')"
    if [[ -z "${version}" ]]; then
        echo "No Version line in ${url}" >&2
        return 1
    fi
    printf '%s\t%s\t%s\n' "${version}" "${release:-?}" "${url}"
}
