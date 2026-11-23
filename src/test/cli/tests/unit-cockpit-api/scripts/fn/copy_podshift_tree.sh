#!/usr/bin/env bash
# @file: copy_podshift_tree.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Copies the PodShift tree to a new folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Copies the PodShift tree to a new folder.
copy_podshift_tree() {
    local dest
    dest="${1}"
    rm -rf "${dest}"
    mkdir -p "${dest}"
    cp -R "${PODSHIFT}/." "${dest}/"
}
