#!/usr/bin/env bash
# @file: cockpit-overview-usage-podman-counts.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/overview-usage/fn
# @dest-dir: /opt/podshift/cockpit/api/modules/overview-usage/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Counts Podman objects for one usage row.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_87C365545274:-}" ]]; then
    DIR_87C365545274="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_87C365545274
fi

# @description: Counts Podman objects for one usage row.
# @arg: $1 - row id: containers, images, volumes, networks or secrets.
# @stdout: a value such as 3 / 5 or 0, or nothing when a command fails.
# @exitcode: 0 always.
cockpit-overview-usage-podman-counts() {
    local kind used all ids
    # shellcheck source=./cockpit-overview-usage-podman.sh
    declare -F cockpit-overview-usage-podman >/dev/null || source "${DIR_87C365545274}/cockpit-overview-usage-podman.sh"
    # shellcheck source=./cockpit-overview-usage-count-lines.sh
    declare -F cockpit-overview-usage-count-lines >/dev/null || source "${DIR_87C365545274}/cockpit-overview-usage-count-lines.sh"
    # shellcheck source=./cockpit-overview-usage-value.sh
    declare -F cockpit-overview-usage-value >/dev/null || source "${DIR_87C365545274}/cockpit-overview-usage-value.sh"
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
