#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-drop
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-drop
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Quadlet drop module: writes one uploaded Quadlet file or .zip bundle into the drop directory.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3CC93FB67063:-}" ]]; then
    DIR_3CC93FB67063="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3CC93FB67063
fi

# @description: Checks one upload, writes it to the web-upload folder and moves it into the drop directory.
# @details:
#   Runs in the podshift realm. args are {name, content}; content is always base64. The name is
#   checked by cockpit-quadlet-drop-name. The decoded file must not be empty and not larger than
#   PODSHIFT_DROP_MAX_BUNDLE_SIZE KB, for a Quadlet file and a .zip alike; without that limit the
#   upload is refused with DROP_UNAVAILABLE. It is written to a temp
#   file in PODSHIFT_QUADLET_WEB_UPLOAD_DIR, set to mode 0644, and moved into PODSHIFT_DROP_DIR
#   with mv -n (a rename, as both are under /home/podshift) only when it is owned by
#   podshift:podshift with mode 644. A name already in the drop directory is refused with
#   NAME_BUSY: a suffix after the extension would send the file to trash and one before it would
#   rename the Quadlet. Every refusal removes the temp file. On success "uploaded <name> to the
#   drop folder" is logged with the podshift-qdl-upload tag and the result is {name, ok: true},
#   with the name in the drop directory. Nothing goes to the drop history here: drop-process gives
#   the file its drop ID and logs it as accepted.
# @arg: $1 - action arguments as one JSON object with name and content.
# @stdout: one JSON object {name, ok} plus error and message when refused.
# @exitcode: 0 when the result was written, 1 when the arguments cannot be read or a write fails.
cockpit-module-quadlet-drop() {
    local args name content problem upload_dir drop_dir max_kb tmp size meta target
    # shellcheck source=./fn/cockpit-quadlet-drop-refuse.sh
    declare -F cockpit-quadlet-drop-refuse >/dev/null || source "${DIR_3CC93FB67063}/fn/cockpit-quadlet-drop-refuse.sh"
    # shellcheck source=./fn/cockpit-quadlet-drop-file-meta.sh
    declare -F cockpit-quadlet-drop-file-meta >/dev/null || source "${DIR_3CC93FB67063}/fn/cockpit-quadlet-drop-file-meta.sh"
    args="${1-}"
    # shellcheck source=../../fn/config/cockpit-config-arg.sh
    declare -F cockpit-config-arg >/dev/null || source "${DIR_3CC93FB67063}/../../fn/config/cockpit-config-arg.sh"
    # shellcheck source=../../fn/drop/cockpit-quadlet-drop-name.sh
    declare -F cockpit-quadlet-drop-name >/dev/null || source "${DIR_3CC93FB67063}/../../fn/drop/cockpit-quadlet-drop-name.sh"
    # shellcheck source=../../fn/drop/cockpit-quadlet-drop-result.sh
    declare -F cockpit-quadlet-drop-result >/dev/null || source "${DIR_3CC93FB67063}/../../fn/drop/cockpit-quadlet-drop-result.sh"
    # shellcheck source=../../../../fn/load-podshift-conf-main.sh
    declare -F load-podshift-conf-main >/dev/null || source "${DIR_3CC93FB67063}/../../../../fn/load-podshift-conf-main.sh"
    name="$(cockpit-config-arg "${args}" name)" || return 1
    content="$(cockpit-config-arg "${args}" content)" || return 1
    load-podshift-conf-main 2>/dev/null || true
    if ! problem="$(cockpit-quadlet-drop-name "${name}" "${PODSHIFT_DROP_QUADLET_EXTENSIONS:-}")"; then
        cockpit-quadlet-drop-refuse "" "${name}" "${problem}"
        return
    fi
    upload_dir="${PODSHIFT_QUADLET_WEB_UPLOAD_DIR:-}"
    drop_dir="${PODSHIFT_DROP_DIR:-}"
    max_kb="${PODSHIFT_DROP_MAX_BUNDLE_SIZE:-}"
    if [[ ! "${max_kb}" =~ ^[0-9]+$ ]]; then
        logger -t podshift-api -p err "PODSHIFT_DROP_MAX_BUNDLE_SIZE is not set to a whole number" 2>/dev/null || true
        cockpit-quadlet-drop-refuse "" "${name}" $'DROP_UNAVAILABLE\tThe drop size limit is not set.'
        return
    fi
    if [[ -z "${upload_dir}" || -z "${drop_dir}" || ! -d "${upload_dir}" || -L "${upload_dir}" || ! -d "${drop_dir}" ]]; then
        cockpit-quadlet-drop-refuse "" "${name}" $'DROP_UNAVAILABLE\tThe upload or drop folder is missing.'
        return
    fi
    if (( ${#content} % 4 != 0 )) || [[ "${content}" == *[!ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/=]* ]]; then
        cockpit-quadlet-drop-refuse "" "${name}" $'INVALID_CONTENT\tThe content must be base64.'
        return
    fi
    tmp="$(mktemp "${upload_dir}/upload.XXXXXX" 2>/dev/null)" || return 1
    if ! printf '%s' "${content}" | base64 -d > "${tmp}" 2>/dev/null; then
        cockpit-quadlet-drop-refuse "${tmp}" "${name}" $'INVALID_CONTENT\tThe content must be base64.'
        return
    fi
    size="$(LC_ALL=C wc -c < "${tmp}" | tr -d '[:space:]')"
    if [[ -z "${size}" || "${size}" == "0" ]]; then
        cockpit-quadlet-drop-refuse "${tmp}" "${name}" $'EMPTY_FILE\tThe file is empty.'
        return
    fi
    if (( size > max_kb * 1024 )); then
        cockpit-quadlet-drop-refuse "${tmp}" "${name}" "TOO_LARGE"$'\t'"The file is larger than ${max_kb} KB."
        return
    fi
    if ! chmod 0644 "${tmp}" 2>/dev/null; then
        rm -f -- "${tmp}"
        return 1
    fi
    meta="$(cockpit-quadlet-drop-file-meta "${tmp}")" || meta=""
    if [[ "${meta}" != "podshift podshift 644" ]]; then
        cockpit-quadlet-drop-refuse "${tmp}" "${name}" $'WRONG_OWNER\tThe upload was not owned by podshift:podshift with mode 0644, so it was not moved.'
        return
    fi
    target="${drop_dir}/${name}"
    if [[ ! -e "${target}" && ! -L "${target}" ]]; then
        mv -n -- "${tmp}" "${target}" 2>/dev/null || true
    fi
    if [[ -e "${tmp}" ]]; then
        cockpit-quadlet-drop-refuse "${tmp}" "${name}" $'NAME_BUSY\tA file with this name is still waiting in the drop folder. Try again in a few seconds.'
        return
    fi
    [[ -f "${target}" ]] || return 1
    logger -t podshift-qdl-upload -p info "uploaded ${name} to the drop folder" 2>/dev/null || true
    cockpit-quadlet-drop-result "${name}"
}
