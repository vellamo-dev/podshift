#!/usr/bin/env bash
# @file: session-helpers.sh
# @dir: /opt/podshift/fn/session
# @group: session
# @description: Defines shell session helpers (quit, hcl).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Clears the bash command history.
# @exitcode: 0 always.
hcl() {
    cat /dev/null >"${HISTFILE:-$HOME/.bash_history}"
    history -c
    history -r
}

# @description: Clears the bash command history and exits the shell.
quit() {
    hcl
    exit
}
