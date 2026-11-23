#!/usr/bin/env bash
# @file: hcl.sh
# @source-dir: src/server/opt/podshift/fn/session
# @dest-dir: /opt/podshift/fn/session
# @host-edit: no
# @group: session
# @category: helper
# @description: Defines hcl, which clears the bash command history.
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
