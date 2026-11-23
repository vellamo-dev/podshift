#!/usr/bin/env bats
# Unit test for cockpit-install-log-matches (src/server/opt/podshift/cockpit/api/fn/drop/cockpit-install-log-matches.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/drop/cockpit-install-log-matches.sh"
}

@test "the four pipeline tags, systemd and podman each with the UID, joined with +" {
    run cockpit-install-log-matches 300
    [ "${status}" -eq 0 ]
    [ "${output}" = "SYSLOG_IDENTIFIER=podshift-drop-process
_UID=300
+
SYSLOG_IDENTIFIER=podshift-qdl-validate
_UID=300
+
SYSLOG_IDENTIFIER=podshift-qdl-install
_UID=300
+
SYSLOG_IDENTIFIER=podshift-qdl-remove
_UID=300
+
SYSLOG_IDENTIFIER=systemd
_UID=300
+
SYSLOG_IDENTIFIER=podman
_UID=300" ]
}

@test "a UID that is not a number is refused" {
    run cockpit-install-log-matches ""
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
    run cockpit-install-log-matches "300 +"
    [ "${status}" -eq 1 ]
}
