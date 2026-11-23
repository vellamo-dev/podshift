#!/usr/bin/env bash
# @file: get-quadlet-unit-name.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @unit-test: yes
# @description: Prints the systemd service name that the Quadlet generator makes from a quadlet file name.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the service name of a quadlet file: web.container is web.service, web.pod is web-pod.service.
# @details:
#   Per the Podman quadlet docs: .container and .kube give <name>.service; .pod, .network,
#   .volume, .image and .build give <name>-pod.service, <name>-network.service and so on. The
#   collision suffix and any folder are removed first. Another extension prints nothing.
# @arg: $1 - quadlet file name or path.
# @stdout: the service name, for example web-network.service.
# @exitcode: 0 if the extension is known, 1 otherwise.
get-quadlet-unit-name() {
    local name stem
    name="$(basename -- "${1-}")"
    [[ "${name}" =~ ^(.+)\.[0-9]+$ ]] && name="${BASH_REMATCH[1]}"
    stem="${name%.*}"
    [[ -n "${stem}" && "${stem}" != "${name}" ]] || return 1
    case "${name##*.}" in
        container|kube) printf '%s.service\n' "${stem}" ;;
        pod|network|volume|image|build) printf '%s-%s.service\n' "${stem}" "${name##*.}" ;;
        *) return 1 ;;
    esac
    return 0
}
