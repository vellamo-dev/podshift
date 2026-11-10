#!/usr/bin/env bash
# @file: podshift.sh
# @dest-dir: /etc/profile.d
# @description: Loads the PodShift shell helpers and configuration into every login shell.
# @warning: Runs in every login shell and is managed by PodShift, so keep it fast and silent and do not edit it on the server.

# Shell session helpers (quit, hcl)
if [[ -n "${BASH_VERSION:-}" ]]; then
    # shellcheck source=../../opt/podshift/fn/session/session-helpers.sh
    source /opt/podshift/fn/session/session-helpers.sh
fi

# Loads main and network configuration
# shellcheck source=../../opt/podshift/fn/load-podshift-conf-nw.sh
declare -F load-podshift-conf-nw >/dev/null || source /opt/podshift/fn/load-podshift-conf-nw.sh
load-podshift-conf-nw
