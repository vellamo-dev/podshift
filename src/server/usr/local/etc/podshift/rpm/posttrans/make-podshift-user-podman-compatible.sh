#!/usr/bin/env bash
# @file: make-podshift-user-podman-compatible.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: PMC
# @description: Makes the podshift user rootless-Podman compatible
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
    source "${DIR_6A062C16DF7A}/../../fn/utils/print-step.sh"
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

    # Ensure newuidmap/newgidmap are setuid (required for rootless user namespaces).
    for bin_file in newuidmap newgidmap; do
        if [ -f "/usr/bin/${bin_file}" ] && [ ! -u "/usr/bin/${bin_file}" ]; then
            echo -e "\tSetting setuid bit on ${bin_file}..."
            chmod u+s "/usr/bin/${bin_file}" \
                || print-step-warn "failed to set setuid bit on ${bin_file}."
        fi
    done

    # Migrate any existing storage for the podshift user.
    echo -e "\tMigrating podman storage..."
    su - podshift -c "podman system migrate" \
        || print-step-warn "podman system migrate failed for podshift."

    print-step-ok
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && make-podshift-user-podman-compatible
fi
