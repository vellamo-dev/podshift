#!/usr/bin/env bash
# @file: is-valid-env-tag.sh
# @source-dir: src/server/opt/podshift/fn/utils
# @dest-dir: /opt/podshift/fn/utils
# @host-edit: no
# @group: utils
# @category: helper
# @unit-test: yes
# @description: Tells if a text can be the environment tag TSV_ENV.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks a tag against ^[a-zA-Z0-9_][a-zA-Z0-9._-]{0,127}$.
# @details:
#   The tag is 1 to 128 characters of a-z, A-Z, 0-9, _, . and -, and does not start with . or -.
#   The characters are checked against literal lists, not letter ranges, so the result does not
#   depend on the locale. podshift env --set and the Cockpit API env-set action use this check.
# @arg: $1 - the tag.
# @stdout: nothing.
# @exitcode: 0 if the tag is valid, 1 if not.
is-valid-env-tag() {
    local tag first
    local -r letters='abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ'
    local -r digits='0123456789'
    tag="${1-}"
    [[ -n "${tag}" && "${#tag}" -le 128 ]] || return 1
    [[ -z "${tag//[${letters}${digits}._-]/}" ]] || return 1
    first="${tag%"${tag#?}"}"
    [[ -z "${first//[${letters}${digits}_]/}" ]] || return 1
    return 0
}
