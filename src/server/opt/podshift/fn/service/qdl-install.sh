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
#   goes to installed-backup, one that fails goes to failed, and one that is already installed
#   unchanged goes to trash. Each step is also logged to the drop history under the drop ID of the
#   item (get-drop-id, from its first line, or from the files of a bundle folder). An item placed
#   in the source by hand without an ID gets a new one on every file (set-drop-id), so the ID line
#   goes into the installed copy too.
# @exitcode: 0 always (non-fatal).
podshift-qdl-install() {
    local source_dir staging_dir backup_dir failed_dir trash_dir quadlets_dir item history_name reason status id file
    local -a items files

    # Load and export the PodShift configuration.
    # shellcheck source=../load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_CC70FC6018EB}/../load-podshift-conf-main.sh"
    load-podshift-conf-main

    source_dir="${PODSHIFT_QUADLET_SOURCE_DIR:-}"
    staging_dir="${PODSHIFT_QUADLET_STAGING_DIR:-}"
    backup_dir="${PODSHIFT_QUADLET_INSTALLED_BACKUP_DIR:-}"
    failed_dir="${PODSHIFT_QUADLET_FAILED_DIR:-}"
    trash_dir="${PODSHIFT_TRASH_DIR:-}"
    quadlets_dir="${PODSHIFT_PODMAN_QUADLETS_DIR:-}"

    if [[ -z "${source_dir}" || -z "${staging_dir}" || -z "${backup_dir}" || -z "${failed_dir}" || -z "${trash_dir}" || -z "${quadlets_dir}" ]]; then
        logger -t podshift-qdl-install -p err "source, staging, installed-backup, failed, trash or quadlets directory is not configured"
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
    # shellcheck source=../quadlet/get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_CC70FC6018EB}/../quadlet/get-original-name.sh"
    # shellcheck source=../quadlet/log-drop-history.sh
    declare -F log-drop-history >/dev/null || source "${DIR_CC70FC6018EB}/../quadlet/log-drop-history.sh"
    # shellcheck source=../quadlet/get-drop-id.sh
    declare -F get-drop-id >/dev/null || source "${DIR_CC70FC6018EB}/../quadlet/get-drop-id.sh"
    # shellcheck source=../quadlet/set-drop-id.sh
    declare -F set-drop-id >/dev/null || source "${DIR_CC70FC6018EB}/../quadlet/set-drop-id.sh"
    # shellcheck source=../utils/new-uuid7.sh
    declare -F new-uuid7 >/dev/null || source "${DIR_CC70FC6018EB}/../utils/new-uuid7.sh"
    for item in "${items[@]}"; do
        # The history name is the dropped name: a bundle folder app.qdl-bundle was app.zip.
        history_name="$(get-original-name "${item}")"
        [[ "${history_name}" == *.qdl-bundle ]] && history_name="${history_name%.qdl-bundle}.zip"
        if ! id="$(get-drop-id "${item}")" && id="$(new-uuid7)"; then
            # Placed here by hand: every file gets the new ID. The list is read first, as
            # set-drop-id writes a temp file next to each file.
            mapfile -t files < <(find "${item}" -maxdepth 1 -type f | LC_ALL=C sort)
            for file in "${files[@]}"; do
                set-drop-id "${file}" "${id}" || logger -t podshift-qdl-install -p warn "could not set the drop ID on $(basename "${file}")"
            done
        fi
        log-drop-history "${id}" "${history_name}" installing "" "${item}"
        reason="$(install-item "${item}" "${staging_dir}" "${quadlets_dir}" "${backup_dir}" "${failed_dir}" "${trash_dir}")" && status=0 || status=$?
        case "${status}" in
            0) log-drop-history "${id}" "${history_name}" installed ;;
            2) log-drop-history "${id}" "${history_name}" unchanged ;;
            *) log-drop-history "${id}" "${history_name}" failed "${reason:-install failed, see the install log}" ;;
        esac
    done

    return 0
}

# Executes only when run directly (systemd ExecStart)
[[ "${BASH_SOURCE[0]}" == "${0}" ]] && podshift-qdl-install
