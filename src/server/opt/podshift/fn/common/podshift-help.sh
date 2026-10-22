#!/usr/bin/env bash
# @file: podshift-help.sh
# @dir: /opt/podshift/fn/common
# @group: common
# @description: Renders PodShift help documents.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_A6D8F81179BE:-}" ]]; then
    DIR_A6D8F81179BE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A6D8F81179BE
fi

# @description: Renders the help document for the given id (Markdown via glow, plain text via cat).
# @param: $1 - document id (defaults to help-usage-guide)
# @exitcode: 0 on success, 1 if the document id is unknown.
podshift-help() {
    local path_doc_root doc_id path_md_file path_txt_file
    doc_id="${1}"
    [[ -z "${doc_id}" ]] && doc_id="help-usage-guide"
    # Strip any directory component to prevent escaping the help directory
    doc_id="${doc_id##*/}"
    # shellcheck source=../../doc/help
    path_doc_root="${DIR_A6D8F81179BE}/../../doc/help"
    path_md_file="${path_doc_root}/${doc_id}.md"
    path_txt_file="${path_doc_root}/${doc_id}.txt"
    if [[ -f "${path_md_file}" ]]; then
        glow "${path_md_file}"
        return
    fi
    if [[ -f "${path_txt_file}" ]]; then
        cat "${path_txt_file}"
        return
    fi
    echo "Unknown command. An invalid id '${doc_id}' provided." >&2
    return 1
}

# Executes only when called or sourced with a document id
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ -n "${1}" ]] && podshift-help "${1}"
fi
