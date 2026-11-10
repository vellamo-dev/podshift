#!/usr/bin/env bash
# @file: show-markdown.sh
# @source-dir: src/test/cli/shared/fn/output
# @group: test
# @category: helper
# @description: Shows a markdown file with glow.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Shows a markdown file with glow, TST_GLOW_WIDTH wide.
# @details:
#   Interactive mode uses glow's normal style. Plain mode uses the notty style, without colors or
#   link codes, and trims trailing spaces.
# @arg: $1 - the output mode: interactive or plain.
# @arg: $2 - the markdown file.
# @stdout: the rendered file.
# @stderr: why it cannot be shown.
# @exitcode: 0 if shown, 1 if the file is missing, 3 if glow is not installed.
show-markdown() {
    local mode file
    mode="${1}"
    file="${2}"
    [[ -f "${file}" ]] || { echo "File not found: ${file}" >&2; return 1; }
    if ! command -v glow >/dev/null 2>&1; then
        echo "glow not found" >&2
        echo "Fix: ${TST_INSTALL_CMD} glow" >&2
        return 3
    fi
    if [[ "${mode}" == "interactive" ]]; then
        glow -s auto -w "${TST_GLOW_WIDTH}" "${file}"
        return
    fi
    # notty still writes terminal link codes (ESC ] 8 ... BEL), so remove them too.
    glow -s notty -w "${TST_GLOW_WIDTH}" "${file}" | LC_ALL=C sed -E -e $'s/\e\\]8;[^\a\e]*(\a|\e\\\\)//g' -e 's/[[:space:]]*$//'
}
