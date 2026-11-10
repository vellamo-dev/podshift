#!/usr/bin/env bash
# @file: is-local-dev-run.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Detects whether running from a local dev checkout rather than the installed app.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_329985B1E57A:-}" ]]; then
    DIR_329985B1E57A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_329985B1E57A
fi

# @description: Returns 0 if running from a local dev checkout rather than the installed app.
# @exitcode: 0 if local dev, 1 otherwise.
is-local-dev-run() {
    [[ "${DIR_329985B1E57A}" != /usr/local/* ]]
}
