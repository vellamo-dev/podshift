#!/usr/bin/env bash
# @file: install-item.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Installs one item (a quadlet file or a bundle folder) from the quadlet source directory.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_DE13369AAA9E:-}" ]]; then
    DIR_DE13369AAA9E="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DE13369AAA9E
fi

# @description: Stages, fills, checks, installs and starts one item, then moves it out of the source directory.
# @details:
#   Empties staging, copies the item there under its original name (the collision suffix removed),
#   fills the TSV variables, runs the dry run, warns about unit files named like ones installed
#   elsewhere (warn-duplicate-units, it never blocks), and installs it with Podman. If that worked,
#   it starts the units (restarts them if the item replaced an installed one), then moves the
#   original item from source to <backup>/<timestamp>/source and the filled copy to
#   <backup>/<timestamp>/installed. If a bundle fails to install, the whole application is removed
#   with remove-app, because Podman installs a bundle file by file (a replaced older version is
#   gone too; its copy is in the backup). If any step before the start failed, the original item is
#   moved from source to the failed directory. Either way staging is emptied at the end and the
#   original has left source. Starting never waits and never fails the install: a unit that fails
#   to start is only logged as an error.
# @arg: $1 - item in the source directory (file or bundle folder).
# @arg: $2 - staging directory.
# @arg: $3 - directory where Podman installs quadlets.
# @arg: $4 - installed-backup directory.
# @arg: $5 - failed directory.
# @exitcode: 0 if installed, 1 if the item failed.
install-item() {
    local item staging_dir quadlets_dir backup_dir failed_dir base name staged stamp target failed replaced install_status
    item="${1}"
    staging_dir="${2}"
    quadlets_dir="${3}"
    backup_dir="${4}"
    failed_dir="${5}"
    base="$(basename "${item}")"

    # shellcheck source=./get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_DE13369AAA9E}/get-original-name.sh"
    # shellcheck source=./empty-staging-dir.sh
    declare -F empty-staging-dir >/dev/null || source "${DIR_DE13369AAA9E}/empty-staging-dir.sh"
    # shellcheck source=./fill-staged-item.sh
    declare -F fill-staged-item >/dev/null || source "${DIR_DE13369AAA9E}/fill-staged-item.sh"
    # shellcheck source=./dry-run-quadlet.sh
    declare -F dry-run-quadlet >/dev/null || source "${DIR_DE13369AAA9E}/dry-run-quadlet.sh"
    # shellcheck source=./install-quadlet.sh
    declare -F install-quadlet >/dev/null || source "${DIR_DE13369AAA9E}/install-quadlet.sh"
    # shellcheck source=./get-app-name.sh
    declare -F get-app-name >/dev/null || source "${DIR_DE13369AAA9E}/get-app-name.sh"
    # shellcheck source=./remove-app.sh
    declare -F remove-app >/dev/null || source "${DIR_DE13369AAA9E}/remove-app.sh"
    # shellcheck source=./warn-duplicate-units.sh
    declare -F warn-duplicate-units >/dev/null || source "${DIR_DE13369AAA9E}/warn-duplicate-units.sh"
    # shellcheck source=./start-quadlet.sh
    declare -F start-quadlet >/dev/null || source "${DIR_DE13369AAA9E}/start-quadlet.sh"
    # shellcheck source=./move-file.sh
    declare -F move-file >/dev/null || source "${DIR_DE13369AAA9E}/move-file.sh"

    name="$(get-original-name "${item}")"
    staged="${staging_dir}/${name}"
    logger -t podshift-qdl-install -p info "installing ${base}"

    failed=0
    replaced=0
    if ! empty-staging-dir "${staging_dir}"; then
        logger -t podshift-qdl-install -p err "failed to empty the staging directory"
        failed=1
    elif ! cp -R -- "${item}" "${staged}"; then
        logger -t podshift-qdl-install -p err "failed to copy ${base} to staging"
        failed=1
    elif ! fill-staged-item "${staged}"; then
        failed=1
    elif ! dry-run-quadlet "${staging_dir}" "${quadlets_dir}"; then
        failed=1
    else
        # A unit file with the name of one installed elsewhere only gets a warning.
        warn-duplicate-units "${staged}" "${quadlets_dir}"
        install-quadlet "${staged}" "${quadlets_dir}"
        install_status=$?
        if (( install_status == 1 )); then
            failed=1
            # A bundle can be installed in part: remove the whole application.
            if [[ -d "${staged}" ]]; then
                remove-app "$(get-app-name "${staged}")" "${quadlets_dir}"
            fi
        elif (( install_status == 2 )); then
            replaced=1
        fi
    fi

    if (( failed != 0 )); then
        logger -t podshift-qdl-install -p warn "failed to install ${base}"
        move-file "${item}" "${failed_dir}" podshift-qdl-install
        empty-staging-dir "${staging_dir}"
        return 1
    fi

    start-quadlet "${staged}" "${replaced}" || logger -t podshift-qdl-install -p err "${name} is installed, but not every unit started"

    stamp="$(date +%Y%m%d-%H%M%S-%N)"
    target="${backup_dir}/${stamp}"
    if mkdir -p "${target}/source" "${target}/installed" \
        && mv -- "${item}" "${target}/source/" \
        && mv -- "${staged}" "${target}/installed/"; then
        logger -t podshift-qdl-install -p info "backed up ${base} to $(basename "${backup_dir}")/${stamp}"
    else
        # The original must not stay in source, or the path watcher fires again.
        logger -t podshift-qdl-install -p err "failed to back up ${base}"
        [[ ! -e "${item}" ]] || move-file "${item}" "${failed_dir}" podshift-qdl-install
    fi
    empty-staging-dir "${staging_dir}"
    return 0
}
