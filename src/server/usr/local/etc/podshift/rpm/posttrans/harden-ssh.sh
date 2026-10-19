#!/usr/bin/env bash
# @file: harden-ssh.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: HSS
# @description: Changes the SSH port to 1022 and restarts sshd
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Updates SSHD configuration to change the port to 1022 and restarts the service.
#
# Changing from 22 is a common security-hardening step that reduces exposure
# to automated port-scanning and brute-force attacks targeting the well-known default port.

if [[ -z "${DIR_CB30D0CF53AD:-}" ]]; then
    DIR_CB30D0CF53AD="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_CB30D0CF53AD
fi

# @description: Changes the SSH port to 1022 and restarts sshd.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
harden-ssh() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-HSS"
    local conf_file backup_file
    conf_file="/etc/ssh/sshd_config"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_CB30D0CF53AD}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Hardening SSH: changing port 22 to 1022..."

    # Precondition: config exists.
    if [ ! -f "${conf_file}" ]; then
        print-step-warn "sshd_config not found, skipping SSH hardening."
        return 0
    fi

    # Idempotency: already on port 1022 (allow optional comment/whitespace).
    if grep -qE '^[[:space:]]*Port[[:space:]]+1022([[:space:]]|#|$)' "${conf_file}"; then
        echo -e "\tAlready hardened"
        return 0
    fi

    # Respect a custom port: if an uncommented Port directive exists and it is
    # not 22, the user has already chosen a port; leave it unchanged.
    if grep -qE '^[[:space:]]*Port[[:space:]]+[0-9]+' "${conf_file}" \
        && ! grep -qE '^[[:space:]]*Port[[:space:]]+22([[:space:]]|#|$)' "${conf_file}"; then
        print-step-warn "a custom SSH port is already configured; leaving it unchanged."
        return 0
    fi

    # Backup with a unique name.
    echo -e "\tBacking up sshd_config"
    backup_file="${conf_file}.bak.$(date +%F_%H%M%S).$$"
    if ! cp "${conf_file}" "${backup_file}"; then
        print-step-warn "failed to back up sshd_config, skipping SSH hardening."
        return 0
    fi

    # Precise edit: change only an exact "#Port 22" or "Port 22" line.
    echo -e "\tUpdating sshd_config"
    sed -i 's/^#Port 22$/Port 1022/' "${conf_file}"
    sed -i 's/^Port 22$/Port 1022/' "${conf_file}"
    # If no Port line was changed, append Port 1022.
    grep -q '^Port 1022$' "${conf_file}" || echo 'Port 1022' >>"${conf_file}"
    restorecon "${conf_file}" 2>/dev/null || true

    # Validate the configuration before restarting.
    echo -e "\tValidating configuration"
    if ! sshd -t 2>/dev/null; then
        cp "${backup_file}" "${conf_file}"
        restorecon "${conf_file}" 2>/dev/null || true
        print-step-warn "sshd configuration invalid after port change, rolled back."
        return 0
    fi

    # Restart sshd; roll back on failure.
    echo -e "\tRestarting sshd"
    if ! systemctl restart sshd; then
        cp "${backup_file}" "${conf_file}"
        restorecon "${conf_file}" 2>/dev/null || true
        systemctl restart sshd >/dev/null 2>&1 || true
        print-step-warn "failed to restart sshd, rolled back to the previous configuration."
        return 0
    fi

    print-step-ok
    return 0
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && harden-ssh
fi
