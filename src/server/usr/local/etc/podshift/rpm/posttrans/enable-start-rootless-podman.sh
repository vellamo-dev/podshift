#!/usr/bin/env bash
# enable-start-rootless-podman.sh
# /usr/local/etc/podshift/rpm/posttrans
# Enables and starts the rootless podman.
#
# Rootless podman is the crucial part of PodShift.
# It ensures that podman runs in sandboxed mode, reducing the attack surface.
#
# Rootless podman allows containers to run without root privileges on
# the host system. Instead of using a privileged daemon (like Docker),
# podman runs entirely within the user's own namespace.
# Container processes are mapped to unprivileged UIDs on the
# host (via subuid/subgid ranges), providing strong isolation.
#
# Rootless operation aligns with modern security best practices and is
# often required in restricted or high-security environments.

if [[ -z "${DIR_AF4859915F16:-}" ]]; then
    DIR_AF4859915F16="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_AF4859915F16
fi

# Enables and starts podman.socket for the podshift user via the
# 300@.host user manager.
enable-start-rootless-podman() {
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_AF4859915F16}/../../fn/utils/print-warning.sh"

    echo -e "\nEnabling and starting rootless podman..."

    if ! id podshift >/dev/null 2>&1; then
        echo -e "\tUser 'podshift' does not exist. Skipping."
        return 0
    fi

    echo -e "\tReloading user manager..."
    systemctl --machine="300@.host" --user daemon-reload >/dev/null 2>&1 \
        || print-warning "failed to reload the 300@.host user manager."

    if systemctl --machine="300@.host" --user is-enabled --quiet podman.socket 2>/dev/null; then
        echo -e "\tAlready enabled"
    else
        echo -e "\tEnabling rootless podman..."
        systemctl --machine="300@.host" --user enable podman.socket >/dev/null 2>&1 \
            || print-warning "failed to enable podman.socket."
    fi

    if systemctl --machine="300@.host" --user is-active --quiet podman.socket 2>/dev/null; then
        echo -e "\tAlready started"
    else
        echo -e "\tStarting rootless podman..."
        systemctl --machine="300@.host" --user start podman.socket >/dev/null 2>&1 \
            || print-warning "failed to start podman.socket."
    fi

    echo -e "\tDone"
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && enable-start-rootless-podman
fi
