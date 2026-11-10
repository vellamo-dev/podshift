#!/usr/bin/env bash
# @file: posttrans.sh
# @source-dir: src/server/opt/podshift/rpm
# @dest-dir: /opt/podshift/rpm
# @host-edit: no
# @group: posttrans
# @category: entry
# @step: PS-PT-0PT
# @description: Coordinates the post-transaction steps.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# This script prepares the system after the PodShift package has been
# installed or upgraded. Instead of putting all logic into one giant
# posttrans script, the work is split into many small, focused scripts.
# This main script coordinates their execution.

if [[ -z "${DIR_0A87CD31EE51:-}" ]]; then
    DIR_0A87CD31EE51="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_0A87CD31EE51
fi

podshift-rpm-do-posttrans() {
    local rpm_dir action
    action="${1}"
    rpm_dir="${2}"
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-0PT"
    local -r step_end_tag="PS-PT-1PT"
    # shellcheck source=../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${rpm_dir}/../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Preparing system (posttrans)..."
    echo -e "\tInstall mode: ${action}"
    # shellcheck source=../fn/utils/is-install-type-desktop.sh
    declare -F is-install-type-desktop >/dev/null || source "${rpm_dir}/../fn/utils/is-install-type-desktop.sh"
    if is-install-type-desktop; then
        echo -e "\tInstall type: desktop"
    else
        echo -e "\tInstall type: server"
    fi

    source "${rpm_dir}/utils/wait-for-tools.sh"

    # Wait for essential tools (reports its own timeout via print-warning)
    wait-for-tools

    # Update System
    source "${rpm_dir}/utils/update-target-system.sh"
    update-target-system

    # Deploy runtime conf
    source "${rpm_dir}/posttrans/deploy-runtime-conf.sh"
    deploy-runtime-conf

    # Configure and enable firewalld
    source "${rpm_dir}/posttrans/enable-configure-firewalld.sh"
    enable-configure-firewalld

    # Update SELinux
    source "${rpm_dir}/posttrans/update-selinux.sh"
    update-selinux

    # Enable and start fail2ban
    source "${rpm_dir}/posttrans/enable-fail2ban.sh"
    enable-fail2ban

    # Enable and start PCP metrics
    source "${rpm_dir}/posttrans/enable-pcp.sh"
    enable-pcp

    # Create the rootless remote key
    source "${rpm_dir}/../fn/rootless/make-rootless-remote-key.sh"
    make-rootless-remote-key

    # Install shell initialisation files for the dedicated podshift user
    source "${rpm_dir}/posttrans/install-rootless-profile.sh"
    install-rootless-profile

    # Install rootless podman configuration overrides
    source "${rpm_dir}/posttrans/install-rootless-podman-auth-file.sh"
    install-rootless-podman-auth-file

    # Enables user lingering for rootless podman
    source "${rpm_dir}/posttrans/enable-rootless-linger.sh"
    enable-rootless-linger

    # Make podshift user Podman compatible
    source "${rpm_dir}/posttrans/make-podshift-user-podman-compatible.sh"
    make-podshift-user-podman-compatible

    # Install the podman auto-update timer override
    source "${rpm_dir}/posttrans/install-podman-auto-update-override.sh"
    install-podman-auto-update-override

    # Enable and start the PodShift user services
    source "${rpm_dir}/posttrans/enable-start-user-services.sh"
    enable-start-user-services

    # Configure the SSH ports (last: restarts sshd after the SELinux port label is set)
    source "${rpm_dir}/posttrans/configure-ssh-ports.sh"
    configure-ssh-ports

    print-step-header "${step_end_tag}" "PodShift version summary"
    # Print PodShift version
    # shellcheck source=../fn/common/podshift-version.sh
    # shellcheck source=../cli/podshift.sh
    podshift --version

    # Remind about environment tag
    if [ "${action}" -eq 1 ]; then
        echo
        # shellcheck source=../../../../../opt/podshift/doc/help/note-env-var-conf.txt
        podshift --help note-env-var-conf
    fi

}

podshift-rpm-do-posttrans "${1:-0}" "${DIR_0A87CD31EE51}"
