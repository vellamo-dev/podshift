#!/usr/bin/env bash
# @file: is-tsv-config-name-sensitive.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Tells if a TSV_* name names a secret, by whole words from the tsv-rules.conf text.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Returns 0 when a whole word of the TSV_* name is a secret word from the rules text.
# @details:
#   The part after TSV_ is split on _. The name is a secret when one whole word is listed as
#   "word <WORD>" in the rules, or when a word is KEY and the word before it is listed as
#   "key-after <WORD>". Only whole words match, so TSV_PASSAGE, TSV_KEYBOARD and
#   TSV_TOKENIZER_MODEL are not secrets. Other rule lines are ignored.
# @arg: $1 - the TSV_* name.
# @arg: $2 - the text of tsv-rules.conf.
# @stdout: nothing.
# @exitcode: 0 if the name looks like a secret, 1 if not.
is-tsv-config-name-sensitive() {
    local key rules rest word previous line kind rule
    local -a words
    key="${1-}"
    rules="${2-}"
    rest="${key#TSV_}"
    IFS='_' read -r -a words <<< "${rest}"
    [[ "${#words[@]}" -gt 0 ]] || return 1
    previous=""
    for word in "${words[@]}"; do
        [[ -n "${word}" ]] || continue
        while IFS= read -r line; do
            kind="${line%% *}"
            rule="${line#* }"
            case "${kind}" in
                word)
                    [[ "${word}" == "${rule}" ]] && return 0
                    ;;
                key-after)
                    [[ "${word}" == "KEY" && -n "${previous}" && "${previous}" == "${rule}" ]] && return 0
                    ;;
            esac
        done <<< "${rules}"
        previous="${word}"
    done
    return 1
}
