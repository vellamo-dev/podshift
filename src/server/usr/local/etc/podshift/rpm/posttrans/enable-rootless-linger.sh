#!/usr/bin/env bash
# @file: enable-rootless-linger.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: LNG
# @description: Enables user lingering for the podshift user
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Enables user lingering for the dedicated podshift user.
#
# User lingering allows the user's systemd instance (user@.service) to
# continue running after logout and to start automatically at system boot.
# This is essential for rootless Podman, as it ensures that podman.socket
# and related user services remain available without requiring an
# active login session.
#
# Without lingering, user services (including the Podman socket) stop when
# the user logs out. By enabling lingering, the podshift user's service
# manager stays active, allowing rootless containers and the
# Podman API to function reliably in the background.

if [[ -z "${DIR_BA906559DA86:-}" ]]; then
    DIR_BA906559DA86="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_BA906559DA86
fi

# @description: Enables user lingering for the podshift user.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
enable-rootless-linger() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-LNG"
    local dir_linger file_linger linger_status
    file_linger="/var/lib/systemd/linger/podshift"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_BA906559DA86}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Enabling user lingering for podshift..."
    dir_linger="$(dirname "${file_linger}")"

    if ! id podshift >/dev/null 2>&1; then
        echo -e "\tUser 'podshift' does not exist. Skipping."
        return 0
    fi

    # Ensure the linger directory exists.
    if [[ ! -d "${dir_linger}" ]]; then
        echo -e "\tCreating linger directory..."
        mkdir -p "${dir_linger}"
    fi

    # Enable lingering (loginctl primary, manual file fallback).
    if command -v loginctl >/dev/null 2>&1; then
        if loginctl enable-linger podshift 2>/dev/null; then
            echo -e "\tLinger enabled via loginctl"
        else
            print-step-warn "loginctl enable-linger failed (non-fatal in some environments)."
        fi
    else
        print-step-warn "loginctl not found, using manual linger file creation."
    fi

    # Manual fallback: create the linger flag file if it does not exist.
    if [[ ! -f "${file_linger}" ]]; then
        echo -e "\tCreating linger flag file..."
        touch "${file_linger}"
        chown root:root "${file_linger}"
        chmod 0644 "${file_linger}"
        echo -e "\tLinger flag created at ${file_linger}"
    fi

    # Show the linger status when loginctl is available.
    if command -v loginctl >/dev/null 2>&1; then
        linger_status="$(loginctl show-user podshift 2>/dev/null | grep Linger)"
        [[ -n "${linger_status}" ]] && echo -e "\t${linger_status}"
    fi

    # Enable and start user@300.service.
    if systemctl is-enabled --quiet user@300.service 2>/dev/null; then
        echo -e "\tuser@300.service already enabled"
    else
        echo -e "\tEnabling user@300.service..."
        systemctl enable user@300.service 2>/dev/null \
            || print-step-warn "failed to enable user@300.service."
    fi
    if systemctl is-active --quiet user@300.service 2>/dev/null; then
        echo -e "\tuser@300.service already started"
    else
        echo -e "\tStarting user@300.service..."
        systemctl start user@300.service 2>/dev/null \
            || print-step-warn "failed to start user@300.service."
    fi

    # Reload the user manager.
    echo -e "\tReloading user manager..."
    systemctl --machine="300@.host" --user daemon-reload 2>/dev/null \
        || print-step-warn "could not reload the 300@.host user manager."

    # Enable and start systemd-tmpfiles-setup.service (user level).
    if systemctl --machine="300@.host" --user is-enabled --quiet systemd-tmpfiles-setup.service 2>/dev/null; then
        echo -e "\tsystemd-tmpfiles-setup.service already enabled"
    else
        echo -e "\tEnabling systemd-tmpfiles-setup.service..."
        systemctl --machine="300@.host" --user enable systemd-tmpfiles-setup.service 2>/dev/null \
            || print-step-warn "failed to enable systemd-tmpfiles-setup.service."
    fi
    if systemctl --machine="300@.host" --user is-active --quiet systemd-tmpfiles-setup.service 2>/dev/null; then
        echo -e "\tsystemd-tmpfiles-setup.service already started"
    else
        echo -e "\tStarting systemd-tmpfiles-setup.service..."
        systemctl --machine="300@.host" --user start systemd-tmpfiles-setup.service 2>/dev/null \
            || print-step-warn "failed to start systemd-tmpfiles-setup.service."
    fi

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && enable-rootless-linger
fi
