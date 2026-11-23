#!/usr/bin/env bash
# @file: podshift.sh
# @dest-dir: /etc/profile.d
# @description: Loads PodShift helpers and config into the login shells of root, podshift and admins.
# @warning: Runs in every login shell and is managed by PodShift, so keep it fast and silent and do not edit it on the server.

# The helpers use Bash syntax, so other shells (sh, zsh) skip this file. [ ] works in every shell, [[ ]] does not.
if [ -n "${BASH_VERSION:-}" ]; then
    # Only root, the podshift user and admins (members of wheel, the Fedora sudo group) get the helpers
    # and the PODSHIFT_* and TSV_* variables; other users get nothing. sudo is not asked, so nothing is
    # logged and no password prompt can appear, and id runs only for users who are not root or podshift.
    # shellcheck source=../../opt/podshift/fn/utils/is-podshift.sh
    declare -F is-podshift >/dev/null || source /opt/podshift/fn/utils/is-podshift.sh
    # shellcheck source=../../opt/podshift/fn/utils/is-wheel-member.sh
    declare -F is-wheel-member >/dev/null || source /opt/podshift/fn/utils/is-wheel-member.sh
    if [[ "${EUID}" -eq 0 ]] || is-podshift || is-wheel-member; then
        # Shell session helpers (quit, hcl)
        # shellcheck source=../../opt/podshift/fn/session/hcl.sh
        declare -F hcl >/dev/null || source /opt/podshift/fn/session/hcl.sh
        # shellcheck source=../../opt/podshift/fn/session/quit.sh
        declare -F quit >/dev/null || source /opt/podshift/fn/session/quit.sh

        # Loads main and network configuration
        # shellcheck source=../../opt/podshift/fn/load-podshift-conf-nw.sh
        declare -F load-podshift-conf-nw >/dev/null || source /opt/podshift/fn/load-podshift-conf-nw.sh
        load-podshift-conf-nw
    fi
fi
