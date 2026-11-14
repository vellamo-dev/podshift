#!/usr/bin/env bash
# @file: cockpit-services-loaded.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/services
# @dest-dir: /opt/podshift/cockpit/api/fn/services
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Lists the loaded systemd user service units and their active state from systemctl list-units text.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints one line per loaded service unit: the unit name, a tab and its ACTIVE state.
# @details:
#   Reads list-units output from stdin, or from $1 when that argument is given. Only units
#   whose load state is loaded are listed. Units marked not-found, masked or error are
#   omitted. A leading failed-unit marker, the header line and the legend are ignored. The
#   same rule is used for the overview Services count (cockpit-overview-service-counts) and
#   the services-list action, so both list the same units.
# @arg: $1 - optional systemctl list-units text; when omitted, the text is read from stdin.
# @stdout: lines such as dbus-broker.service<TAB>active, in list order.
# @exitcode: 0 always.
cockpit-services-loaded() {
    local raw
    raw="${1-}"
    if [[ "$#" -eq 0 ]]; then
        raw="$(cat)"
    fi
    printf '%s\n' "${raw}" | awk '
        {
            line = $0
            sub(/^[[:space:]]+/, "", line)
            if (line == "") next
            nf = split(line, f, /[[:space:]]+/)
            if (nf < 3) next
            idx = 1
            unit = f[1]
            if (unit !~ /[.]service$/) {
                if (nf >= 4 && f[2] ~ /[.]service$/) {
                    idx = 2
                    unit = f[2]
                } else {
                    u = unit
                    while (u != "" && u !~ /^[A-Za-z0-9_@.\-]/)
                        u = substr(u, 2)
                    if (u ~ /[.]service$/)
                        unit = u
                    else
                        next
                }
            }
            # A marker glued to the name, such as ●app.service, is not part of the name.
            while (unit != "" && unit !~ /^[A-Za-z0-9_@.\-]/)
                unit = substr(unit, 2)
            load = f[idx + 1]
            active = f[idx + 2]
            if (unit == "UNIT" && load == "LOAD") next
            if (load != "loaded") next
            print unit "\t" active
        }
    '
}
