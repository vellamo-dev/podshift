#!/usr/bin/env bash
# @file: remove-podman-auto-update.sh
# @source-dir: src/server/opt/podshift/rpm/preun
# @dest-dir: /opt/podshift/rpm/preun
# @host-edit: no
# @group: preun
# @category: step
# @step: PS-PR-AUT
# @description: Disables the rootless podman auto-update timer.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_9C5E3A7B1D4F:-}" ]]; then
    DIR_9C5E3A7B1D4F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_9C5E3A7B1D4F
fi

# @description: Disables the rootless podman auto-update timer.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
remove-podman-auto-update() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PR-AUT"
    # shellcheck source=../../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_9C5E3A7B1D4F}/../../fn/utils/print-step.sh"

    print-step-header "${step_tag}" "Disabling podman auto-update timer..."

    if ! systemctl --machine="300@.host" --user is-enabled --quiet podman-auto-update.timer 2>/dev/null; then
        print-step-skip "Timer not enabled"
        return 0
    fi

    systemctl --machine="300@.host" --user disable --now podman-auto-update.timer >/dev/null 2>&1 \
        || print-step-warn "Failed to disable podman-auto-update.timer."

    print-step-ok
}
