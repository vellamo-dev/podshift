#!/usr/bin/env bash
# @file: podshift-help.sh
# @source-dir: src/server/opt/podshift/fn/common
# @dest-dir: /opt/podshift/fn/common
# @host-edit: no
# @group: common
# @category: helper
# @description: Renders PodShift help documents.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_A6D8F81179BE:-}" ]]; then
    DIR_A6D8F81179BE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A6D8F81179BE
fi

# @description: Renders the help document for the given id (Markdown via glow, plain text via cat).
# @details:
#   Markdown is shown with glow when stdout is a terminal and glow is installed. If stdout is not a
#   terminal, or glow is missing, the file is printed as is with cat. Glow writes nothing when
#   stdout is not a terminal. Plain text files are always printed with cat.
# @arg: $1 - document id (defaults to podshift, the main help as plain text)
# @exitcode: 0 on success, 1 if the document id is unknown.
podshift-help() {
    local path_doc_root doc_id path_md_file path_txt_file
    doc_id="${1}"
    [[ -z "${doc_id}" ]] && doc_id="podshift"
    # Strip any directory component to prevent escaping the help directory
    doc_id="${doc_id##*/}"
    if [[ "${doc_id}" == "podshift" ]]; then
        # shellcheck source=./podshift-help-main.sh
        declare -F podshift-help-main >/dev/null || source "${DIR_A6D8F81179BE}/podshift-help-main.sh"
        podshift-help-main
        return
    fi
    # shellcheck source=../../doc/help
    path_doc_root="${DIR_A6D8F81179BE}/../../doc/help"
    path_md_file="${path_doc_root}/${doc_id}.md"
    path_txt_file="${path_doc_root}/${doc_id}.txt"
    if [[ -f "${path_md_file}" ]]; then
        # Glow writes nothing when stdout is not a terminal.
        if [[ ! -t 1 ]] || ! command -v glow >/dev/null 2>&1; then
            cat "${path_md_file}"
        else
            glow "${path_md_file}"
        fi
        return
    fi
    if [[ -f "${path_txt_file}" ]]; then
        cat "${path_txt_file}"
        return
    fi
    echo "Unknown command. An invalid id '${doc_id}' provided." >&2
    return 1
}
