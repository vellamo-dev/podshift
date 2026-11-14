#!/usr/bin/env bash
# @file: cockpit-services-journal-matches.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/services
# @dest-dir: /opt/podshift/cockpit/api/fn/services
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Prints the journalctl matches for one user service of one user, for a journalctl run as root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the journalctl match arguments for one user unit of one UID, one per line.
# @details:
#   The same filter that journalctl --user-unit builds for its own UID, but for the given UID, so it
#   also works as root: messages from the service (_SYSTEMD_USER_UNIT), messages from that user's
#   systemd about it (USER_UNIT) and messages about it from that user (OBJECT_SYSTEMD_USER_UNIT),
#   each with _UID, joined with +. The unit must already be checked (cockpit-services-args), so it
#   has no newline or space; the UID must be a number.
# @arg: $1 - unit name, for example web.service.
# @arg: $2 - numeric UID, for example 300.
# @stdout: the match arguments, one per line.
# @exitcode: 0 when they were printed, 1 when the unit is empty or has a space, or the UID is not a number.
cockpit-services-journal-matches() {
    local unit uid
    unit="${1-}"
    uid="${2-}"
    [[ -n "${unit}" && "${unit}" != *[[:space:]]* ]] || return 1
    [[ "${uid}" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' \
        "_SYSTEMD_USER_UNIT=${unit}" "_UID=${uid}" + \
        "USER_UNIT=${unit}" "_UID=${uid}" + \
        "OBJECT_SYSTEMD_USER_UNIT=${unit}" "_UID=${uid}"
}
