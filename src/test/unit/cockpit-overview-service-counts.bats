#!/usr/bin/env bats
# Unit test for cockpit-overview-service-counts (src/server/opt/podshift/cockpit/api/fn/overview/cockpit-overview-service-counts.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/cockpit/api/fn/overview/cockpit-overview-service-counts.sh"
}

# Sample taken from `systemctl --user list-units --type=service` on a PodShift VM.
VM_SAMPLE=$'  UNIT                           LOAD      ACTIVE   SUB     DESCRIPTION                                               \n  dbus-broker.service            loaded    active   running D-Bus User Message Bus\n  grub-boot-success.service      loaded    inactive dead    Mark boot as successful\n  podman-auto-update.service     loaded    inactive dead    Podman auto-update service\n  podman.service                 loaded    inactive dead    Podman API Service\n  podshift-drop-debounce.service loaded    inactive dead    Reset the drop debounce timer on every drop event\n  podshift-drop-process.service  loaded    inactive dead    Process files dropped into the PodShift drop directory\n  podshift-qdl-install.service   loaded    inactive dead    Install quadlets waiting in the PodShift source directory\n  podshift-qdl-validate.service  loaded    inactive dead    Validate quadlets waiting in the PodShift validation queue\n● systemd-oomd.service           not-found inactive dead    systemd-oomd.service\n  systemd-tmpfiles-clean.service loaded    inactive dead    Cleanup of User\'s Temporary Files and Directories\n  systemd-tmpfiles-setup.service loaded    active   exited  Create User Files and Directories\n\nLegend: LOAD   → Reflects whether the unit definition was properly loaded.\n        ACTIVE → The high-level unit activation state, i.e. generalization of SUB.\n        SUB    → The low-level unit activation state, values depend on unit type.\n\n11 loaded units listed.\nTo show all installed unit files use \'systemctl list-unit-files\'.\n'

@test "the VM sample is 2 / 10" {
    run cockpit-overview-service-counts "${VM_SAMPLE}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "2 / 10" ]
}

@test "an empty list is 0" {
    run cockpit-overview-service-counts ""
    [ "${status}" -eq 0 ]
    [ "${output}" = "0" ]
}

@test "a masked unit is excluded and a failed unit is in the total only" {
    run cockpit-overview-service-counts $'dbus-broker.service loaded active running D-Bus User Message Bus\nfoo.service loaded failed failed Failed unit\nbar.service masked inactive dead Masked unit\nbaz.service error inactive dead Error unit\nqux.service not-found inactive dead Missing unit\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1 / 2" ]
}

@test "plain list-units text without a header is counted" {
    run cockpit-overview-service-counts $'app@one.service loaded active running Instance\nother.service loaded activating start Starting unit\n'
    [ "${status}" -eq 0 ]
    [ "${output}" = "1 / 2" ]
}

@test "text can also be read from stdin" {
    output="$(printf '%s\n' 'ok.service loaded active running Ok' | cockpit-overview-service-counts)"
    status=$?
    [ "${status}" -eq 0 ]
    [ "${output}" = "1 / 1" ]
}
