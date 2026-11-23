#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-remove
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-remove
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Quadlet remove module: queues the removal of one installed Quadlet file or app.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_5CE8BE00E075:-}" ]]; then
    DIR_5CE8BE00E075="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_5CE8BE00E075
fi

# @description: Checks one removal request and writes it to the remove queue for the podshift-qdl-remove service.
# @details:
#   Runs in the podshift realm. args are {name, volumes}. list-quadlet-item-files resolves the name:
#   a name with a Quadlet extension (.container, .network, .volume, .pod, .image, .build, .kube) is
#   a single file at the top of PODSHIFT_PODMAN_QUADLETS_DIR, any other valid app name
#   (is-valid-app-name) an app folder there.
#   It is refused with NOT_FOUND when it is not installed, and with IN_USE when another installed
#   Quadlet refers to it (find-quadlet-users). The removal itself can take longer than the 10
#   second module bound, so it is only queued: a file named like the request, holding volumes=1 or
#   volumes=0, is moved into PODSHIFT_QUADLET_REMOVE_QUEUE_DIR with mv -n; a request already
#   waiting, or one the service is still removing (its .removing.<name> marker), is BUSY. On
#   success "queued removal of <name>" is logged with the podshift-qdl-remove tag, and the service
#   logs each step there later; the install log shows them. A removal is not a drop, so nothing
#   goes to the drop history.
# @arg: $1 - action arguments as one JSON object with name and optional volumes.
# @stdout: one JSON object {name, ok} plus error and message when refused.
# @exitcode: 0 when the result was written, 1 when the arguments cannot be read or a write fails.
cockpit-module-quadlet-remove() {
    local args name volumes queue_dir quadlets_dir path users tmp target listed listed_rc file
    local -a names
    args="${1-}"
    # shellcheck source=../../fn/drop/cockpit-quadlet-drop-result.sh
    declare -F cockpit-quadlet-drop-result >/dev/null || source "${DIR_5CE8BE00E075}/../../fn/drop/cockpit-quadlet-drop-result.sh"
    # shellcheck source=../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_5CE8BE00E075}/../../../../fn/load-podshift-conf-main.sh"
    # shellcheck source=../../../../fn/quadlet/list-quadlet-item-files.sh
    declare -F list-quadlet-item-files >/dev/null || source "${DIR_5CE8BE00E075}/../../../../fn/quadlet/list-quadlet-item-files.sh"
    # shellcheck source=../../../../fn/quadlet/find-quadlet-users.sh
    declare -F find-quadlet-users >/dev/null || source "${DIR_5CE8BE00E075}/../../../../fn/quadlet/find-quadlet-users.sh"
    name="$(printf '%s' "${args}" | jq -r '.name // empty' 2>/dev/null)" || return 1
    volumes="$(printf '%s' "${args}" | jq -r 'if .volumes == true then 1 else 0 end' 2>/dev/null)" || return 1
    load-podshift-conf-main 2>/dev/null || true
    queue_dir="${PODSHIFT_QUADLET_REMOVE_QUEUE_DIR:-}"
    quadlets_dir="${PODSHIFT_PODMAN_QUADLETS_DIR:-}"
    if [[ -z "${queue_dir}" || -z "${quadlets_dir}" || ! -d "${queue_dir}" || -L "${queue_dir}" ]]; then
        cockpit-quadlet-drop-result "${name}" $'REMOVE_UNAVAILABLE\tThe remove queue folder is missing.'
        return
    fi

    path="${quadlets_dir}/${name}"
    listed="$(list-quadlet-item-files "${quadlets_dir}" "${name}")" && listed_rc=0 || listed_rc=$?
    case "${listed_rc}" in
        0) ;;
        1)
            cockpit-quadlet-drop-result "${name}" $'NOT_FOUND\tThis Quadlet file is not installed.'
            return
            ;;
        2)
            cockpit-quadlet-drop-result "${name}" $'NOT_FOUND\tThis app is not installed.'
            return
            ;;
        *)
            cockpit-quadlet-drop-result "${name}" $'INVALID_NAME\tThe name must be an installed Quadlet file name or app name.'
            return
            ;;
    esac
    names=()
    while IFS= read -r file; do
        [[ -z "${file}" ]] || names+=("${file##*/}")
    done <<<"${listed}"
    users="$(find-quadlet-users "${quadlets_dir}" "${path}" "${names[@]}")" || users=""
    if [[ -n "${users}" ]]; then
        cockpit-quadlet-drop-result "${name}" "IN_USE"$'\t'"used by $(printf '%s' "${users}" | tr '\n' ' ' | sed 's/ $//')"
        return
    fi

    target="${queue_dir}/${name}"
    # A request that the service is working on is a hidden .removing.<name> marker until remove-item returns.
    if [[ -e "${target}" || -L "${target}" || -e "${queue_dir}/.removing.${name}" ]]; then
        cockpit-quadlet-drop-result "${name}" $'BUSY\tA removal of this name is already waiting.'
        return
    fi
    tmp="$(mktemp "${queue_dir}/.request.XXXXXX" 2>/dev/null)" || return 1
    if ! printf 'volumes=%s\n' "${volumes}" > "${tmp}" || ! chmod 0644 "${tmp}" 2>/dev/null; then
        rm -f -- "${tmp}"
        return 1
    fi
    mv -n -- "${tmp}" "${target}" 2>/dev/null || true
    if [[ -e "${tmp}" ]]; then
        rm -f -- "${tmp}"
        cockpit-quadlet-drop-result "${name}" $'BUSY\tA removal of this name is already waiting.'
        return
    fi
    logger -t podshift-qdl-remove -p info "queued removal of ${name}" 2>/dev/null || true
    cockpit-quadlet-drop-result "${name}"
}
