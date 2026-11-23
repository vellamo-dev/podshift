#!/usr/bin/env bash
# @file: 400-drop-upload.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: quadlet-drop uploads: size, busy names, owner checks and bad input.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# --- quadlet-drop, quadlet-drop-history, quadlet-install-log and log-drop-history ---
# quadlet-drop runs in this process with real files in a temporary folder. load-podshift-conf-main
# and logger are stubbed. The test does not run as podshift, so cockpit-quadlet-drop-file-meta is
# stubbed with DROP_META for the success cases.
load_module quadlet-drop
drop_root="${WORK}/drop-case"
drop_up="${drop_root}/web-upload"
drop_in="${drop_root}/drop"
drop_log="${WORK}/drop-history.log"
mkdir -p "${drop_up}" "${drop_in}"
drop_contract="$(jq -c '.output' "${API}/modules/quadlet-drop/capability.json")"
load-podshift-conf-main() {
    PODSHIFT_QUADLET_WEB_UPLOAD_DIR="${drop_up}"
    PODSHIFT_DROP_DIR="${drop_in}"
    PODSHIFT_DROP_MAX_BUNDLE_SIZE=50
    PODSHIFT_DROP_QUADLET_EXTENSIONS=".container,.volume,.network,.image"
}
logger() { printf '%s\n' "$*" >> "${drop_log}"; }
DROP_META="podshift podshift 644"
cockpit-quadlet-drop-file-meta() { printf '%s\n' "${DROP_META}"; }
drop_args() { jq -n -c --arg name "${1}" --arg content "${2}" '{name: $name, content: $content}'; }
drop_b64() { base64 | tr -d '\n'; }
drop_upload_empty() { [[ -z "$(find "${drop_up}" -mindepth 1 -print 2>/dev/null)" ]]; }
drop_mode() { stat -c '%a' -- "${1}" 2>/dev/null || stat -f '%Lp' -- "${1}" 2>/dev/null; }
web_b64="$(printf '[Unit]\nDescription=Web test\n\n[Container]\nImage=docker.io/library/nginx:latest\n' | drop_b64)"

: > "${drop_log}"
drop_out="$(cockpit-module-quadlet-drop "$(drop_args web.container "${web_b64}")")"
if [[ "${drop_out}" == '{"name":"web.container","ok":true}' ]] \
    && cockpit-validate-contract "${drop_contract}" "${drop_out}" \
    && grep -qx 'Description=Web test' "${drop_in}/web.container" \
    && [[ "$(drop_mode "${drop_in}/web.container")" == "644" ]] \
    && drop_upload_empty \
    && grep -qxF -- '-t podshift-qdl-upload -p info uploaded web.container to the drop folder' "${drop_log}" \
    && ! grep -q 'podshift-drop-history' "${drop_log}"; then
    ok "quadlet-drop-writes"
else
    bad "quadlet-drop-writes" "${drop_out} log $(cat "${drop_log}")"
fi

# A .zip of exactly 50 KB is accepted; one byte more is TOO_LARGE and leaves nothing behind.
drop_out="$(cockpit-module-quadlet-drop "$(drop_args shop.zip "$(head -c 51200 /dev/zero | drop_b64)")")"
[[ "${drop_out}" == '{"name":"shop.zip","ok":true}' ]] && [[ "$(LC_ALL=C wc -c < "${drop_in}/shop.zip" | tr -d '[:space:]')" == "51200" ]] && drop_upload_empty
expect_status "quadlet-drop-zip-limit" $? "${drop_out}"
drop_out="$(cockpit-module-quadlet-drop "$(drop_args big.zip "$(head -c 51201 /dev/zero | drop_b64)")")"
[[ "$(printf '%s' "${drop_out}" | jq -r '.error')" == "TOO_LARGE" ]] && cockpit-validate-contract "${drop_contract}" "${drop_out}" \
    && [[ ! -e "${drop_in}/big.zip" ]] && drop_upload_empty
expect_status "quadlet-drop-too-large" $? "${drop_out}"
drop_out="$(cockpit-module-quadlet-drop "$(drop_args big.container "$(head -c 51201 /dev/zero | tr '\0' 'a' | drop_b64)")")"
[[ "$(printf '%s' "${drop_out}" | jq -r '.error')" == "TOO_LARGE" ]] && [[ ! -e "${drop_in}/big.container" ]] && drop_upload_empty
expect_status "quadlet-drop-file-too-large" $? "${drop_out}"

# A name still waiting in the drop directory is refused; the waiting file is not touched.
printf 'old\n' > "${drop_in}/busy.container"
drop_out="$(cockpit-module-quadlet-drop "$(drop_args busy.container "${web_b64}")")"
[[ "$(printf '%s' "${drop_out}" | jq -r '.error')" == "NAME_BUSY" ]] && cockpit-validate-contract "${drop_contract}" "${drop_out}" \
    && [[ "$(cat "${drop_in}/busy.container")" == "old" ]] && drop_upload_empty \
    && [[ "$(find "${drop_in}" -name 'busy.container*' | wc -l | tr -d '[:space:]')" == "1" ]]
expect_status "quadlet-drop-name-busy" $? "${drop_out}"

# Wrong owner, group or mode: refused and the temp file is removed.
drop_n=0
for DROP_META in "root podshift 644" "podshift wheel 644" "podshift podshift 600" ""; do
    drop_n=$((drop_n + 1))
    drop_out="$(cockpit-module-quadlet-drop "$(drop_args "owner${drop_n}.container" "${web_b64}")")"
    [[ "$(printf '%s' "${drop_out}" | jq -r '.error')" == "WRONG_OWNER" ]] && [[ ! -e "${drop_in}/owner${drop_n}.container" ]] && drop_upload_empty
    expect_status "quadlet-drop-wrong-owner-${drop_n}" $? "${drop_out}"
done
DROP_META="podshift podshift 644"

# Bad names, types and content never write a file.
drop_n=0
for drop_case in \
    '.web.container|INVALID_NAME' \
    'a/web.container|INVALID_NAME' \
    '../web.container|INVALID_NAME' \
    '-web.container|INVALID_NAME' \
    'web.pod|UNSUPPORTED_TYPE' \
    'notes.txt|UNSUPPORTED_TYPE' \
    'web|UNSUPPORTED_TYPE'; do
    drop_n=$((drop_n + 1))
    drop_out="$(cockpit-module-quadlet-drop "$(drop_args "${drop_case%%|*}" "${web_b64}")")"
    [[ "$(printf '%s' "${drop_out}" | jq -r '.error')" == "${drop_case#*|}" ]] && cockpit-validate-contract "${drop_contract}" "${drop_out}" \
        && [[ "$(find "${drop_in}" -type f | wc -l | tr -d '[:space:]')" == "3" ]] && drop_upload_empty
    expect_status "quadlet-drop-refused-${drop_n}" $? "${drop_case} ${drop_out}"
done
drop_out="$(cockpit-module-quadlet-drop "$(drop_args name.container "abc")")"
drop_out2="$(cockpit-module-quadlet-drop "$(drop_args name.container 'ab!=')")"
[[ "$(printf '%s' "${drop_out}" | jq -r '.error')" == "INVALID_CONTENT" && "$(printf '%s' "${drop_out2}" | jq -r '.error')" == "INVALID_CONTENT" ]] \
    && [[ ! -e "${drop_in}/name.container" ]] && drop_upload_empty
expect_status "quadlet-drop-invalid-content" $? "${drop_out} ${drop_out2}"
rm -rf "${drop_up}"
drop_out="$(cockpit-module-quadlet-drop "$(drop_args gone.container "${web_b64}")")"
[[ "$(printf '%s' "${drop_out}" | jq -r '.error')" == "DROP_UNAVAILABLE" ]] && [[ ! -e "${drop_in}/gone.container" ]]
expect_status "quadlet-drop-no-upload-dir" $? "${drop_out}"
mkdir -p "${drop_up}"
# Without a size limit in main.conf the upload is refused; there is no built-in limit.
load-podshift-conf-main() {
    PODSHIFT_QUADLET_WEB_UPLOAD_DIR="${drop_up}"
    PODSHIFT_DROP_DIR="${drop_in}"
    PODSHIFT_DROP_MAX_BUNDLE_SIZE=""
    PODSHIFT_DROP_QUADLET_EXTENSIONS=".container,.volume,.network,.image"
}
drop_out="$(cockpit-module-quadlet-drop "$(drop_args nolimit.container "${web_b64}")")"
[[ "$(printf '%s' "${drop_out}" | jq -r '.error + " " + .message')" == "DROP_UNAVAILABLE The drop size limit is not set." ]] \
    && [[ ! -e "${drop_in}/nolimit.container" ]] && drop_upload_empty
expect_status "quadlet-drop-no-size-limit" $? "${drop_out}"
load-podshift-conf-main() {
    PODSHIFT_QUADLET_WEB_UPLOAD_DIR="${drop_up}"
    PODSHIFT_DROP_DIR="${drop_in}"
    PODSHIFT_DROP_MAX_BUNDLE_SIZE=50
    PODSHIFT_DROP_QUADLET_EXTENSIONS=".container,.volume,.network,.image"
}

# The real stat helper prints owner, group and mode; the test user is not podshift, so the upload is refused.
source "${API}/modules/quadlet-drop/module.sh"
# shellcheck source=/dev/null
for module_helper in "${API}/modules/quadlet-drop/fn/"*.sh; do source "${module_helper}"; done
printf 'x' > "${WORK}/meta.file"
chmod 0644 "${WORK}/meta.file"
drop_meta_real="$(cockpit-quadlet-drop-file-meta "${WORK}/meta.file")"
drop_out="$(cockpit-module-quadlet-drop "$(drop_args real.container "${web_b64}")")"
[[ "${drop_meta_real}" =~ ^[^\ ]+\ [^\ ]+\ 644$ ]] \
    && { [[ "$(id -un)" == "podshift" ]] || [[ "$(printf '%s' "${drop_out}" | jq -r '.error')" == "WRONG_OWNER" && ! -e "${drop_in}/real.container" ]]; } \
    && drop_upload_empty
expect_status "quadlet-drop-real-owner-check" $? "meta ${drop_meta_real} ${drop_out}"

if cockpit-validate-contract "${drop_contract}" '{"name":"a.zip","ok":false,"error":"OTHER","message":""}' \
    || cockpit-validate-contract "${drop_contract}" '{"name":"a.zip","ok":true,"path":"/home/podshift/drop/a.zip"}'; then
    bad "quadlet-drop-output-contract" "an unknown code or extra field was accepted"
else
    ok "quadlet-drop-output-contract"
fi

