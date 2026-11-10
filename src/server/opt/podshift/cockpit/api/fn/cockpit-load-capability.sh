#!/usr/bin/env bash
# @file: cockpit-load-capability.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Reads the capability.json of a module named by the dispatch map.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reads capability.json from a module directory supplied by the dispatch map.
# @details:
#   The file must be a regular readable file of 1 to 65536 bytes. A symlink is refused.
# @arg: $1 - absolute module directory from the dispatch map.
# @stdout: the file bytes on success.
# @exitcode: 0 when the file was read, 1 when it is missing, unreadable, a symlink, empty, or larger than 65536 bytes.
cockpit-load-capability() {
    local module_dir file bytes
    module_dir="${1:-}"
    case "${module_dir}" in
        /*) ;;
        *) return 1 ;;
    esac
    case "${module_dir}" in
        *$'\n'*) return 1 ;;
    esac
    file="${module_dir}/capability.json"
    [[ -f "${file}" && ! -L "${file}" && -r "${file}" ]] || return 1
    bytes="$(stat -c '%s' "${file}" 2>/dev/null || stat -f '%z' "${file}" 2>/dev/null || true)"
    case "${bytes}" in
        ''|*[!0123456789]*) return 1 ;;
    esac
    # Fixed metadata bound: 65536 bytes.
    if (( bytes < 1 || bytes > 65536 )); then
        return 1
    fi
    cat -- "${file}"
}
