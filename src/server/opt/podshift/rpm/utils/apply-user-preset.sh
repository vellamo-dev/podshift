#!/usr/bin/env bash
# @file: apply-user-preset.sh
# @source-dir: src/server/opt/podshift/rpm/utils
# @dest-dir: /opt/podshift/rpm/utils
# @host-edit: no
# @group: utils
# @category: helper
# @description: Applies the PodShift user unit preset (90-podshift.preset).
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_DC2ECBFFB070:-}" ]]; then
    DIR_DC2ECBFFB070="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DC2ECBFFB070
fi

# @description: Applies the user unit enablement preset.
apply-user-preset() {
    # shellcheck source=../../fn/utils/print-step-warn.sh
    declare -F print-step-warn >/dev/null || source "${DIR_DC2ECBFFB070}/../../fn/utils/print-step-warn.sh"
    if systemctl --machine="300@.host" --user preset \
        systemd-tmpfiles-setup.service \
        podman.socket \
        podman-auto-update.timer \
        podshift-drop.path \
        podshift-qdl-validate.path \
        podshift-qdl-install.path \
        podshift-qdl-remove.path \
        podshift-drop-safety.timer >/dev/null 2>&1; then
        echo -e "\tUser presets '90-podshift.preset' apply succeeded"
    else
        print-step-warn "User presets '90-podshift.preset' apply failed"
    fi
}
