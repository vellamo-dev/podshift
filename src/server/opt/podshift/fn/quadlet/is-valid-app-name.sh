#!/usr/bin/env bash
# @file: is-valid-app-name.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Tells if a name can be the name of a bundle and of its application.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that the name of a dropped zip, without .zip, is a valid application name.
# @details:
#   The name is the name of a dropped zip without .zip. It is valid if it starts with a letter or a
#   digit, has only letters, digits, underscore, dot and dash, and does not end with a Quadlet
#   extension (.artifact, .build, .container, .image, .kube, .network, .pod, .volume, .quadlets) or
#   with .qdl-bundle or .zip. The list is fixed and does not depend on the configuration, because
#   Podman refuses an application name that ends like a quadlet file. Allowed characters are
#   checked as a full literal list, not as letter ranges and not via LC_ALL, so the result does not
#   depend on the locale.
# @arg: $1 - name, without .zip.
# @stdout: nothing.
# @exitcode: 0 if the name is valid, 1 if not.
is-valid-app-name() {
    # Literal lists (no a-z ranges, no LC_ALL): letter ranges follow locale collation and can
    # accept non-ASCII; local LC_ALL=C under bats run has crashed bash 5.3 on macOS.
    local name suffix c
    local -r letters='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local -r digits='0123456789'
    local -r first="${letters}${digits}"
    local -r rest="${first}_.-"
    name="${1-}"
    [[ -n "${name}" ]] || return 1
    # Every character must be in the allowed set (hyphen last in the bracket list).
    [[ -z "${name//[${rest}]/}" ]] || return 1
    # The first character must be a letter or a digit, not underscore, dot or dash.
    c="${name%"${name#?}"}"
    case "${c}" in
        [${first}]) ;;
        *) return 1 ;;
    esac
    for suffix in .artifact .build .container .image .kube .network .pod .volume .quadlets .qdl-bundle .zip; do
        [[ "${name}" == *"${suffix}" ]] && return 1
    done
    return 0
}
