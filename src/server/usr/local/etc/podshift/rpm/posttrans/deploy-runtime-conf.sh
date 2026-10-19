#!/usr/bin/env bash
# deploy-runtime-conf.sh
# /usr/local/etc/podshift/rpm/posttrans
# Deploys the runtime configuration templates to the target system.
# Each template is copied only when its target does not exist, so user
# edits are never overwritten.

if [[ -z "${DIR_A42A118E8B3B:-}" ]]; then
    DIR_A42A118E8B3B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A42A118E8B3B
fi

# shellcheck source=../../conf/main.conf
# shellcheck source=../../fn/load-podshift-conf-main.sh
source "${DIR_A42A118E8B3B}/../../fn/load-podshift-conf-main.sh" --now
# shellcheck source=../../fn/utils/print-warning.sh
source "${DIR_A42A118E8B3B}/../../fn/utils/print-warning.sh"

# Installs one template to its target, skipping if it already exists.
deploy-runtime-conf-file() {
    local src_file dst_file filename
    dst_file="${1}"
    filename="$(basename "${dst_file}")"
    # shellcheck source=../../../../../../var/lib/podshift/tpl
    src_file="${PODSHIFT_RUNTIME_CONF_TEMPLATES}/${filename}"
    if [[ -f "${src_file}" && ! -f "${dst_file}" ]]; then
        echo -e "\t- ${filename}"
        install -D -m 0644 "${src_file}" "${dst_file}" || print-warning "failed to install ${filename}"
    fi
}

# Deploys the flat runtime templates to their targets.
deploy-runtime-conf() {
    echo -e "\nDeploying runtime configurations..."
    # Copies template files into the target location
    deploy-runtime-conf-file "${PODSHIFT_RUNTIME_CONF}"
    deploy-runtime-conf-file "/etc/fail2ban/jail.d/00-global.local"
    deploy-runtime-conf-file "/etc/fail2ban/jail.d/sshd.local"
    deploy-runtime-conf-file "/etc/ssh/sshd_config.d/20-podshift-access.conf"
    deploy-runtime-conf-file "/etc/ssh/sshd_config.d/50-podshift-auth.conf"
    echo -e "\tDone"
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && deploy-runtime-conf
fi
