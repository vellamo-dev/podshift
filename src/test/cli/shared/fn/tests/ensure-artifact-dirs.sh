#!/usr/bin/env bash
# @file: ensure-artifact-dirs.sh
# @source-dir: src/test/cli/shared/fn/tests
# @group: test
# @category: helper
# @description: Creates the artifact folders and stops if any is missing or unusable.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Creates the artifacts folders and checks that each is a real, writable directory and not a symlink.
# @details:
#   The folders are artifacts/logs, the RPM share folder (TST_RPM_SHARE_DIR), artifacts/tmp and
#   artifacts/work under the repository root. Stops the run when any check fails.
# @arg: $1 - the repository root.
# @stderr: which folder failed and a Fix line.
# @exitcode: 0 if all four are usable, 3 otherwise (cannot run here).
ensure-artifact-dirs() {
    local repo_root rpm_dir path name
    repo_root="${1}"
    rpm_dir="${TST_RPM_SHARE_DIR:-artifacts/rpm}"
    case "${rpm_dir}" in
        /*) ;;
        *) rpm_dir="${repo_root}/${rpm_dir}" ;;
    esac
    for path in \
        "${repo_root}/artifacts/logs" \
        "${rpm_dir}" \
        "${repo_root}/artifacts/tmp" \
        "${repo_root}/artifacts/work"
    do
        name="${path#"${repo_root}/"}"
        if ! mkdir -p "${path}" 2>/dev/null; then
            echo "Cannot create ${name}." >&2
            echo "Fix: create a writable ${name} under the repository root." >&2
            return 3
        fi
        if [[ -L "${path}" ]]; then
            echo "${name} is a symlink; the test engine needs a real directory." >&2
            echo "Fix: replace the symlink with a normal directory at ${name}." >&2
            return 3
        fi
        if [[ ! -d "${path}" ]]; then
            echo "${name} is not a directory." >&2
            echo "Fix: remove whatever is at ${name} and let the test engine create the folder." >&2
            return 3
        fi
        if [[ ! -w "${path}" ]]; then
            echo "${name} is not writable." >&2
            echo "Fix: make ${name} writable by the user that runs the tests." >&2
            return 3
        fi
    done
    return 0
}
