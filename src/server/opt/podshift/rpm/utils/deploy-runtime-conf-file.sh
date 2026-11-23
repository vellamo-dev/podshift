#!/usr/bin/env bash
# @file: deploy-runtime-conf-file.sh
# @source-dir: src/server/opt/podshift/rpm/utils
# @dest-dir: /opt/podshift/rpm/utils
# @host-edit: no
# @group: posttrans
# @category: helper
# @description: Installs one runtime configuration template to its target, skipping if it already exists.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_8FB94E11FE8F:-}" ]]; then
    DIR_8FB94E11FE8F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_8FB94E11FE8F
fi

# @description: Installs one template to its target, skipping if it already exists.
# @arg: $1 - target path
# @stdout: the file name when it is installed.
# @exitcode: 0 always; a failed install is reported with [WARN].
deploy-runtime-conf-file() {
    local dst_file filename src_file
    dst_file="${1}"
    filename="$(basename "${dst_file}")"
    # shellcheck source=../../assets/tpl
    src_file="${PODSHIFT_RUNTIME_CONF_TEMPLATES}/${filename}"
    # shellcheck source=../../fn/utils/print-step-warn.sh
    declare -F print-step-warn >/dev/null || source "${DIR_8FB94E11FE8F}/../../fn/utils/print-step-warn.sh"
    if [[ -f "${src_file}" && ! -f "${dst_file}" ]]; then
        echo -e "\t- ${filename}"
        install -D -m 0644 "${src_file}" "${dst_file}" || print-step-warn "failed to install ${filename}"
    fi
}
