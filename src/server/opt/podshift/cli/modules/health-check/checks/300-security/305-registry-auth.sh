#!/usr/bin/env bash
# @file: 305-registry-auth.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/300-security
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/300-security
# @host-edit: no
# @group: health-check
# @category: check
# @title: Registry auth
# @run-as: podshift
# @description: Verifies the registry auth file.
# @rationale: Without auth, pulls to private registries fail.
# @fix: Only needed for private registries: podman login as the podshift user. The file needs mode 600.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the registry-auth check.
# @stdout: one TSV line: registry-auth<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-registry-auth() {
    local auth_file mode
    auth_file="/home/podshift/.config/containers/auth.json"
    if [[ ! -f "${auth_file}" ]]; then
        printf 'registry-auth\tWARN\tauth file absent (public pulls only)\n'
        return 1
    fi
    mode="$(stat -c %a "${auth_file}" 2>/dev/null)"
    if [[ "${mode}" == "600" ]]; then
        printf 'registry-auth\tOK\tauth file present (600)\n'
        return 0
    fi
    printf 'registry-auth\tFAIL\tauth file mode %s (expected 600)\n' "${mode:-unknown}"
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-registry-auth
