#!/usr/bin/env bash
# @file: enable-start-rootless-podman.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: POD
# @description: Enables and starts the rootless Podman socket
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
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
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-POD"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_AF4859915F16}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Enabling and starting rootless podman..."

    if ! id podshift >/dev/null 2>&1; then
        echo -e "\tUser 'podshift' does not exist. Skipping."
        return 0
    fi

    echo -e "\tReloading user manager..."
    systemctl --machine="300@.host" --user daemon-reload >/dev/null 2>&1 \
        || print-step-warn "failed to reload the 300@.host user manager."

    if systemctl --machine="300@.host" --user is-enabled --quiet podman.socket 2>/dev/null; then
        echo -e "\tAlready enabled"
    else
        echo -e "\tEnabling rootless podman..."
        systemctl --machine="300@.host" --user enable podman.socket >/dev/null 2>&1 \
            || print-step-warn "failed to enable podman.socket."
    fi

    if systemctl --machine="300@.host" --user is-active --quiet podman.socket 2>/dev/null; then
        echo -e "\tAlready started"
    else
        echo -e "\tStarting rootless podman..."
        systemctl --machine="300@.host" --user start podman.socket >/dev/null 2>&1 \
            || print-step-warn "failed to start podman.socket."
    fi

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && enable-start-rootless-podman
fi
