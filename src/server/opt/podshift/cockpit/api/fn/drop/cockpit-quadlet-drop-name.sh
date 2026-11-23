#!/usr/bin/env bash
# @file: cockpit-quadlet-drop-name.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/drop
# @dest-dir: /opt/podshift/cockpit/api/fn/drop
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Checks the file name of a Quadlet upload of the quadlet-drop action.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_93CB97419B98:-}" ]]; then
    DIR_93CB97419B98="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_93CB97419B98
fi

# @description: Prints nothing for a valid upload name, else one CODE<tab>message problem line.
# @details:
#   The name must be a plain file name: no folder part, not hidden. Its extension must be .zip or
#   one of the accepted Quadlet extensions (PODSHIFT_DROP_QUADLET_EXTENSIONS, passed in). The name
#   without the extension must pass is-valid-app-name: it starts with a letter or a digit and has
#   only letters, digits, underscore, dot and dash. Codes: INVALID_NAME and UNSUPPORTED_TYPE.
# @arg: $1 - file name, for example web.container or shop.zip.
# @arg: $2 - comma-separated accepted Quadlet extensions, for example .container,.volume.
# @stdout: nothing when valid, else CODE<tab>message.
# @exitcode: 0 when the name is valid, 1 when it is refused.
cockpit-quadlet-drop-name() {
    local name extensions extension stem shown
    name="${1-}"
    extensions="${2-}"
    if [[ -z "${name}" || "${name}" == */* || "${name}" == *\\* ]]; then
        printf 'INVALID_NAME\tThe name must be a file name without folders.\n'
        return 1
    fi
    if [[ "${name}" == .* ]]; then
        printf 'INVALID_NAME\tHidden files are not accepted.\n'
        return 1
    fi
    extension=""
    [[ "${name}" == *.* ]] && extension=".${name##*.}"
    if [[ -z "${extension}" || ( "${extension}" != ".zip" && ",${extensions}," != *",${extension},"* ) ]]; then
        shown="${extensions//,/, }"
        printf 'UNSUPPORTED_TYPE\tOnly %s and .zip files are accepted.\n' "${shown}"
        return 1
    fi
    stem="${name%.*}"
    # shellcheck source=../../../../fn/quadlet/is-valid-app-name.sh
    declare -F is-valid-app-name >/dev/null || source "${DIR_93CB97419B98}/../../../../fn/quadlet/is-valid-app-name.sh"
    if ! is-valid-app-name "${stem}"; then
        printf 'INVALID_NAME\tThe name must start with a letter or a digit and use only letters, digits, _, . and -.\n'
        return 1
    fi
    return 0
}
