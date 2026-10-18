#!/usr/bin/env bash
# make-podshift-user-podman-compatible.sh
# /usr/local/etc/podshift/rpm/posttrans
# Configures the dedicated podshift system user so that it
# can run rootless Podman containers reliably.

if [[ -z "${DIR_6A062C16DF7A:-}" ]]; then
    DIR_6A062C16DF7A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_6A062C16DF7A
fi

make-podshift-user-podman-compatible() {
    local dir_local bin_file
    dir_local="/home/podshift/.local"

    echo -e "\nMaking podshift user compatible with rootless podman..."

    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_6A062C16DF7A}/../../fn/utils/print-warning.sh"
    source "${DIR_6A062C16DF7A}/../../fn/rootless/set-owner-rootless.sh"

    if [[ ! -d "${dir_local}" ]]; then
        echo -e "\tCreating directory '${dir_local}'..."
        mkdir -p "${dir_local}"
        set-owner-rootless "${dir_local}"
    fi

    # Add subuid/subgid ranges if missing (100000-165535 = 65536 ids).
    if ! grep -q '^podshift:100000:65536$' /etc/subuid 2>/dev/null; then
        echo -e "\tAdding subuids..."
        usermod --add-subuids 100000-165535 podshift \
            || print-warning "failed to add subuids for podshift."
    fi
    if ! grep -q '^podshift:100000:65536$' /etc/subgid 2>/dev/null; then
        echo -e "\tAdding subgids..."
        usermod --add-subgids 100000-165535 podshift \
            || print-warning "failed to add subgids for podshift."
    fi

    # Ensure newuidmap/newgidmap are setuid (required for rootless user namespaces).
    for bin_file in newuidmap newgidmap; do
        if [ -f "/usr/bin/${bin_file}" ] && [ ! -u "/usr/bin/${bin_file}" ]; then
            echo -e "\tSetting setuid bit on ${bin_file}..."
            chmod u+s "/usr/bin/${bin_file}" \
                || print-warning "failed to set setuid bit on ${bin_file}."
        fi
    done

    # Migrate any existing storage for the podshift user.
    echo -e "\tMigrating podman storage..."
    su - podshift -c "podman system migrate" \
        || print-warning "podman system migrate failed for podshift."

    echo -e "\tDone"
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && make-podshift-user-podman-compatible
fi
