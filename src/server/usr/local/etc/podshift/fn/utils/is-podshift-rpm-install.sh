#!/usr/bin/env bash
# @file: is-podshift-rpm-install.sh
# @dir: /usr/local/etc/podshift/fn/utils
# @group: utils
# @description: Detects whether PodShift is installed via RPM on Fedora.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_A95FE67DC14D:-}" ]]; then
    DIR_A95FE67DC14D="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_A95FE67DC14D
fi

# shellcheck source=./is-fedora.sh
source "${DIR_A95FE67DC14D}/is-fedora.sh"

# @description: Returns 0 if PodShift is installed via RPM on Fedora.
# @exitcode: 0 if installed via RPM on Fedora, 1 otherwise.
is-podshift-rpm-install() {
    is-fedora || return 1
    command -v rpm >/dev/null 2>&1 || return 1
    rpm -q podshift >/dev/null 2>&1
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-podshift-rpm-install
fi
