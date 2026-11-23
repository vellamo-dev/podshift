#!/usr/bin/env bash
# @file: cockpit-install-log-matches.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/drop
# @dest-dir: /opt/podshift/cockpit/api/fn/drop
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Prints the journalctl matches of the Quadlet install pipeline of one UID, one per line.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints SYSLOG_IDENTIFIER and _UID matches for the pipeline tags, systemd and podman, joined with +.
# @details:
#   The tags are podshift-drop-process, podshift-qdl-validate, podshift-qdl-install,
#   podshift-qdl-remove, systemd (the user manager, for the start and stop of Quadlet units)
#   and podman (container events), each with _UID, so lines that another user logs with the
#   same tag never show. cockpit-install-log-filter leaves out the systemd and podman noise.
# @arg: $1 - numeric UID, for example 300.
# @stdout: the match arguments, one per line.
# @exitcode: 0 when they were printed, 1 when the UID is not a number.
cockpit-install-log-matches() {
    local uid
    uid="${1-}"
    [[ "${uid}" =~ ^[0-9]+$ ]] || return 1
    printf '%s\n' \
        "SYSLOG_IDENTIFIER=podshift-drop-process" "_UID=${uid}" + \
        "SYSLOG_IDENTIFIER=podshift-qdl-validate" "_UID=${uid}" + \
        "SYSLOG_IDENTIFIER=podshift-qdl-install" "_UID=${uid}" + \
        "SYSLOG_IDENTIFIER=podshift-qdl-remove" "_UID=${uid}" + \
        "SYSLOG_IDENTIFIER=systemd" "_UID=${uid}" + \
        "SYSLOG_IDENTIFIER=podman" "_UID=${uid}"
}
