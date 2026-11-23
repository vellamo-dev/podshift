#!/usr/bin/env bash
# @file: get-quadlet-name-key.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Prints the section and key that set the Podman object name for a quadlet type.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints "Container ContainerName" for container, and the same for network, volume and pod.
# @details:
#   These four types create a Podman object whose name the file sets (per the Podman quadlet
#   docs). Other types, such as image, have no such key and print nothing.
#   The pod branches wait for pod support (docs/roadmap.md); a .pod file or Pod= key is refused for now.
# @arg: $1 - extension without the dot, for example container.
# @stdout: the section and the key, separated by one space.
# @exitcode: 0 if the type has a name key, 1 otherwise.
get-quadlet-name-key() {
    case "${1-}" in
        container) echo "Container ContainerName" ;;
        network) echo "Network NetworkName" ;;
        volume) echo "Volume VolumeName" ;;
        pod) echo "Pod PodName" ;;
        *) return 1 ;;
    esac
    return 0
}
