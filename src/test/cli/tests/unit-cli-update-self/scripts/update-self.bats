#!/usr/bin/env bats
# Stubbed tests for podshift update-self. No VM, no network, no root, no package changes.
# require-admin, rpm, dnf and sudo are stubbed as functions; sudo records its arguments.
# Run with: ./test unit-cli-update-self

setup() {
    HERE="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    REPO="${HERE}"
    while [ "${REPO}" != "/" ] && [ ! -f "${REPO}/podshift.spec" ]; do
        REPO="$(dirname "${REPO}")"
    done
    SCRIPT="${REPO}/src/server/opt/podshift/cli/modules/update-self/main.sh"
    SUDO_LOG="${BATS_TEST_TMPDIR}/sudo.log"
    RELOAD="Reload the PodShift page in Cockpit to load the new UI."
    SKIPPED="Note: cockpit-podshift was skipped: it is not in any enabled repository (probably installed from an RPM file)."
}

# Runs podshift-update-self with stubs.
# ADMIN=yes|no, INSTALLED=space list of installed packages, REPO_PKGS=space list in a repo,
# DNF_RC=exit code of sudo dnf update.
run_update() {
    run env PATH="/usr/bin:/bin:/opt/homebrew/bin:/usr/local/bin" \
        ADMIN="${ADMIN:-yes}" \
        INSTALLED="${INSTALLED-podshift}" \
        REPO_PKGS="${REPO_PKGS-podshift}" \
        DNF_RC="${DNF_RC:-0}" \
        SUDO_LOG="${SUDO_LOG}" \
        bash -c '
            require-admin() { [ "${ADMIN}" = yes ] || { echo "Unauthorised. Root required." >&2; return 1; }; }
            rpm() { [ "$1" = -q ] && [[ " ${INSTALLED} " == *" $2 "* ]]; }
            dnf() {
                if [ "$1" = repoquery ]; then
                    [[ " ${REPO_PKGS} " == *" $2 "* ]] && echo "$2-0.22.0-1.fc43.noarch"
                    return 0
                fi
                echo "unexpected dnf $*" >&2
                return 9
            }
            sudo() { echo "$*" >> "${SUDO_LOG}"; return "${DNF_RC}"; }
            source "$1" || exit 1
            shift
            podshift-update-self "$@"
        ' bash "${SCRIPT}" "$@"
}

@test "UI not installed: only podshift is updated, the UI is not installed" {
    INSTALLED="podshift" REPO_PKGS="podshift cockpit-podshift" run_update
    echo "${output}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
    [ "$(cat "${SUDO_LOG}")" = "dnf update --refresh podshift -y" ]
}

@test "UI installed and in a repository: one transaction for both, then the reload hint" {
    INSTALLED="podshift cockpit-podshift" REPO_PKGS="podshift cockpit-podshift" run_update
    echo "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${RELOAD}" ]
    [ "$(cat "${SUDO_LOG}")" = "dnf update --refresh podshift cockpit-podshift -y" ]
}

@test "UI installed but in no repository: podshift only, with a note" {
    INSTALLED="podshift cockpit-podshift" REPO_PKGS="podshift" run_update
    echo "${output}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${SKIPPED}" ]
    [ "$(cat "${SUDO_LOG}")" = "dnf update --refresh podshift -y" ]
}

@test "podshift in no repository: exit 1 and nothing is updated" {
    INSTALLED="podshift cockpit-podshift" REPO_PKGS="cockpit-podshift" run_update
    echo "${output}"
    [ "${status}" -eq 1 ]
    [ "${output}" = $'PodShift cannot be updated: not available in any enabled repository.\nIt may have been installed directly from an RPM file instead of COPR.' ]
    [ ! -e "${SUDO_LOG}" ]
}

@test "a failed update with the UI is exit 1 and prints no reload hint" {
    INSTALLED="podshift cockpit-podshift" REPO_PKGS="podshift cockpit-podshift" DNF_RC=1 run_update
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
    [ "$(cat "${SUDO_LOG}")" = "dnf update --refresh podshift cockpit-podshift -y" ]
}

@test "a failed podshift-only update is exit 1" {
    DNF_RC=1 run_update
    [ "${status}" -eq 1 ]
}

@test "not an administrator: exit 1 and nothing is updated" {
    ADMIN=no run_update
    [ "${status}" -eq 1 ]
    [ "${output}" = "Unauthorised. Root required." ]
    [ ! -e "${SUDO_LOG}" ]
}
