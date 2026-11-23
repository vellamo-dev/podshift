#!/usr/bin/env bash
# @file: cockpit-service-logs-systemctl.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/service-logs/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/service-logs/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Runs systemctl --user against the podshift user manager, from the root realm.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs systemctl --user against the podshift user manager, from the root realm.
# @arg: $1 - the podshift UID.
# @arg: $@ - further systemctl arguments.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code.
cockpit-service-logs-systemctl() {
    local uid
    uid="${1}"
    shift
    systemctl --machine="${uid}@.host" --user "$@"
}
