#!/usr/bin/env bash
# podshift.sh
# /etc/profile.d

# Shell session helpers (quit, hcl)
if [[ -n "${BASH_VERSION:-}" ]]; then
    # shellcheck source=../../opt/podshift/fn/session/session-helpers.sh
    source /opt/podshift/fn/session/session-helpers.sh
fi

# Loads main and network configuration
# shellcheck source=../../opt/podshift/fn/load-podshift-conf-nw.sh
source /opt/podshift/fn/load-podshift-conf-nw.sh --now