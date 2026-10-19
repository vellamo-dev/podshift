#!/usr/bin/env bash
# @file: make-rootless-remote-key.sh
# @dir: /usr/local/etc/podshift/fn/rootless
# @group: rootless
# @prefix: PS-PT
# @id: KEY
# @description: Creates the rootless remote SSH key pair for the podshift user.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_95A057375FBB:-}" ]]; then
    DIR_95A057375FBB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_95A057375FBB
fi

# @description: Creates the rootless remote SSH key pair for the podshift user.
# @exitcode: 0 always (non-fatal, failures are logged via logger).
make-rootless-remote-key() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-KEY"
    local podshift_rss_key_file podshift_ssh_dir epoch
    # shellcheck source=../utils/print-step.sh
    source "${DIR_95A057375FBB}/../utils/print-step.sh"

    podshift_rss_key_file="/home/podshift/.ssh/podshift_remote_rss"
    podshift_ssh_dir="$(dirname "${podshift_rss_key_file}")"
    epoch="$(date +%s)"

    print-step-header "${step_tag}" "Creating ssh key pair for rootless podman..."

    if [ -f "${podshift_rss_key_file}" ]; then
        print-step-skip "key already exists"
        return 0
    fi

    # shellcheck source=./set-owner-rootless.sh
    source "${DIR_95A057375FBB}/set-owner-rootless.sh"
    mkdir -p "${podshift_ssh_dir}" || logger -t podshift "failed to create ${podshift_ssh_dir}." || true
    ssh-keygen -t rsa -b 4096 -f "${podshift_rss_key_file}" -q -N "" -C "podshift-rss-${epoch}@${HOSTNAME}" \
        || logger -t podshift "failed to generate the rootless remote key." || true
    set-owner-rootless "${podshift_ssh_dir}" || logger -t podshift "failed to set ownership of ${podshift_ssh_dir}." || true
    chmod 700 "${podshift_ssh_dir}" || logger -t podshift "failed to set permissions on ${podshift_ssh_dir}." || true
    chmod 600 "${podshift_rss_key_file}" || logger -t podshift "failed to set permissions on ${podshift_rss_key_file}." || true

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && make-rootless-remote-key
fi
