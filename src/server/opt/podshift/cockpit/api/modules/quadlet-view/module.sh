#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-view
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-view
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Quadlet view module: prints the Quadlet file that one podshift user service was generated from.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_9E41C7A2D5B8:-}" ]]; then
    DIR_9E41C7A2D5B8="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_9E41C7A2D5B8
fi

# shellcheck source=../../fn/services/cockpit-services-args.sh
declare -F cockpit-services-args >/dev/null || source "${DIR_9E41C7A2D5B8}/../../fn/services/cockpit-services-args.sh"
# shellcheck source=../../fn/services/cockpit-services-loaded.sh
declare -F cockpit-services-loaded >/dev/null || source "${DIR_9E41C7A2D5B8}/../../fn/services/cockpit-services-loaded.sh"
# shellcheck source=../../fn/quadlets/cockpit-quadlet-view-path.sh
declare -F cockpit-quadlet-view-path >/dev/null || source "${DIR_9E41C7A2D5B8}/../../fn/quadlets/cockpit-quadlet-view-path.sh"
# shellcheck source=../../fn/quadlets/cockpit-quadlet-view-result.sh
declare -F cockpit-quadlet-view-result >/dev/null || source "${DIR_9E41C7A2D5B8}/../../fn/quadlets/cockpit-quadlet-view-result.sh"

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code.
cockpit-quadlet-view-systemctl() {
    systemctl --user "$@"
}

# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @details:
#   Uses PODSHIFT_PODMAN_QUADLETS_DIR, usually /home/podshift/.config/containers/systemd, where
#   podman quadlet install puts the files. When main.conf does not set it, the default
#   ~/.config/containers/systemd of the current (podshift) user is used.
# @stdout: the directory path, or nothing when it is not known.
# @exitcode: 0 always.
cockpit-quadlet-view-dir() {
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        # shellcheck source=../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_9E41C7A2D5B8}/../../../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main 2>/dev/null || true
    fi
    if [[ -n "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        printf '%s\n' "${PODSHIFT_PODMAN_QUADLETS_DIR}"
    elif [[ -n "${HOME:-}" ]]; then
        printf '%s\n' "${HOME}/.config/containers/systemd"
    fi
    return 0
}

# @description: Prints the Quadlet file that one loaded user service of the podshift user was generated from.
# @details:
#   The unit is checked by cockpit-services-args and must be one of the loaded units of
#   systemctl --user list-units --type=service --all (cockpit-services-loaded); else the result is
#   found false. systemctl --user show --property=SourcePath --value gives the file Quadlet read.
#   cockpit-quadlet-view-path checks that it is a Quadlet file (else NOT_QUADLET) in the Quadlet
#   folder of cockpit-quadlet-view-dir (else OUTSIDE_QUADLET_DIR). A file that is missing or not a
#   regular file is FILE_NOT_FOUND. A symlink, or a file whose real folder is not inside the real
#   Quadlet folder, is OUTSIDE_QUADLET_DIR. A file that cannot be read is FILE_UNREADABLE. The
#   text is returned by cockpit-quadlet-view-result with the 131072-byte module output bound, so a
#   longer file gives tooLarge and size. Quadlet files name secrets but never hold their values.
#   The process runs in the podshift session, so the files are read as that user.
# @arg: $1 - action arguments as one JSON object with unit.
# @stdout: one JSON object {unit, found} plus quadlet, and error, or name, path, kind and text or tooLarge and size.
# @exitcode: 0 when the result was written, 1 when the arguments are refused or systemctl fails.
cockpit-module-quadlet-view() {
    local parsed unit raw src_path dir kind rc real_dir file_dir text
    parsed="$(cockpit-services-args "${1-}" no)" || return 1
    unit="${parsed%%$'\t'*}"
    raw="$(cockpit-quadlet-view-systemctl list-units --type=service --all --plain --no-legend --no-pager 2>/dev/null)" || return 1
    if ! cockpit-services-loaded "${raw}" | cut -f 1 | grep -F -x -q -- "${unit}"; then
        cockpit-quadlet-view-result "${unit}" missing "" "" 131072
        return
    fi
    src_path="$(cockpit-quadlet-view-systemctl show --property=SourcePath --value -- "${unit}" 2>/dev/null)" || return 1
    dir="$(cockpit-quadlet-view-dir)"
    kind="$(cockpit-quadlet-view-path "${src_path}" "${dir}")" && rc=0 || rc=$?
    case "${rc}" in
        0) ;;
        2)
            cockpit-quadlet-view-result "${unit}" OUTSIDE_QUADLET_DIR "${src_path}" "${kind}" 131072
            return
            ;;
        *)
            cockpit-quadlet-view-result "${unit}" NOT_QUADLET "" "" 131072
            return
            ;;
    esac
    if [[ -L "${src_path}" ]]; then
        cockpit-quadlet-view-result "${unit}" OUTSIDE_QUADLET_DIR "${src_path}" "${kind}" 131072
        return
    fi
    if [[ ! -f "${src_path}" ]]; then
        cockpit-quadlet-view-result "${unit}" FILE_NOT_FOUND "${src_path}" "${kind}" 131072
        return
    fi
    real_dir="$(CDPATH='' cd -P -- "${dir}" 2>/dev/null && pwd -P)" || real_dir=""
    file_dir="$(CDPATH='' cd -P -- "$(dirname -- "${src_path}")" 2>/dev/null && pwd -P)" || file_dir=""
    if [[ -z "${real_dir}" || -z "${file_dir}" || "${file_dir}/" != "${real_dir}/"* ]]; then
        cockpit-quadlet-view-result "${unit}" OUTSIDE_QUADLET_DIR "${src_path}" "${kind}" 131072
        return
    fi
    # The x keeps trailing newlines; the subshell still exits with the cat code.
    if [[ ! -r "${src_path}" ]] || ! text="$(cat -- "${src_path}" 2>/dev/null; rc=$?; printf x; exit "${rc}")"; then
        cockpit-quadlet-view-result "${unit}" FILE_UNREADABLE "${src_path}" "${kind}" 131072
        return
    fi
    text="${text%x}"
    printf '%s' "${text}" | cockpit-quadlet-view-result "${unit}" ok "${src_path}" "${kind}" 131072
}
