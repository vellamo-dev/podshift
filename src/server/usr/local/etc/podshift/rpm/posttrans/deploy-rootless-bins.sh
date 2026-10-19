#!/usr/bin/env bash
# @file: deploy-rootless-bins.sh
# @dir: /usr/local/etc/podshift/rpm/posttrans
# @group: posttrans
# @prefix: PS-PT
# @id: BIN
# @description: Creates the shorthand commands for the podshift user
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Enables shorthand commands for podshift user.

if [[ -z "${DIR_DD272F40557F:-}" ]]; then
    DIR_DD272F40557F="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_DD272F40557F
fi

# @description: Creates the shorthand commands for the podshift user.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
deploy-rootless-bins() {
    # Reserved step tag (matches @prefix-@id in the header).
    local -r step_tag="PS-PT-BIN"
    local name script source_dir dest_dir symlink_bin bins_count
    bins_count=0
    dest_dir="/home/podshift/.local/bin"
    # shellcheck source=../../fn/utils/print-step.sh
    source "${DIR_DD272F40557F}/../../fn/utils/print-step.sh"
    print-step-header "${step_tag}" "Enabling shorthand commands for podshift user..."
    # shellcheck source=../../bin-rootless
    source_dir="$(realpath "${DIR_DD272F40557F}/../../bin-rootless")"

    # Create the destination directory if missing.
    if [[ ! -d "${dest_dir}" ]]; then
        echo -e "\tCreating dir '${dest_dir}'..."
        if ! mkdir -p "${dest_dir}"; then
            print-step-warn "failed to create ${dest_dir}."
            return 0
        fi
        # shellcheck source=../../fn/rootless/set-owner-rootless.sh
        source "${DIR_DD272F40557F}/../../fn/rootless/set-owner-rootless.sh"
        set-owner-rootless "${dest_dir}"
    fi

    # Create symlinks without the .sh extension.
    for script in "${source_dir}"/*.sh; do
        [ -e "${script}" ] || continue
        name="$(basename "${script}" .sh)"
        symlink_bin="${dest_dir}/${name}"
        if ! ln -sf "${script}" "${symlink_bin}"; then
            print-step-warn "failed to create the ${name} shorthand."
            continue
        fi
        chown -h podshift:podshift "${symlink_bin}" 2>/dev/null \
            || print-step-warn "failed to set ownership of the ${name} shorthand."
        ((bins_count++))
    done

    print-step-ok "Created ${bins_count} shorthands."
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "$1" == "--now" ]] && deploy-rootless-bins
fi
