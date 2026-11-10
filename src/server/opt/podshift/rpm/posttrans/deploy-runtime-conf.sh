#!/usr/bin/env bash
# @file: deploy-runtime-conf.sh
# @source-dir: src/server/opt/podshift/rpm/posttrans
# @dest-dir: /opt/podshift/rpm/posttrans
# @host-edit: no
# @group: posttrans
# @category: step
# @step: PS-PT-DRC
# @description: Deploys the runtime configuration templates.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Deploys the runtime configuration templates to the target system.
# Each template is copied only when its target does not exist, so user
# edits are never overwritten.

if [[ -z "${DIR_A42A118E8B3B:-}" ]]; then
    DIR_A42A118E8B3B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A42A118E8B3B
fi

# @description: Installs one template to its target, skipping if it already exists.
# @arg: $1 - target path
deploy-runtime-conf-file() {
    local dst_file filename
    dst_file="${1}"
    filename="$(basename "${dst_file}")"
    # shellcheck source=../../assets/tpl
    src_file="${PODSHIFT_RUNTIME_CONF_TEMPLATES}/${filename}"
    if [[ -f "${src_file}" && ! -f "${dst_file}" ]]; then
        echo -e "\t- ${filename}"
        install -D -m 0644 "${src_file}" "${dst_file}" || print-step-warn "failed to install ${filename}"
    fi
}

# @description: Deploys the runtime configuration templates.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
deploy-runtime-conf() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-DRC"
    # shellcheck source=../../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_A42A118E8B3B}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Deploying runtime configurations..."
    # shellcheck source=../../conf/main.conf
    # shellcheck source=../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_A42A118E8B3B}/../../fn/load-podshift-conf-main.sh"
    load-podshift-conf-main
    # Copies template files into the target location
    deploy-runtime-conf-file "${PODSHIFT_RUNTIME_CONF}"
    # Desktop install: no fail2ban jails and no sshd drop-ins.
    # shellcheck source=../../fn/utils/is-install-type-desktop.sh
    declare -F is-install-type-desktop >/dev/null || source "${DIR_A42A118E8B3B}/../../fn/utils/is-install-type-desktop.sh"
    if is-install-type-desktop; then
        echo -e "\tSkipping fail2ban and sshd files (desktop install)"
    else
        deploy-runtime-conf-file "/etc/fail2ban/jail.d/00-global.local"
        deploy-runtime-conf-file "/etc/fail2ban/jail.d/sshd.local"
        deploy-runtime-conf-file "/etc/ssh/sshd_config.d/20-podshift-access.conf"
        deploy-runtime-conf-file "/etc/ssh/sshd_config.d/50-podshift-auth.conf"
    fi
    print-step-ok
}
