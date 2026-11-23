#!/usr/bin/env bash
# @file: cockpit-quadlets-unit-description.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/quadlets
# @dest-dir: /opt/podshift/cockpit/api/fn/quadlets
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the first Description= value from the [Unit] section of a Quadlet file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the first Description= value from the [Unit] section of a Quadlet file.
# @details:
#   The first matching key in the [Unit] section wins. The value is trimmed. Blank lines and
#   comments starting with # or ; are skipped. Description= in any other section is ignored.
#   An empty string is printed when the path is empty, the file is missing or unreadable, or
#   the section has no Description.
# @arg: $1 - path of the Quadlet file.
# @stdout: the trimmed Description, or an empty string.
# @exitcode: 0
cockpit-quadlets-unit-description() {
    local path
    path="${1-}"
    if [[ -z "${path}" || ! -f "${path}" || ! -r "${path}" ]]; then
        return 0
    fi
    awk '
        {
            sub(/\r$/, "")
        }
        /^[[:space:]]*\[Unit\][[:space:]]*$/ {
            in_unit = 1
            next
        }
        /^[[:space:]]*\[/ {
            in_unit = 0
            next
        }
        in_unit && /^[[:space:]]*[#;]/ { next }
        in_unit && /^[[:space:]]*Description[[:space:]]*=/ {
            sub(/^[[:space:]]*Description[[:space:]]*=/, "")
            sub(/^[[:space:]]+/, "")
            sub(/[[:space:]]+$/, "")
            print
            exit
        }
    ' < "${path}"
}
