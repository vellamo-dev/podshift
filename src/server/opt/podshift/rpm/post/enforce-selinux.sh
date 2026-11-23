#!/usr/bin/env bash
# @file: enforce-selinux.sh
# @source-dir: src/server/opt/podshift/rpm/post
# @dest-dir: /opt/podshift/rpm/post
# @host-edit: no
# @group: post
# @category: step
# @step: PS-PO-SEL
# @description: Switches SELinux to enforcing on a first server install.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# On a first server install, switches SELinux from permissive to enforcing.
# Desktop installs and upgrades leave the mode as it is. A failed switch is
# reported and the step continues.

if [[ -z "${DIR_C7A16BCB6A8A:-}" ]]; then
    DIR_C7A16BCB6A8A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_C7A16BCB6A8A
fi

# @description: Switches SELinux to enforcing on a first server install.
# @arg: $1 - the RPM %post action: 1 for an install, 2 or more for an upgrade.
# @exitcode: 0 always (non-fatal, failures are reported via [WARN]).
enforce-selinux() {
    # Reserved step tag (matches @step in the header).
    local -r step_tag="PS-PO-SEL"
    local action mode config
    action="${1}"
    # shellcheck source=../../fn/utils/print-step-header.sh
    declare -F print-step-header >/dev/null || source "${DIR_C7A16BCB6A8A}/../../fn/utils/print-step-header.sh"
    # shellcheck source=../../fn/utils/print-step-warn.sh
    declare -F print-step-warn >/dev/null || source "${DIR_C7A16BCB6A8A}/../../fn/utils/print-step-warn.sh"
    # shellcheck source=../../fn/utils/print-step-skip.sh
    declare -F print-step-skip >/dev/null || source "${DIR_C7A16BCB6A8A}/../../fn/utils/print-step-skip.sh"
    # shellcheck source=../../fn/utils/print-step-ok.sh
    declare -F print-step-ok >/dev/null || source "${DIR_C7A16BCB6A8A}/../../fn/utils/print-step-ok.sh"
    print-step-header "${step_tag}" "Setting SELinux to enforcing..."

    if [[ "${action}" -ne 1 ]]; then
        print-step-skip "Skipped on upgrade"
        return 0
    fi

    # shellcheck source=../../fn/utils/is-install-type-desktop.sh
    declare -F is-install-type-desktop >/dev/null || source "${DIR_C7A16BCB6A8A}/../../fn/utils/is-install-type-desktop.sh"
    if is-install-type-desktop; then
        print-step-skip "Skipped on desktop install"
        return 0
    fi

    if ! command -v selinuxenabled >/dev/null 2>&1 || ! selinuxenabled; then
        print-step-warn "SELinux is disabled, run podshift selinux enforce for the steps to turn it back on"
        print-step-ok
        return 0
    fi

    mode="$(getenforce 2>/dev/null)" || mode=""
    mode="$(printf '%s' "${mode}" | tr 'A-Z' 'a-z')"
    # The tests point PODSHIFT_SELINUX_CONFIG at a temp file; otherwise main.conf sets it.
    if [[ -z "${PODSHIFT_SELINUX_CONFIG:-}" ]]; then
        # shellcheck source=../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_C7A16BCB6A8A}/../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main
    fi
    config="${PODSHIFT_SELINUX_CONFIG:-}"
    if [[ -z "${config}" ]]; then
        print-step-warn "PODSHIFT_SELINUX_CONFIG is not set in main.conf, run podshift selinux enforce later"
        print-step-ok
        return 0
    fi
    case "${mode}" in
        enforcing)
            echo -e "\tAlready enforcing"
            ;;
        permissive)
            # shellcheck source=../../fn/utils/selinux-set-enforcing.sh
            declare -F selinux-set-enforcing >/dev/null || source "${DIR_C7A16BCB6A8A}/../../fn/utils/selinux-set-enforcing.sh"
            if selinux-set-enforcing "${config}"; then
                echo -e "\tSwitched SELinux from permissive to enforcing"
            else
                print-step-warn "failed to switch SELinux to enforcing"
            fi
            ;;
        *)
            if [[ -n "${mode}" ]]; then
                print-step-warn "SELinux mode is unknown (${mode}), mode not changed"
            else
                print-step-warn "could not read the SELinux mode, mode not changed"
            fi
            ;;
    esac

    print-step-ok
    return 0
}
