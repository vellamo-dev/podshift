#!/usr/bin/env bash
# @file: 500-quadlet-remove.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: quadlet-remove.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# --- quadlet-remove ---
# The module runs in this process with real files in a temporary folder. load-podshift-conf-main
# and logger are stubbed. It only checks and queues; podshift-qdl-remove does the removal.
# shellcheck source=/dev/null
source "${API}/modules/quadlet-remove/module.sh"
rm_root="${WORK}/remove-case"
rm_queue="${rm_root}/remove-queue"
rm_qdir="${rm_root}/systemd"
rm_log="${WORK}/remove-history.log"
mkdir -p "${rm_queue}" "${rm_qdir}/shop"
rm_contract="$(jq -c '.output' "${API}/modules/quadlet-remove/capability.json")"
printf '[Network]\nNetworkName=front\n' > "${rm_qdir}/front.network"
printf '[Container]\nContainerName=web\nNetwork=front.network\n' > "${rm_qdir}/web.container"
printf '[Container]\nContainerName=api\nVolume=data.volume:/data\n' > "${rm_qdir}/shop/api.container"
printf '[Volume]\nVolumeName=data\n' > "${rm_qdir}/shop/data.volume"
load-podshift-conf-main() {
    PODSHIFT_QUADLET_REMOVE_QUEUE_DIR="${rm_queue}"
    PODSHIFT_PODMAN_QUADLETS_DIR="${rm_qdir}"
}
logger() { printf '%s\n' "$*" >> "${rm_log}"; }
rm_args() { jq -n -c --arg name "${1}" --argjson volumes "${2:-false}" '{name: $name, volumes: $volumes}'; }

: > "${rm_log}"
rm_out="$(cockpit-module-quadlet-remove "$(rm_args web.container)")"
if [[ "${rm_out}" == '{"name":"web.container","ok":true}' ]] \
    && cockpit-validate-contract "${rm_contract}" "${rm_out}" \
    && [[ "$(cat "${rm_queue}/web.container")" == "volumes=0" ]] \
    && [[ -z "$(find "${rm_queue}" -name '.request.*')" ]] \
    && grep -qxF -- '-t podshift-qdl-remove -p info queued removal of web.container' "${rm_log}" \
    && ! grep -q 'podshift-drop-history' "${rm_log}"; then
    ok "quadlet-remove-queues-file"
else
    bad "quadlet-remove-queues-file" "${rm_out} $(cat "${rm_log}")"
fi

rm_out="$(cockpit-module-quadlet-remove "$(rm_args web.container)")"
[[ "$(printf '%s' "${rm_out}" | jq -r '.error')" == "BUSY" ]] && cockpit-validate-contract "${rm_contract}" "${rm_out}"
expect_status "quadlet-remove-busy" $? "${rm_out}"
rm -f "${rm_queue}/web.container"

# While the service removes web.container, its request is a hidden marker; the same removal is still BUSY.
: > "${rm_queue}/.removing.web.container"
rm_out="$(cockpit-module-quadlet-remove "$(rm_args web.container)")"
[[ "$(printf '%s' "${rm_out}" | jq -r '.error')" == "BUSY" && ! -e "${rm_queue}/web.container" ]]
expect_status "quadlet-remove-busy-while-removing" $? "${rm_out}"
rm -f "${rm_queue}/.removing.web.container"

rm_out="$(cockpit-module-quadlet-remove "$(rm_args shop true)")"
[[ "$(printf '%s' "${rm_out}" | jq -r '.ok')" == "true" && "$(cat "${rm_queue}/shop")" == "volumes=1" ]] \
    && grep -qxF -- '-t podshift-qdl-remove -p info queued removal of shop' "${rm_log}"
expect_status "quadlet-remove-queues-app-with-volumes" $? "${rm_out}"
rm -f "${rm_queue}/shop"

rm_out="$(cockpit-module-quadlet-remove "$(rm_args front.network)")"
[[ "$(printf '%s' "${rm_out}" | jq -r '.error')" == "IN_USE" && "$(printf '%s' "${rm_out}" | jq -r '.message')" == "used by web.container" ]] \
    && [[ -z "$(find "${rm_queue}" -mindepth 1)" ]]
expect_status "quadlet-remove-in-use" $? "${rm_out}"

rm_ok=1
for rm_case in "gone.container NOT_FOUND" "blog NOT_FOUND" "../web.container INVALID_NAME" "shop/api.container INVALID_NAME" "notes.txt NOT_FOUND" "bad name INVALID_NAME" "-x.container INVALID_NAME"; do
    rm_out="$(cockpit-module-quadlet-remove "$(rm_args "${rm_case% *}")")"
    if [[ "$(printf '%s' "${rm_out}" | jq -r '.error')" != "${rm_case##* }" ]] || ! cockpit-validate-contract "${rm_contract}" "${rm_out}"; then
        rm_ok=0
        bad "quadlet-remove-refuses" "${rm_case}: ${rm_out}"
    fi
done
[[ -z "$(find "${rm_queue}" -mindepth 1)" ]] || { rm_ok=0; bad "quadlet-remove-refuses" "a request was queued"; }
[[ "${rm_ok}" -eq 1 ]] && ok "quadlet-remove-refuses"

rmdir "${rm_queue}"
rm_out="$(cockpit-module-quadlet-remove "$(rm_args web.container)")"
expect_eq "quadlet-remove-unavailable" "$(printf '%s' "${rm_out}" | jq -r '.error')" "REMOVE_UNAVAILABLE" "${rm_out}"
if cockpit-validate-contract "${rm_contract}" '{"name":"a","ok":false,"error":"OTHER"}' \
    || cockpit-validate-contract "${rm_contract}" '{"name":"a","ok":true,"path":"/x"}'; then
    bad "quadlet-remove-output-contract" "an unknown code or extra field was accepted"
else
    ok "quadlet-remove-output-contract"
fi
unset -f load-podshift-conf-main logger
rm -rf "${rm_root}"

