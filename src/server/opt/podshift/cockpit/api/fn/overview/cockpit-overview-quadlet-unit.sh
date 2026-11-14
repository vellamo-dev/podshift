#!/usr/bin/env bash
# @file: cockpit-overview-quadlet-unit.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Maps an installed quadlet file name to its systemd user unit name.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the systemd unit name that Quadlet generates for a file name.
# @details:
#   A .container or .kube file becomes <name>.service. A .pod, .volume, .network, .image
#   or .build file becomes <name>-pod.service, <name>-volume.service, and so on.
# @arg: $1 - a quadlet file name, with or without a directory path.
# @stdout: the unit name, for example app.service or db-volume.service.
# @exitcode: 0 when the name has a known quadlet suffix, 1 otherwise.
cockpit-overview-quadlet-unit() {
    local name
    name="${1-}"
    name="${name##*/}"
    case "${name}" in
        *.container)
            printf '%s.service\n' "${name%.container}"
            ;;
        *.kube)
            printf '%s.service\n' "${name%.kube}"
            ;;
        *.pod)
            printf '%s-pod.service\n' "${name%.pod}"
            ;;
        *.volume)
            printf '%s-volume.service\n' "${name%.volume}"
            ;;
        *.network)
            printf '%s-network.service\n' "${name%.network}"
            ;;
        *.image)
            printf '%s-image.service\n' "${name%.image}"
            ;;
        *.build)
            printf '%s-build.service\n' "${name%.build}"
            ;;
        *)
            return 1
            ;;
    esac
    return 0
}
