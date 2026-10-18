#!/usr/bin/env bash
# update-selinux.sh
# /usr/local/etc/podshift/rpm/posttrans
# Imports custom SELinux port definitions.

if [[ -z "${DIR_4F418A769F3C:-}" ]]; then
    DIR_4F418A769F3C="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4F418A769F3C
fi

update-selinux() {
    local import_file port_list
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_4F418A769F3C}/../../fn/utils/print-warning.sh"

    # shellcheck source=../../../../../../etc/selinux/local/port-config.semanage
    import_file="/etc/selinux/local/port-config.semanage"

    echo -e "\nUpdating SELinux configuration..."

    # Port labelling only matters when SELinux is enabled (real Fedora target);
    # skip in containers/CI where no policy store is accessible.
    if ! command -v selinuxenabled >/dev/null 2>&1 || ! selinuxenabled; then
        echo -e "\tSkipped (SELinux is not enabled)"
        return 0
    fi

    semanage import -f "${import_file}" 2>/dev/null

    # Verify the end state: ports 1022 and 81 must be labelled ssh_port_t.
    port_list="$(semanage port -l)"
    if ! grep -qE 'ssh_port_t.*\b1022\b' <<<"${port_list}" \
        || ! grep -qE 'ssh_port_t.*\b81\b' <<<"${port_list}"; then
        print-warning "SELinux port labeling is incomplete (1022/81 are not ssh_port_t)."
        return 0
    fi

    echo -e "\tDone"
    return 0
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && update-selinux
fi
