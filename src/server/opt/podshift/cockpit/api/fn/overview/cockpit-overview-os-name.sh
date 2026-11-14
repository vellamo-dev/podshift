#!/usr/bin/env bash
# @file: cockpit-overview-os-name.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Reads the OS name and version from os-release text.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints PRETTY_NAME from os-release text, or NAME and VERSION_ID when it is missing.
# @arg: $1 - optional os-release text; when omitted, the text is read from stdin.
# @stdout: the OS name, for example Fedora Linux 45.
# @exitcode: 0 when a name was printed, 1 when the text has no usable name.
cockpit-overview-os-name() {
    local raw pretty name version
    raw="${1-}"
    if [[ -z "${raw}" ]]; then
        raw="$(cat)"
    fi
    pretty="$(printf '%s\n' "${raw}" | awk '
        $0 ~ /^PRETTY_NAME=/ {
            val = substr($0, index($0, "=") + 1)
            if (val ~ /^".*"$/) val = substr(val, 2, length(val) - 2)
            else if (val ~ /^'\''.*'\''$/) val = substr(val, 2, length(val) - 2)
            print val
            exit
        }
    ')"
    if [[ -n "${pretty}" ]]; then
        printf '%s\n' "${pretty}"
        return 0
    fi
    name="$(printf '%s\n' "${raw}" | awk '
        $0 ~ /^NAME=/ {
            val = substr($0, index($0, "=") + 1)
            if (val ~ /^".*"$/) val = substr(val, 2, length(val) - 2)
            else if (val ~ /^'\''.*'\''$/) val = substr(val, 2, length(val) - 2)
            print val
            exit
        }
    ')"
    version="$(printf '%s\n' "${raw}" | awk '
        $0 ~ /^VERSION_ID=/ {
            val = substr($0, index($0, "=") + 1)
            if (val ~ /^".*"$/) val = substr(val, 2, length(val) - 2)
            else if (val ~ /^'\''.*'\''$/) val = substr(val, 2, length(val) - 2)
            print val
            exit
        }
    ')"
    if [[ -n "${name}" && -n "${version}" ]]; then
        printf '%s %s\n' "${name}" "${version}"
        return 0
    fi
    if [[ -n "${name}" ]]; then
        printf '%s\n' "${name}"
        return 0
    fi
    return 1
}
