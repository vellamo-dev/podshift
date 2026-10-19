#!/usr/bin/env bash
# update-target-system.sh
# /usr/local/etc/podshift/rpm/utils
# Applies the kernel parameters and systemd unit files installed by the
# PodShift package, so they take effect before the remaining
# post-transaction steps run.

if [[ -z "${DIR_A2C6C3AD0274:-}" ]]; then
    DIR_A2C6C3AD0274="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A2C6C3AD0274
fi

# Applies sysctl kernel settings and reloads systemd units.
update-target-system() {
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_A2C6C3AD0274}/../../fn/utils/print-warning.sh"

    echo -e "\nUpdating target system..."
    # Load and apply kernel parameter configuration files.
    sysctl --system 2>/dev/null \
        || print-warning "failed to apply sysctl settings."
    # Rescan unit files and rebuild systemd's dependency tree.
    systemctl daemon-reload 2>/dev/null \
        || print-warning "failed to reload systemd units."
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && update-target-system
fi
