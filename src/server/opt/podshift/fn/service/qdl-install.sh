#!/usr/bin/env bash
# @file: qdl-install.sh
# @source-dir: src/server/opt/podshift/fn/service
# @dest-dir: /opt/podshift/fn/service
# @host-edit: no
# @group: service
# @category: entry
# @description: Installs the quadlets waiting in the PodShift source directory as user units.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# shellcheck source=../../../../usr/lib/systemd/user/podshift-qdl-install.service

if [[ -z "${DIR_CC70FC6018EB:-}" ]]; then
    DIR_CC70FC6018EB="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_CC70FC6018EB
fi

# @description: Installs every item in the source directory with install-item, in the order of list-install-items.
# @details:
#   An item is a quadlet file or a .qdl-bundle folder. The TSV_ values (tsv.conf, runtime.conf,
#   TSV_NW1..8) are loaded first, so the ${TSV_NAME} variables can be filled. An item that installs
#   goes to installed-backup, one that fails goes to failed.
# @exitcode: 0 always (non-fatal).
podshift-qdl-install() {
    local source_dir staging_dir backup_dir failed_dir quadlets_dir item
    local -a items

    # Load and export the PodShift configuration.
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_CC70FC6018EB}/../load-podshift-conf-main.sh"
    load-podshift-conf-main

    source_dir="${PODSHIFT_QUADLET_SOURCE_DIR:-}"
    staging_dir="${PODSHIFT_QUADLET_STAGING_DIR:-}"
    backup_dir="${PODSHIFT_QUADLET_INSTALLED_BACKUP_DIR:-}"
    failed_dir="${PODSHIFT_QUADLET_FAILED_DIR:-}"
    quadlets_dir="${PODSHIFT_PODMAN_QUADLETS_DIR:-}"

    if [[ -z "${source_dir}" || -z "${staging_dir}" || -z "${backup_dir}" || -z "${failed_dir}" || -z "${quadlets_dir}" ]]; then
        logger -t podshift-qdl-install -p err "source, staging, installed-backup, failed, or quadlets directory is not configured"
        return 0
    fi

    if [[ ! -d "${source_dir}" ]]; then
        logger -t podshift-qdl-install -p warn "source directory missing: ${source_dir}"
        return 0
    fi

    # Load the TSV_ values (tsv.conf, runtime.conf, then TSV_NW1..8).
    # shellcheck source=../load-podshift-conf-nw.sh
    declare -F load-podshift-conf-nw >/dev/null || source "${DIR_CC70FC6018EB}/../load-podshift-conf-nw.sh"
    load-podshift-conf-nw

    # shellcheck source=../quadlet/list-install-items.sh
    declare -F list-install-items >/dev/null || source "${DIR_CC70FC6018EB}/../quadlet/list-install-items.sh"
    mapfile -t items < <(list-install-items "${source_dir}")

    # shellcheck source=../quadlet/install-item.sh
    declare -F install-item >/dev/null || source "${DIR_CC70FC6018EB}/../quadlet/install-item.sh"
    for item in "${items[@]}"; do
        install-item "${item}" "${staging_dir}" "${quadlets_dir}" "${backup_dir}" "${failed_dir}"
    done

    return 0
}

# Executes only when run directly (systemd ExecStart)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && podshift-qdl-install
