#!/usr/bin/env bash
# @file: cockpit-overview-info-fail2ban-version.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-info/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-info/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the installed Fail2Ban version.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the installed Fail2Ban version.
# @stdout: a version string, or nothing when Fail2Ban is missing.
# @exitcode: 0 always.
cockpit-overview-info-fail2ban-version() {
    local version
    version="$(rpm -q --qf '%{VERSION}' fail2ban 2>/dev/null || true)"
    if [[ -z "${version}" || "${version}" == *"is not installed"* ]]; then
        version="$(fail2ban-client version 2>/dev/null || true)"
    fi
    case "${version}" in
        ''|*is\ not\ installed*)
            return 0
            ;;
    esac
    version="${version#Fail2Ban }"
    version="${version#Fail2Ban v}"
    version="${version#v}"
    printf '%s\n' "${version}"
}
