#!/usr/bin/env bats
# Stubbed tests for /etc/profile.d/podshift.sh (src/server/etc/profile.d/podshift.sh): who gets the helpers.
# A copy points at the source tree; is-podshift, load-podshift-conf-nw and id are stubs. Run with: ./test unit-cli-config

setup() {
    local here repo
    here="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    # The shared helper is at the same place from every suite's scripts/ folder.
    declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
    repo="$(find-repo-root "${here}")" || return 1
    # The root branch cannot be tested as root: every case would load.
    [ "${EUID}" -ne 0 ] || skip "runs only as a user that is not root"
    PROFILE="${BATS_TEST_TMPDIR}/podshift.sh"
    sed "s|/opt/podshift/|${repo}/src/server/opt/podshift/|g" "${repo}/src/server/etc/profile.d/podshift.sh" > "${PROFILE}"
    mkdir -p "${BATS_TEST_TMPDIR}/bin"
    printf '#!/usr/bin/env bash\n[ "$1" = "-Gn" ] && echo "${STUB_GROUPS}"\nexit 0\n' > "${BATS_TEST_TMPDIR}/bin/id"
    chmod +x "${BATS_TEST_TMPDIR}/bin/id"
}

# Sources the profile copy as a login shell would and prints what it loaded.
# $1 - yes when the stub is-podshift says podshift; $2 - groups printed by id -Gn.
run_profile() {
    run env -i PATH="${BATS_TEST_TMPDIR}/bin:/usr/bin:/bin" STUB_PODSHIFT="${1}" STUB_GROUPS="${2}" \
        bash -c '
            is-podshift() { [ "${STUB_PODSHIFT}" = yes ]; }
            load-podshift-conf-nw() { export PODSHIFT_TEST_LOADED=1 TSV_NW1=192.0.2.1; }
            source "$1"
            declare -F hcl quit
            env | grep -E "^(PODSHIFT|TSV)_" | cut -d= -f1 | sort
        ' bash "${PROFILE}"
}

@test "an ordinary user gets no helpers and no PODSHIFT_ or TSV_ variables" {
    run_profile no "users"
    [ -z "${output}" ]
}

@test "a group name that only contains wheel does not count" {
    run_profile no "users wheels nowheel"
    [ -z "${output}" ]
}

@test "a member of wheel gets the helpers and the variables" {
    run_profile no "users wheel"
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf 'hcl\nquit\nPODSHIFT_TEST_LOADED\nTSV_NW1')" ]
}

@test "the podshift user gets the helpers and the variables" {
    run_profile yes "podshift"
    [ "${status}" -eq 0 ]
    [ "${output}" = "$(printf 'hcl\nquit\nPODSHIFT_TEST_LOADED\nTSV_NW1')" ]
}

@test "a shell that is not Bash skips the file" {
    if ! command -v zsh >/dev/null 2>&1; then
        skip "zsh is not installed"
    fi
    run env -i PATH="${BATS_TEST_TMPDIR}/bin:/usr/bin:/bin" STUB_GROUPS="wheel" zsh -c 'source "$1"; typeset -f hcl >/dev/null && echo loaded; true' zsh "${PROFILE}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}
