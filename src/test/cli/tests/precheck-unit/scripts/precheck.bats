#!/usr/bin/env bats
# Stubbed tests for utils/portable/precheck.sh, the portable precheck. No VM, no network, no root.
# Fake system files come from precheck-make-root.sh and fake commands from stubs/.
# Run with: ./test precheck-unit

setup() {
    HERE="$(cd "$(dirname "${BATS_TEST_FILENAME}")" && pwd)"
    REPO="${HERE}"
    while [ "${REPO}" != "/" ] && [ ! -f "${REPO}/podshift.spec" ]; do
        REPO="$(dirname "${REPO}")"
    done
    SCRIPT="${REPO}/utils/portable/precheck.sh"
    source "${HERE}/precheck-make-root.sh"
    ROOT="${BATS_TEST_TMPDIR}/root"
    unset STUB_UID STUB_RPM STUB_DNF_PODMAN STUB_DNF_PODSHIFT STUB_DNF_INSTALL STUB_SELINUX STUB_TARGET STUB_DOCKER STUB_PORTS STUB_NET STUB_BASH_VERSION SUDO_USER
    export STUB_USER=ivor
}

run_check() {
    run env PATH="${HERE}/stubs:/usr/bin:/bin" PRECHECK_ROOT="${ROOT}" bash "${SCRIPT}" --plain "$@"
}

@test "Fedora 45 server, not root: Ready, dry run skipped" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    run_check
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"Result: Ready (exit 0)"* ]]
    [[ "${output}" == *"○ dnf dry run of PodShift's packages [needs root"* ]]
    [[ "${output}" == *"Run with sudo for the full check."* ]]
    [[ "${output}" == *"✔ Podman 6.0 or newer [dnf offers 6.0.2-1.fc45]"* ]]
}

@test "Fedora 45 server as root: dry run resolves" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_UID=0 SUDO_USER=ivor
    run_check
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"✔ dnf dry run of PodShift's packages [all packages can be installed]"* ]]
    [[ "${output}" != *"skipped"* ]]
}

@test "Fedora 45 as root: dnf conflict is a blocker with the problem listed" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_UID=0 STUB_DNF_INSTALL=conflict
    run_check
    echo "${output}"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"nothing provides libfoo"* ]]
    [[ "${output}" == *"Checking security and clashes   not run"* ]]
}

@test "Fedora 45 Workstation: multi-purpose warning" {
    precheck-make-root "${ROOT}" fedora 45 workstation "Fedora Linux"
    run_check
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"⚠ Edition [desktop, VARIANT_ID=workstation]"* ]]
    [[ "${output}" == *"multi-purpose desktop machine"* ]]
    [[ "${output}" == *"Result: Ready with warnings (exit 1)"* ]]
}

@test "Server edition booting to graphical target counts as desktop" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_TARGET=graphical.target
    run_check
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"boots to a graphical desktop"* ]]
}

@test "Workstation with the desktop flag: no edition warning" {
    precheck-make-root "${ROOT}" fedora 45 workstation "Fedora Linux"
    touch "${ROOT}/etc/podshift-desktop"
    rm -f "${ROOT}/home/ivor/.ssh/authorized_keys"
    run_check
    echo "${output}"
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"✔ Install type [desktop install, /etc/podshift-desktop exists]"* ]]
    [[ "${output}" != *"SSH key"* ]]
}

@test "Fedora 44: version blocker, stops early" {
    precheck-make-root "${ROOT}" fedora 44 server "Fedora Linux"
    run_check
    echo "${output}"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"✘ Fedora 45 or newer [found 44]"* ]]
    [[ "${output}" == *"Checking packages               not run"* ]]
}

@test "Debian: OS blocker" {
    precheck-make-root "${ROOT}" debian 13 "" "Debian GNU/Linux"
    run_check
    echo "${output}"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"✘ OS is Fedora"* ]]
    [[ "${output}" == *"AppArmor"* ]]
}

@test "CoreOS (ostree marker): image-based blocker" {
    precheck-make-root "${ROOT}" fedora 45 coreos "Fedora CoreOS"
    touch "${ROOT}/run/ostree-booted"
    run_check
    echo "${output}"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"image-based system"* ]]
    [[ "${output}" == *"/usr             read-only (image-based system)"* ]]
}

@test "Read-only root mount: blocker" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    printf '/dev/vda3 / xfs ro,relatime 0 0\n' >"${ROOT}/proc/mounts"
    run_check
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"mounted read-only"* ]]
}

@test "PodShift installed, Copr enabled, newer build: Installed with update available" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    printf '[x]\nenabled=1\n' >"${ROOT}/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:vellamo:podshift.repo"
    export STUB_RPM="podshift=0.16.2-1.fc45 podman=6.0.2-1.fc45" STUB_DNF_PODSHIFT=0.17.0-1.fc45
    run_check
    echo "${output}"
    [ "${status}" -eq 3 ]
    [[ "${output}" == *"update available: 0.17.0-1.fc45"* ]]
    [[ "${output}" == *"Result: Installed (exit 3)"* ]]
}

@test "PodShift installed and up to date" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    printf '[x]\nenabled=1\n' >"${ROOT}/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:vellamo:podshift.repo"
    export STUB_RPM="podshift=0.17.0-1.fc45" STUB_DNF_PODSHIFT=0.17.0-1.fc45
    run_check
    [ "${status}" -eq 3 ]
    [[ "${output}" == *"up to date"* ]]
}

@test "PodShift installed, Copr not enabled: cannot check the newest version" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_RPM="podshift=0.17.0-1.fc45"
    run_check
    echo "${output}"
    [ "${status}" -eq 3 ]
    [[ "${output}" == *"cannot check, the vellamo/podshift Copr repo is not enabled"* ]]
}

@test "Podman 5.8 offered: blocker" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_DNF_PODMAN=5.8.1-1.fc45
    run_check
    echo "${output}"
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"✘ Podman 6.0 or newer [newest dnf offers is 5.8.1-1.fc45]"* ]]
}

@test "Podman 6 already installed passes without dnf" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_RPM="podman=6.1.0-1.fc45" STUB_DNF_PODMAN=""
    run_check
    [ "${status}" -eq 0 ]
    [[ "${output}" == *"[installed 6.1.0-1.fc45]"* ]]
}

@test "dnf gives no Podman version: warning" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_DNF_PODMAN=""
    run_check
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"cannot check, dnf gave no Podman version"* ]]
}

@test "System Bash 4.4: blocker" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_BASH_VERSION=4.4.23
    run_check
    [ "${status}" -eq 2 ]
    [[ "${output}" == *"✘ Bash 5.0 or newer for PodShift [found 4.4.23]"* ]]
}

@test "Network down: repository warning" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_NET=down
    run_check
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"no answer from mirrors.fedoraproject.org, download.copr.fedorainfracloud.org"* ]]
}

@test "SELinux permissive, Docker, port 80, two users, no SSH key, UID 300 taken: warnings" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    printf 'anna:x:1001:1001:Anna:/home/anna:/bin/bash\nweb:x:300:300::/srv:/sbin/nologin\n' >>"${ROOT}/etc/passwd"
    rm -f "${ROOT}/home/ivor/.ssh/authorized_keys"
    export STUB_SELINUX=Permissive STUB_DOCKER=1 STUB_PORTS="22 80 9090"
    run_check
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"⚠ SELinux is not enforcing [permissive]"* ]]
    [[ "${output}" == *"The PodShift install switches it to enforcing."* ]]
    [[ "${output}" != *"sudo podshift selinux enforce to switch it on."* ]]
    [[ "${output}" == *"⚠ No Docker [docker service running]"* ]]
    [[ "${output}" == *"⚠ PodShift's ports are free [in use: 80]"* ]]
    [[ "${output}" == *"⚠ One person uses this machine [2 login users: ivor anna]"* ]]
    [[ "${output}" == *"⚠ UID 300 is free for the podshift user [used by web]"* ]]
    [[ "${output}" == *"⚠ SSH key for ivor"* ]]
}

@test "SELinux permissive on a desktop install: points to the command" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    touch "${ROOT}/etc/podshift-desktop"
    export STUB_SELINUX=Permissive
    run_check
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"⚠ SELinux is not enforcing [permissive]"* ]]
    [[ "${output}" == *"sudo podshift selinux enforce to switch it on."* ]]
    [[ "${output}" != *"The PodShift install switches it to enforcing."* ]]
}

@test "SELinux disabled: warning wording and steps hint" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    export STUB_SELINUX=Disabled
    run_check
    echo "${output}"
    [ "${status}" -eq 1 ]
    [[ "${output}" == *"⚠ SELinux is not enforcing [disabled]"* ]]
    [[ "${output}" == *"sudo podshift selinux enforce prints the steps"* ]]
}

@test "--json is valid JSON with the result" {
    command -v jq >/dev/null || skip "jq not installed"
    precheck-make-root "${ROOT}" fedora 45 workstation "Fedora Linux"
    run env PATH="${HERE}/stubs:/usr/bin:/bin" PRECHECK_ROOT="${ROOT}" bash "${SCRIPT}" --json
    [ "${status}" -eq 1 ]
    printf '%s' "${output}" | jq -e '.result == "Ready with warnings" and .exit_code == 1 and (.checks | length) > 5' >/dev/null
}

@test "runs under macOS /bin/bash 3.2 too" {
    [ -x /bin/bash ] || skip
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    run env PATH="${HERE}/stubs:/usr/bin:/bin" PRECHECK_ROOT="${ROOT}" /bin/bash "${SCRIPT}" --plain
    echo "${output}"
    [ "${status}" -eq 0 ]
}

@test "no colour codes when output is not a terminal" {
    precheck-make-root "${ROOT}" fedora 45 server "Fedora Linux"
    run env PATH="${HERE}/stubs:/usr/bin:/bin" PRECHECK_ROOT="${ROOT}" bash "${SCRIPT}"
    [[ "${output}" != *$'\033['* ]]
}

@test "unknown option exits 4" {
    run bash "${SCRIPT}" --bogus
    [ "${status}" -eq 4 ]
}

@test "a cut-off download runs no checks" {
    head -c 20000 "${SCRIPT}" >"${BATS_TEST_TMPDIR}/cut.sh"
    run bash "${BATS_TEST_TMPDIR}/cut.sh"
    [[ "${output}" != *"PodShift precheck"* ]]
}
