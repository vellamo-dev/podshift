#!/usr/bin/env bash
# @file: list-install-items.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Lists the items waiting in the quadlet source directory in install order.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_21B219C1EDBF:-}" ]]; then
    DIR_21B219C1EDBF="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_21B219C1EDBF
fi

# @description: Lists the items of the directory in install order: by type, then oldest first, then by name.
# @details:
#   Lists the non-hidden files and folders of the directory, one per line, in install order: single
#   files by type (.network, .volume, .image, .container), then bundle folders (.qdl-bundle), then
#   anything else. Inside each group the oldest comes first by modification time (in seconds), and
#   a tie is sorted by name. The collision suffix is ignored when the type is found.
# @arg: $1 - source directory.
# @stdout: the full path of each item, one per line. Nothing if the directory is empty.
# @exitcode: 0 if the directory was read (even if it is empty), 1 if it is not a directory.
list-install-items() {
    local source_dir path name rank mtime
    source_dir="${1-}"
    [[ -d "${source_dir}" ]] || return 1

    # shellcheck source=./get-original-name.sh
    declare -F get-original-name >/dev/null || source "${DIR_21B219C1EDBF}/get-original-name.sh"

    {
        while IFS= read -r -d '' path; do
            name="$(get-original-name "${path}")"
            rank=9
            if [[ -d "${path}" ]]; then
                [[ "${name}" == *.qdl-bundle ]] && rank=5
            else
                case "${name}" in
                    *.network) rank=1 ;;
                    *.volume) rank=2 ;;
                    *.image) rank=3 ;;
                    *.container) rank=4 ;;
                esac
            fi
            # GNU stat first, BSD stat second, so it also runs on a Mac.
            mtime="$(stat -c %Y -- "${path}" 2>/dev/null || stat -f %m -- "${path}" 2>/dev/null || echo 0)"
            printf '%s\t%s\t%s\n' "${rank}" "${mtime}" "${path}"
        done < <(find "${source_dir}" -mindepth 1 -maxdepth 1 \( -type f -o -type d \) ! -name '.*' -print0)
    } | LC_ALL=C sort -t $'\t' -k1,1n -k2,2n -k3,3 | cut -f3-
    return 0
}
