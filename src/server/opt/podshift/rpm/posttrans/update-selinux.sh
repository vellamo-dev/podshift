#!/usr/bin/env bash
# @file: update-selinux.sh
# @dir: /opt/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: SEL
# @description: Imports the SELinux port definitions
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Imports custom SELinux port definitions.

if [[ -z "${DIR_4F418A769F3C:-}" ]]; then
    DIR_4F418A769F3C="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4F418A769F3C
fi

# @description: Imports the SELinux port definitions.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
update-selinux() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-SEL"
    local import_file port_list
    # shellcheck source=../../../../../../etc/selinux/local/port-config.semanage
    import_file="/etc/selinux/local/port-config.semanage"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_4F418A769F3C}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Updating SELinux configuration..."

    # Port labelling only matters when SELinux is enabled (real Fedora target);
    # skip in containers/CI where no policy store is accessible.
    if ! command -v selinuxenabled >/dev/null 2>&1 || ! selinuxenabled; then
        print-step-skip "SELinux is not enabled"
        return 0
    fi

    semanage import -f "${import_file}" 2>/dev/null

    # Verify the end state: 1022 = ssh_port_t, 81 = http_port_t.
    port_list="$(semanage port -l)"
    if ! grep -qE 'ssh_port_t.*\b1022\b' <<<"${port_list}" \
        || ! grep -qE 'http_port_t.*\b81\b' <<<"${port_list}"; then
        print-step-warn "SELinux port labeling is incomplete (1022 is not ssh_port_t or 81 is not http_port_t)."
        return 0
    fi

    print-step-ok
    return 0
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && update-selinux
fi
