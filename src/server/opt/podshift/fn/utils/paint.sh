#!/usr/bin/env bash
# @file: paint.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Prints text in a color, only when the output is interactive.
# @warning: The caller decides the mode once, while its output is still the terminal, and sets PODSHIFT_OUTPUT. Inside $(...) the output is never a terminal.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the text with the style's color when PODSHIFT_OUTPUT is interactive, otherwise as it is.
# @arg: $1 - style: ok, warn, fail, marker (bold magenta, for ▶), title (bold cyan, for header titles), dim or bold.
# @arg: $2 - the text.
# @stdout: the text, colored or plain, without a newline.
# @exitcode: 0 always.
paint() {
    local style text code
    style="${1}"
    text="${2}"
    if [[ "${PODSHIFT_OUTPUT:-plain}" != "interactive" ]]; then
        printf '%s' "${text}"
        return 0
    fi
    case "${style}" in
        ok)   code='1;32' ;;
        warn) code='1;33' ;;
        info) code='1;34' ;;
        fail) code='1;31' ;;
        marker) code='1;35' ;;
        title)  code='1;36' ;;
        dim)  code='2' ;;
        bold) code='1' ;;
        *)    code='0' ;;
    esac
    printf '\033[%sm%s\033[0m' "${code}" "${text}"
    return 0
}
