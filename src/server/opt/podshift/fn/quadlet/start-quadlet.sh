#!/usr/bin/env bash
# @file: start-quadlet.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Starts the user units of an installed quadlet file or bundle folder, without waiting.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_82FEC917646A:-}" ]]; then
    DIR_82FEC917646A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_82FEC917646A
fi

# @description: Queues the start of the item's pods and containers without waiting.
# @details:
#   Queues the start of every .pod as <name>-pod.service, then of every .container as
#   <name>.service unless its file sets StartWithPod= to true (the pod starts it). Files of other
#   types (.network, .volume, .image) are not started: systemd starts them as dependencies. Every
#   call is "systemctl --user start --no-block". An installed item is never replaced, so there is
#   nothing to restart. --no-block returns at once, so the caller never waits for a unit. A systemctl error is only logged; the rest are still tried.
#   The pod branches wait for pod support (docs/roadmap.md); a .pod file or Pod= key is refused for now.
# @arg: $1 - staged quadlet file or bundle folder, named by its original name.
# @exitcode: 0 if every systemctl call was accepted or none was needed, 1 if a call failed. The caller only logs this.
start-quadlet() {
    local item file name unit output failed extension
    local -a files
    item="${1}"
    failed=0

    # shellcheck source=./is-start-with-pod.sh
    declare -F is-start-with-pod >/dev/null || source "${DIR_82FEC917646A}/is-start-with-pod.sh"

    mapfile -t files < <(find "${item}" -type f | LC_ALL=C sort)

    for extension in pod container; do
        for file in "${files[@]}"; do
            name="$(basename "${file}")"
            [[ "${name}" == *".${extension}" ]] || continue
            if [[ "${extension}" == "pod" ]]; then
                unit="${name%.pod}-pod.service"
            else
                if is-start-with-pod "${file}"; then
                    logger -t podshift-qdl-install -p info "${name} is started with its pod, not started on its own"
                    continue
                fi
                unit="${name%.container}.service"
            fi
            if output="$(systemctl --user start --no-block "${unit}" 2>&1)"; then
                logger -t podshift-qdl-install -p info "queued start of ${unit}"
            else
                logger -t podshift-qdl-install -p err "failed to queue start of ${unit}"
                printf '%s\n' "${output}" | logger -t podshift-qdl-install -p err
                failed=1
            fi
        done
    done
    return "${failed}"
}
