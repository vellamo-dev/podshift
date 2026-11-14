#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-usage
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-usage
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Overview usage module: lists counts for user services, Podman objects and installed Quadlets.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_D5F29B38C0E1:-}" ]]; then
    DIR_D5F29B38C0E1="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_D5F29B38C0E1
fi

# shellcheck source=../../fn/overview/cockpit-overview-count.sh
declare -F cockpit-overview-count >/dev/null || source "${DIR_D5F29B38C0E1}/../../fn/overview/cockpit-overview-count.sh"
# shellcheck source=../../fn/overview/cockpit-overview-service-counts.sh
declare -F cockpit-overview-service-counts >/dev/null || source "${DIR_D5F29B38C0E1}/../../fn/overview/cockpit-overview-service-counts.sh"
# shellcheck source=../../fn/overview/cockpit-overview-usage-rows.sh
declare -F cockpit-overview-usage-rows >/dev/null || source "${DIR_D5F29B38C0E1}/../../fn/overview/cockpit-overview-usage-rows.sh"

# @description: Runs podman in the current (podshift) session.
# @arg: $@ - podman arguments.
# @stdout: podman stdout.
# @exitcode: the podman exit code, or 1 when podman is missing.
cockpit-overview-usage-podman() {
    podman "$@"
}

# @description: Runs systemctl --user in the current (podshift) session.
# @arg: $@ - systemctl arguments after --user.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code, or 1 when systemctl is missing.
cockpit-overview-usage-systemctl() {
    systemctl --user "$@"
}

# @description: Prints the installed-quadlet directory, loading main.conf when needed.
# @stdout: the directory path, or nothing when it is not known.
# @exitcode: 0 always.
cockpit-overview-usage-quadlet-dir() {
    if [[ -z "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        # shellcheck source=../../../../fn/load-podshift-conf-main.sh
        declare -F load-podshift-conf-main >/dev/null || source "${DIR_D5F29B38C0E1}/../../../../fn/load-podshift-conf-main.sh"
        load-podshift-conf-main
    fi
    if [[ -n "${PODSHIFT_PODMAN_QUADLETS_DIR:-}" ]]; then
        printf '%s\n' "${PODSHIFT_PODMAN_QUADLETS_DIR}"
    fi
}

# @description: Counts unique non-empty lines on stdin.
# @stdout: a non-negative integer.
# @exitcode: 0 always.
cockpit-overview-usage-count-lines() {
    awk 'NF { if (!seen[$0]++) n++ } END { print n+0 }'
}

# @description: Formats a usage count, or prints nothing when an argument is missing.
# @arg: $1 - a total, or the in-use count when $2 is also given.
# @arg: $2 - optional total count.
# @stdout: a value such as 3 or 3 / 5, or nothing.
# @exitcode: 0 always.
cockpit-overview-usage-value() {
    local text
    if text="$(cockpit-overview-count "$@")"; then
        printf '%s\n' "${text}"
    fi
}

# @description: Counts installed Quadlet files of every known type.
# @details:
#   Looks at regular files in the installed-quadlet directory (maxdepth 1). The value is
#   the number of installed Quadlet files of every known type.
# @arg: $1 - all to count every quadlet type.
# @stdout: a value such as 3 or 0, or nothing when the directory cannot be read.
# @exitcode: 0 always.
cockpit-overview-usage-quadlet-counts() {
    local mode dir file all name
    mode="${1-}"
    [[ "${mode}" == "all" ]] || return 0
    dir="$(cockpit-overview-usage-quadlet-dir)"
    [[ -n "${dir}" && -d "${dir}" ]] || return 0
    all=0
    # -P: do not follow a symlink when naming the starting directory.
    while IFS= read -r file; do
        [[ -n "${file}" ]] || continue
        name="${file##*/}"
        case "${name}" in
            *.container|*.kube|*.pod|*.volume|*.network|*.image|*.build)
                all=$((all + 1))
                ;;
        esac
    done < <(find -P "${dir}" -maxdepth 1 -type f ! -name '.*' \( \
        -name '*.container' -o -name '*.kube' -o -name '*.pod' -o \
        -name '*.volume' -o -name '*.network' -o -name '*.image' -o -name '*.build' \
        \) 2>/dev/null | LC_ALL=C sort)
    cockpit-overview-usage-value "${all}"
}

# @description: Counts the podshift user's loaded systemd user service units as active over total.
# @details:
#   Runs systemctl --user list-units --type=service --all --plain --no-legend --no-pager
#   through cockpit-overview-usage-systemctl, then formats the list with
#   cockpit-overview-service-counts. Nothing is printed when systemctl fails.
# @stdout: a value such as 2 / 10 or 0, or nothing when the list cannot be read.
# @exitcode: 0 always.
cockpit-overview-usage-service-counts() {
    local raw
    if raw="$(cockpit-overview-usage-systemctl list-units --type=service --all --plain --no-legend --no-pager 2>/dev/null)"; then
        printf '%s\n' "${raw}" | cockpit-overview-service-counts
    fi
}

# @description: Counts Podman objects for one usage row.
# @arg: $1 - row id: containers, images, volumes, networks or secrets.
# @stdout: a value such as 3 / 5 or 0, or nothing when a command fails.
# @exitcode: 0 always.
cockpit-overview-usage-podman-counts() {
    local kind used all ids
    kind="${1-}"
    used=""
    all=""
    case "${kind}" in
        containers)
            if ids="$(cockpit-overview-usage-podman ps -q 2>/dev/null)" && all="$(cockpit-overview-usage-podman ps -aq 2>/dev/null)"; then
                used="$(printf '%s\n' "${ids}" | cockpit-overview-usage-count-lines)"
                all="$(printf '%s\n' "${all}" | cockpit-overview-usage-count-lines)"
                cockpit-overview-usage-value "${used}" "${all}"
            fi
            ;;
        images)
            if all="$(cockpit-overview-usage-podman images -q 2>/dev/null)" && used="$(cockpit-overview-usage-podman ps -a --format '{{.ImageID}}' 2>/dev/null)"; then
                used="$(printf '%s\n' "${used}" | cockpit-overview-usage-count-lines)"
                all="$(printf '%s\n' "${all}" | cockpit-overview-usage-count-lines)"
                cockpit-overview-usage-value "${used}" "${all}"
            fi
            ;;
        volumes)
            if ! all="$(cockpit-overview-usage-podman volume ls -q 2>/dev/null)"; then
                return 0
            fi
            all="$(printf '%s\n' "${all}" | cockpit-overview-usage-count-lines)"
            if ! ids="$(cockpit-overview-usage-podman ps -aq 2>/dev/null)"; then
                return 0
            fi
            used=0
            if [[ -n "${ids}" ]]; then
                # shellcheck disable=SC2086
                if used="$(cockpit-overview-usage-podman inspect --format '{{range .Mounts}}{{if eq .Type "volume"}}{{.Name}}{{"\n"}}{{end}}{{end}}' ${ids} 2>/dev/null)"; then
                    used="$(printf '%s\n' "${used}" | cockpit-overview-usage-count-lines)"
                else
                    return 0
                fi
            fi
            cockpit-overview-usage-value "${used}" "${all}"
            ;;
        networks)
            if all="$(cockpit-overview-usage-podman network ls --format '{{.Name}}' 2>/dev/null)"; then
                all="$(printf '%s\n' "${all}" | cockpit-overview-usage-count-lines)"
                cockpit-overview-usage-value "${all}"
            fi
            ;;
        secrets)
            if all="$(cockpit-overview-usage-podman secret ls -q 2>/dev/null)"; then
                all="$(printf '%s\n' "${all}" | cockpit-overview-usage-count-lines)"
                cockpit-overview-usage-value "${all}"
            fi
            ;;
        *)
            return 0
            ;;
    esac
}

# @description: Lists usage counts for services, networks, containers, volumes, images, Quadlets and secrets.
# @details:
#   Services are the podshift user's loaded systemd user service units, as active over
#   total, from systemctl --user list-units --type=service --all. Units whose load state
#   is not loaded (not-found, masked or error) are omitted. A total of 0 is shown as 0.
#   Containers are running over all. Images and volumes are unique objects used by any
#   container, over the objects listed by podman. Networks, Quadlets and secrets are
#   totals only: podman network ls, installed Quadlet files in PODSHIFT_PODMAN_QUADLETS_DIR,
#   and podman secret ls. The process runs in the podshift session, so podman and
#   systemctl --user already talk to that user.
# @stdout: one JSON object with a rows array.
# @exitcode: 0 when the rows were written, 1 otherwise.
cockpit-module-overview-usage() {
    local values text
    values="{}"
    _overview_usage_put() {
        local id text
        id="${1}"
        text="${2-}"
        if [[ -n "${text}" ]]; then
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" --arg value "${text}" '$values + {($id): $value}')" || return 1
        else
            values="$(jq -c -n --argjson values "${values}" --arg id "${id}" '$values + {($id): null}')" || return 1
        fi
    }
    text="$(cockpit-overview-usage-service-counts)"
    _overview_usage_put services "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts networks)"
    _overview_usage_put networks "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts containers)"
    _overview_usage_put containers "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts volumes)"
    _overview_usage_put volumes "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts images)"
    _overview_usage_put images "${text}" || return 1
    text="$(cockpit-overview-usage-quadlet-counts all)"
    _overview_usage_put quadlets "${text}" || return 1
    text="$(cockpit-overview-usage-podman-counts secrets)"
    _overview_usage_put secrets "${text}" || return 1
    cockpit-overview-usage-rows "${values}"
}
