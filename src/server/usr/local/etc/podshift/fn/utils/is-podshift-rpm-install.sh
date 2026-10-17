#!/usr/bin/env bash
# is-podshift-rpm-install.sh
# /usr/local/etc/podshift/fn/utils

if [[ -z "${DIR_A95FE67DC14D:-}" ]]; then
    DIR_A95FE67DC14D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A95FE67DC14D
fi

# shellcheck source=./is-fedora.sh
source "${DIR_A95FE67DC14D}/is-fedora.sh"

# Returns 0 (true) if PodShift is installed via RPM on Fedora, non-zero otherwise.
is-podshift-rpm-install() {
    is-fedora || return 1
    command -v rpm >/dev/null 2>&1 || return 1
    rpm -q podshift >/dev/null 2>&1
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-podshift-rpm-install
fi
