#!/usr/bin/env bash
# @file: make-podshift-user-podman-compatible.sh
# @source-dir: src/server/opt/podshift/rpm/posttrans
# @dest-dir: /opt/podshift/rpm/posttrans
# @host-edit: no
# @group: posttrans
# @category: step
# @step: PS-PT-PMC
# @description: Makes the podshift user rootless-Podman compatible.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Configures the dedicated podshift system user so that it
# can run rootless Podman containers reliably.

if [[ -z "${DIR_6A062C16DF7A:-}" ]]; then
    DIR_6A062C16DF7A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_6A062C16DF7A
fi

# @description: Makes the podshift user rootless-Podman compatible.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
make-podshift-user-podman-compatible() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-PMC"
    local dir_local bin_file
    dir_local="/home/podshift/.local"
    # shellcheck source=../../fn/utils/print-step.sh
    declare -F print-step-header >/dev/null || source "${DIR_6A062C16DF7A}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Making podshift user compatible with rootless podman..."

    if [[ ! -d "${dir_local}" ]]; then
        echo -e "\tCreating directory '${dir_local}'..."
        mkdir -p "${dir_local}"
        # shellcheck source=../../fn/rootless/set-owner-rootless.sh
        source "${DIR_6A062C16DF7A}/../../fn/rootless/set-owner-rootless.sh"
        set-owner-rootless "${dir_local}"
    fi

    # Add subuid/subgid ranges if missing (100000-165535 = 65536 ids).
    if ! grep -q '^podshift:100000:65536$' /etc/subuid 2>/dev/null; then
        echo -e "\tAdding subuids..."
        usermod --add-subuids 100000-165535 podshift \
            || print-step-warn "failed to add subuids for podshift."
    fi
    if ! grep -q '^podshift:100000:65536$' /etc/subgid 2>/dev/null; then
        echo -e "\tAdding subgids..."
        usermod --add-subgids 100000-165535 podshift \
            || print-step-warn "failed to add subgids for podshift."
    fi

    # Ensure the newuidmap/newgidmap can map ids (required for rootless user namespaces).
    # They need either file capabilities or the setuid bit, never both: on Fedora
    # (caps by default) adding setuid makes the newuidmap fail with "open of uid_map
    # failed: Permission denied". Setuid is the fallback when the caps are missing.
    for bin_file in newuidmap newgidmap; do
        if [ -f "/usr/bin/${bin_file}" ] && [ ! -u "/usr/bin/${bin_file}" ] \
            && [ -z "$(getcap "/usr/bin/${bin_file}" 2>/dev/null)" ]; then
            echo -e "\tSetting setuid bit on ${bin_file}..."
            chmod u+s "/usr/bin/${bin_file}" \
                || print-step-warn "failed to set setuid bit on ${bin_file}."
        fi
    done

    print-step-ok
}
