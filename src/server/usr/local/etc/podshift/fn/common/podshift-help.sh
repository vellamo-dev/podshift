#!/usr/bin/env bash
# podshift-help.sh
# /usr/local/etc/podshift/fn/common

if [[ -z "${DIR_A6D8F81179BE:-}" ]]; then
    DIR_A6D8F81179BE="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A6D8F81179BE
fi

podshift-help() {
    local path_doc_root doc_id path_md_file path_txt_file
    doc_id="${1}"
    [[ -z "${doc_id}" ]] && doc_id="help-usage-guide"
    # Strip any directory component to prevent escaping the help directory
    doc_id="${doc_id##*/}"
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

# Executes only when a real argument (doc_id) is provided
[[ -n "${1}" ]] && podshift-help "${1}"
