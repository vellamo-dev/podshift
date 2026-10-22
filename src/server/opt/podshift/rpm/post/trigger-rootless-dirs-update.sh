#!/usr/bin/env bash
# @file: trigger-rootless-dirs-update.sh
# @dir: /opt/podshift/rpm/post
# @group: post
# @prefix: PS-PO
# @id: DRS
# @description: Creates the rootless podman directories
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E04AB66E0316:-}" ]]; then
    DIR_E04AB66E0316="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E04AB66E0316
fi

# @description: Creates the rootless podman directories via systemd-tmpfiles.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
trigger-rootless-dirs-update() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PO-DRS"
    local dir_registries tmpfiles_conf
    dir_registries="/home/podshift/.config/containers/registries.conf.d"
    tmpfiles_conf="/usr/lib/tmpfiles.d/podshift-dirs.conf"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_E04AB66E0316}/../../fn/utils/print-step.sh"

    print-step-header "${step_tag}" "Creating directories for rootless podman..."

    if [[ -d "${dir_registries}" ]]; then
        print-step-skip "directories already exist"
        return 0
    fi

    if ! command -v systemd-tmpfiles >/dev/null 2>&1; then
        print-step-warn "systemd-tmpfiles not found, directories may not be created."
        return 0
    fi

    systemd-tmpfiles --create "${tmpfiles_conf}" \
        || print-step-warn "failed to create the rootless podman directories."

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && trigger-rootless-dirs-update
fi
