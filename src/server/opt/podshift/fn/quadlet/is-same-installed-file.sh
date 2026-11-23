#!/usr/bin/env bash
# @file: is-same-installed-file.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Tells if a dropped quadlet file, with its TSV variables filled, is the same as an installed file.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1F329386B8DA:-}" ]]; then
    DIR_1F329386B8DA="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1F329386B8DA
fi

# @description: Fills a copy of the dropped file with fill-tsv-vars and compares it with the installed file, without drop ID lines.
# @details:
#   The installed file is the filled copy that Podman installed, so the dropped file is filled the
#   same way first. The TSV_ values must already be loaded in the shell. The "# podshift-drop-id:"
#   lines (set-drop-id) are left out on both sides, since every drop has a new ID; the rest is
#   compared byte for byte. The dropped file is not changed. The temporary copies are removed.
# @arg: $1 - dropped quadlet file.
# @arg: $2 - installed quadlet file.
# @exitcode: 0 if the contents are the same, 1 if they differ or a file cannot be read.
is-same-installed-file() {
    local file installed tmp tmp_installed rc
    file="${1-}"
    installed="${2-}"
    [[ -f "${file}" && -r "${file}" && -f "${installed}" && -r "${installed}" ]] || return 1

    # shellcheck source=./fill-tsv-vars.sh
    declare -F fill-tsv-vars >/dev/null || source "${DIR_1F329386B8DA}/fill-tsv-vars.sh"
    tmp="$(mktemp)" || return 1
    tmp_installed="$(mktemp)" || { rm -f -- "${tmp}"; return 1; }
    rc=1
    if sed "/^# podshift-drop-id: /d" "${file}" > "${tmp}" && fill-tsv-vars "${tmp}" \
        && sed "/^# podshift-drop-id: /d" "${installed}" > "${tmp_installed}" \
        && cmp -s -- "${tmp}" "${tmp_installed}"; then
        rc=0
    fi
    rm -f -- "${tmp}" "${tmp_installed}"
    return "${rc}"
}
