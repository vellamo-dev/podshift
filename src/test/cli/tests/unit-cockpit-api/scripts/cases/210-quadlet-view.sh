#!/usr/bin/env bash
# @file: 210-quadlet-view.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: quadlet-view.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# quadlet-view: QV_SOURCE is the SourcePath that systemctl show prints; QV_DIR the Quadlet folder.
qv_dir="${WORK}/quadlet-view/systemd"
qv_outside="${WORK}/quadlet-view/outside"
mkdir -p "${qv_dir}/app" "${qv_outside}"
printf '[Container]\nImage=nginx\nSecret=db-pass\n' > "${qv_dir}/web.container"
printf '[Network]\n' > "${qv_dir}/app/net.network"
printf '[Container]\n' > "${qv_outside}/evil.container"
# Temporary links in the mktemp folder, like the capability link cases above.
ln -s "${qv_outside}/evil.container" "${qv_dir}/link.container"
ln -s "${qv_outside}" "${qv_dir}/escape"
quadlet_contract="$(jq -c '.output' "${API}/modules/quadlet-view/capability.json")"
cockpit-quadlet-view-systemctl() {
    printf '%s\n' "$*" >> "${svc_calls}"
    case "${1-}" in
        list-units) printf '%s' "${svc_units}" ;;
        show) printf '%s\n' "${QV_SOURCE-}"; return "${QV_RC:-0}" ;;
        *) return 1 ;;
    esac
}
cockpit-quadlet-view-dir() {
    printf '%s\n' "${QV_DIR-}"
}

: > "${svc_calls}"
qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/web.container" cockpit-module-quadlet-view '{"unit":"web.service"}')"
if printf '%s' "${qv_out}" | jq -e --arg path "${qv_dir}/web.container" '. == {"unit":"web.service","found":true,"quadlet":true,"name":"web.container","path":$path,"kind":"container","text":"[Container]\nImage=nginx\nSecret=db-pass\n"}' >/dev/null \
    && cockpit-validate-contract "${quadlet_contract}" "${qv_out}" \
    && grep -q -- '^show --property=SourcePath --value -- web.service$' "${svc_calls}"; then
    ok "quadlet-view-module"
else
    bad "quadlet-view-module" "${qv_out} calls $(tr '\n' ';' < "${svc_calls}")"
fi

qv_out="$(QV_DIR="${qv_dir}/" QV_SOURCE="${qv_dir}/app/net.network" cockpit-module-quadlet-view '{"unit":"web.service"}')"
printf '%s' "${qv_out}" | jq -e '.kind == "network" and .name == "net.network" and .text == "[Network]\n"' >/dev/null
expect_status "quadlet-view-bundle-folder" $? "${qv_out}"

: > "${svc_calls}"
qv_out="$(QV_DIR="${qv_dir}" cockpit-module-quadlet-view '{"unit":"missing.service"}')"
[[ "${qv_out}" == '{"unit":"missing.service","found":false}' ]] && ! grep -q '^show' "${svc_calls}"
expect_status "quadlet-view-unknown-unit" $? "${qv_out}"

qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="" cockpit-module-quadlet-view '{"unit":"old.service"}')"
[[ "${qv_out}" == '{"unit":"old.service","found":true,"quadlet":false,"error":"NOT_QUADLET"}' ]] \
    && cockpit-validate-contract "${quadlet_contract}" "${qv_out}"
expect_status "quadlet-view-not-quadlet" $? "${qv_out}"

qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/gone.container" cockpit-module-quadlet-view '{"unit":"web.service"}')"
printf '%s' "${qv_out}" | jq -e '.error == "FILE_NOT_FOUND" and .name == "gone.container" and (has("text") | not)' >/dev/null \
    && cockpit-validate-contract "${quadlet_contract}" "${qv_out}"
expect_status "quadlet-view-file-not-found" $? "${qv_out}"

qv_n=0
for qv_source in "${qv_outside}/evil.container" "${qv_dir}/../outside/evil.container" "${qv_dir}/link.container" "${qv_dir}/escape/evil.container"; do
    qv_n=$((qv_n + 1))
    qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_source}" cockpit-module-quadlet-view '{"unit":"web.service"}')"
    printf '%s' "${qv_out}" | jq -e '.error == "OUTSIDE_QUADLET_DIR" and .quadlet == true and (has("text") | not)' >/dev/null \
        && cockpit-validate-contract "${quadlet_contract}" "${qv_out}"
    expect_status "quadlet-view-outside-${qv_n}" $? "${qv_source}: ${qv_out}"
done

qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/web.container" QV_RC=1 cockpit-module-quadlet-view '{"unit":"web.service"}' 2>/dev/null)" && qv_rc=0 || qv_rc=$?
[[ "${qv_rc}" -ne 0 && -z "${qv_out}" ]]
expect_status "quadlet-view-show-fails" $? "${qv_out}"

: > "${svc_calls}"
if qv_out="$(cockpit-module-quadlet-view '{"unit":"../web.service"}' 2>/dev/null)" || [[ -s "${svc_calls}" ]]; then
    bad "quadlet-view-bad-name" "${qv_out}"
else
    ok "quadlet-view-bad-name"
fi

head -c 140000 /dev/zero | tr '\0' 'x' > "${qv_dir}/big.container"
qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/big.container" cockpit-module-quadlet-view '{"unit":"web.service"}')"
if printf '%s' "${qv_out}" | jq -e '.tooLarge == true and .size == 140000 and (has("text") | not)' >/dev/null \
    && cockpit-validate-contract "${quadlet_contract}" "${qv_out}"; then
    ok "quadlet-view-limit"
else
    bad "quadlet-view-limit" "$(printf '%s' "${qv_out}" | head -c 200)"
fi

if [[ "$(id -u)" -ne 0 ]]; then
    printf '[Container]\n' > "${qv_dir}/locked.container"
    chmod 000 "${qv_dir}/locked.container"
    qv_out="$(QV_DIR="${qv_dir}" QV_SOURCE="${qv_dir}/locked.container" cockpit-module-quadlet-view '{"unit":"web.service"}')"
    chmod 600 "${qv_dir}/locked.container"
    printf '%s' "${qv_out}" | jq -e '.error == "FILE_UNREADABLE" and (has("text") | not)' >/dev/null
    expect_status "quadlet-view-unreadable" $? "${qv_out}"
fi
rm -rf "${WORK}/quadlet-view"


