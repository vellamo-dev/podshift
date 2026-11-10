#!/usr/bin/env bash
# @file: health-result.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @description: Turns one health check into one result line.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_FDEA7807AFE8:-}" ]]; then
    DIR_FDEA7807AFE8="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_FDEA7807AFE8
fi

# @description: Runs one check where the caller can reach it and prints its result.
# @arg: $1 - path to the check script.
# @arg: $2 - the group key, for example host.
# @arg: $3 - the caller: root, podshift, or other.
# @stdout: one line: group<TAB>id<TAB>title<TAB>status<TAB>detail.
# @exitcode: 0 always.
health-result() {
    local script group caller fmt id title run_as install_type route status detail line rc
    script="${1}"
    group="${2}"
    caller="${3}"
    fmt='%s\t%s\t%s\t%s\t%s\n'
    # shellcheck source=health-route.sh
    declare -F health-route >/dev/null || source "${DIR_FDEA7807AFE8}/health-route.sh"
    # shellcheck source=health-run-check.sh
    declare -F health-run-check >/dev/null || source "${DIR_FDEA7807AFE8}/health-run-check.sh"
    # shellcheck source=../../../../fn/utils/is-install-type-desktop.sh
    declare -F is-install-type-desktop >/dev/null || source "${DIR_FDEA7807AFE8}/../../../../fn/utils/is-install-type-desktop.sh"

    id="$(basename "${script}" .sh)"
    id="${id#*-}"
    title="$(grep -m1 '^# @title:' "${script}" 2>/dev/null | sed 's/^# @title: //')"
    title="${title:-${id}}"
    run_as="$(grep -m1 '^# @run-as:' "${script}" 2>/dev/null | sed 's/^# @run-as: //')"
    install_type="$(grep -m1 '^# @install-type:' "${script}" 2>/dev/null | sed 's/^# @install-type: //')"
    route="$(health-route "${run_as}" "${caller}")"
    # The podshift realm can only be entered while the podshift user's session runs.
    [[ "${route}" == "podshift-session" && ! -d /run/user/300 ]] && route="no-session"

    # Checks that are not run.
    status=""
    case "${route}" in
        skip-root)     status="SKIP";  detail="needs root" ;;
        skip-podshift) status="SKIP";  detail="needs podshift or root" ;;
        invalid)       status="ERROR"; detail="missing or unknown @run-as" ;;
        no-session)    status="ERROR"; detail="podshift session not available" ;;
    esac
    # Server-only checks are not run on a desktop install.
    if [[ -z "${status}" && "${install_type}" == "server" ]] && is-install-type-desktop; then
        status="SKIP"
        detail="desktop install"
    fi
    if [[ -n "${status}" ]]; then
        printf "${fmt}" "${group}" "${id}" "${title}" "${status}" "${detail}"
        return 0
    fi

    # Checks that are run: the exit code decides the status.
    line="$(health-run-check "${route}" "${script}")"
    rc=$?
    [[ -n "${line}" ]] && id="${line%%$'\t'*}"
    detail="${line#*$'\t'}"
    detail="${detail#*$'\t'}"
    case "${rc}:${line:+output}" in
        0:output)  status="OK" ;;
        1:output)  status="WARN" ;;
        2:output)  status="FAIL" ;;
        3:output)  status="INFO" ;;
        0:|1:|2:|3:)  status="ERROR"; detail="produced no output" ;;
        124:*)     status="ERROR"; detail="timed out after 10s" ;;
        *)         status="ERROR"; detail="failed to run" ;;
    esac
    printf "${fmt}" "${group}" "${id}" "${title}" "${status}" "${detail}"
    return 0
}
