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
#   fills the TSV variables, and checks again that nothing of it is installed yet
#   (check-installed-item), since another item may have been installed after validation: the same
#   item already installed is unchanged and the original goes to trash, any other clash fails. Then
#   it runs the dry run and installs it with Podman, never with --replace. If that worked, it
#   starts the units, then moves the original item from source to <backup>/<timestamp>/source and
#   the filled copy to <backup>/<timestamp>/installed. If a bundle fails to install, the partly
#   installed application is removed with remove-app (the check made sure no older version was
#   there). If any step before the start failed, the original item is moved from source to the
#   failed directory. Each item gets one try. Either way staging is emptied at the end and the
#   original has left source. Starting never waits and never fails the install: a unit that fails
#   to start is only logged as an error.
# @arg: $1 - item in the source directory (file or bundle folder).
# @arg: $2 - staging directory.
# @arg: $3 - directory where Podman installs quadlets.
# @arg: $4 - installed-backup directory.
# @arg: $5 - failed directory.
# @arg: $6 - trash directory, for an item that is already installed unchanged.
# @stdout: a short reason when the item was not installed and the reason is known, one line.
# @exitcode: 0 if installed, 1 if the item failed, 2 if the same item was already installed (unchanged).
install-item() {
    local item staging_dir quadlets_dir backup_dir failed_dir trash_dir base name staged stamp target failed app reason status
    item="${1}"
    staging_dir="${2}"
    quadlets_dir="${3}"
    backup_dir="${4}"
    failed_dir="${5}"
    trash_dir="${6-}"
    base="$(basename "${item}")"

    # shellcheck source=./get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_DE13369AAA9E}/get-original-name.sh"
    # shellcheck source=./empty-staging-dir.sh
    declare -F empty-staging-dir >/dev/null || source "${DIR_DE13369AAA9E}/empty-staging-dir.sh"
    # shellcheck source=./fill-staged-item.sh
    declare -F fill-staged-item >/dev/null || source "${DIR_DE13369AAA9E}/fill-staged-item.sh"
    # shellcheck source=./check-installed-item.sh
    declare -F check-installed-item >/dev/null || source "${DIR_DE13369AAA9E}/check-installed-item.sh"
    # shellcheck source=./dry-run-quadlet.sh
    declare -F dry-run-quadlet >/dev/null || source "${DIR_DE13369AAA9E}/dry-run-quadlet.sh"
    # shellcheck source=./install-quadlet.sh
    declare -F install-quadlet >/dev/null || source "${DIR_DE13369AAA9E}/install-quadlet.sh"
    # shellcheck source=./get-app-name.sh
    declare -F get-app-name >/dev/null || source "${DIR_DE13369AAA9E}/get-app-name.sh"
    # shellcheck source=./remove-app.sh
    declare -F remove-app >/dev/null || source "${DIR_DE13369AAA9E}/remove-app.sh"
    # shellcheck source=./start-quadlet.sh
    declare -F start-quadlet >/dev/null || source "${DIR_DE13369AAA9E}/start-quadlet.sh"
    # shellcheck source=./move-file.sh
    declare -F move-file >/dev/null || source "${DIR_DE13369AAA9E}/move-file.sh"

    name="$(get-original-name "${item}")"
    staged="${staging_dir}/${name}"
    app=""
    [[ -d "${item}" ]] && app="$(get-app-name "${item}")"
    logger -t podshift-qdl-install -p info "installing ${base}"

    failed=0
    reason=""
    if ! empty-staging-dir "${staging_dir}"; then
        logger -t podshift-qdl-install -p err "failed to empty the staging directory"
        failed=1
    elif ! cp -R -- "${item}" "${staged}"; then
        logger -t podshift-qdl-install -p err "failed to copy ${base} to staging"
        failed=1
    elif ! fill-staged-item "${staged}"; then
        failed=1
    else
        # Second check: something with these names may have been installed since validation.
        reason="$(check-installed-item "${staged}" "${quadlets_dir}" "${app}")" && status=0 || status=$?
        if (( status == 2 )); then
            logger -t podshift-qdl-install -p info "${name} is already installed with the same content"
            move-file "${item}" "${trash_dir}" podshift-qdl-install || move-file "${item}" "${failed_dir}" podshift-qdl-install
            empty-staging-dir "${staging_dir}"
            return 2
        elif (( status != 0 )); then
            logger -t podshift-qdl-install -p err "${reason}"
            failed=1
        elif ! dry-run-quadlet "${staging_dir}" "${quadlets_dir}"; then
            failed=1
        elif ! install-quadlet "${staged}"; then
            failed=1
            # A bundle can be installed in part: remove the new application again.
            [[ -n "${app}" ]] && remove-app "${app}" "${quadlets_dir}"
        fi
    fi

    if (( failed != 0 )); then
        logger -t podshift-qdl-install -p warn "failed to install ${base}"
        move-file "${item}" "${failed_dir}" podshift-qdl-install
        empty-staging-dir "${staging_dir}"
        [[ -z "${reason}" ]] || printf '%s\n' "${reason}"
        return 1
    fi

    start-quadlet "${staged}" || logger -t podshift-qdl-install -p err "${name} is installed, but not every unit started"

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
