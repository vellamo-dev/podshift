#!/usr/bin/env bash
# deploy-rootless-bins.sh
# /usr/local/etc/podshift/rpm/posttrans
# Enables shorthand commands for podshift user.

if [[ -z "${DIR_DD272F40557F:-}" ]]; then
    DIR_DD272F40557F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DD272F40557F
fi

deploy-rootless-bins() {
    local name script source_dir dest_dir symlink_bin bins_count
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_DD272F40557F}/../../fn/utils/print-warning.sh"
    # shellcheck source=../../fn/rootless/set-owner-rootless.sh
    source "${DIR_DD272F40557F}/../../fn/rootless/set-owner-rootless.sh"

    bins_count=0
    dest_dir="/home/podshift/.local/bin"
    # shellcheck source=../../bin-rootless
    source_dir="$(realpath "${DIR_DD272F40557F}/../../bin-rootless")"

    echo -e "\nEnabling shorthand commands for podshift user..."

    # Create the destination directory if missing.
    if [[ ! -d "${dest_dir}" ]]; then
        echo -e "\tCreating dir '${dest_dir}'..."
        if ! mkdir -p "${dest_dir}"; then
            print-warning "failed to create ${dest_dir}."
            return 0
        fi
        set-owner-rootless "${dest_dir}"
    fi

    # Create symlinks without the .sh extension.
    for script in "${source_dir}"/*.sh; do
        [ -e "${script}" ] || continue
        name="$(basename "${script}" .sh)"
        symlink_bin="${dest_dir}/${name}"
        if ! ln -sf "${script}" "${symlink_bin}"; then
            print-warning "failed to create the ${name} shorthand."
            continue
        fi
        chown -h podshift:podshift "${symlink_bin}" 2>/dev/null \
            || print-warning "failed to set ownership of the ${name} shorthand."
        ((bins_count++))
    done

    echo -e "\tDone. Created ${bins_count} shorthands."
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && deploy-rootless-bins
fi
