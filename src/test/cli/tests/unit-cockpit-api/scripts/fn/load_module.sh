#!/usr/bin/env bash
# @file: load_module.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Loads a Cockpit API module and the helpers in its fn folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Loads a Cockpit API module and the helpers in its fn folder.
# @arg: $1 - the module name, for example networks-list.
load_module() {
    local module_helper
    # shellcheck source=/dev/null
    source "${API}/modules/${1}/module.sh"
    for module_helper in "${API}/modules/${1}/fn/"*.sh; do
        # shellcheck source=/dev/null
        source "${module_helper}"
    done
}
