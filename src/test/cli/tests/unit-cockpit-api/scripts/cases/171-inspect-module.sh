#!/usr/bin/env bash
# @file: 171-inspect-module.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: inspect module: secrets, image short IDs, size limits and file mode.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# inspect module, kind secret: podman is stubbed to print SecretData anyway. It is removed in
# normal and file mode, and --showsecret is never passed.
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${*}" in
        "secret inspect -- db-password")
            printf '%s\n' '[{"ID":"3c8e1f0a9b7d6c5e4f3a2b1c0","Spec":{"Name":"db-password","Driver":{"Name":"file"}},"SecretData":"must-never-leak"}]'
            ;;
        "secret inspect -- "*)
            return 125
            ;;
        "secret exists -- "*)
            return 1
            ;;
        *)
            return 2
            ;;
    esac
}
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect '{"kind":"secret","ref":"db-password"}')"
printf '%s' "${ins_out}" | jq -e '.kind == "secret" and .found == true and .object.Spec.Name == "db-password" and (.object | has("SecretData") | not)' >/dev/null \
    && [[ "${ins_out}" != *must-never-leak* ]] && cockpit-validate-contract "${inspect_contract}" "${ins_out}" \
    && ! grep -q -- '--showsecret' "${ins_calls}"
expect_status "inspect-module-secret-no-value" $? "${ins_out}"
sec_rt="${WORK}/secret-runtime"
mkdir -p "${sec_rt}"
ins_out="$(XDG_RUNTIME_DIR="${sec_rt}" cockpit-module-inspect '{"kind":"secret","ref":"db-password","mode":"file"}')"
ins_path="$(printf '%s' "${ins_out}" | jq -r '.file.path // empty')"
[[ -f "${ins_path}" ]] && jq -e '.ID == "3c8e1f0a9b7d6c5e4f3a2b1c0" and (has("SecretData") | not)' "${ins_path}" >/dev/null \
    && ! grep -q 'must-never-leak' "${ins_path}" && ! grep -q -- '--showsecret' "${ins_calls}"
expect_status "inspect-module-secret-file-no-value" $? "${ins_out}"
ins_out="$(cockpit-module-inspect '{"kind":"secret","ref":"gone"}')"
[[ "${ins_out}" == '{"kind":"secret","ref":"gone","found":false}' ]] && cockpit-validate-contract "${inspect_contract}" "${ins_out}"
expect_status "inspect-module-secret-not-found" $? "${ins_out}"

# inspect module: an image short ID that podman image inspect does not find is resolved through
# podman image ls; a full ID is found directly; no match is still not found.
ins_full="abbc135a7d39c0e8a2fdabbc135a7d39c0e8a2fdabbc135a7d39c0e8a2fd1234"
ins_tagonly="5ee1d0c0ffee5ee1d0c0ffee5ee1d0c0ffee5ee1d0c0ffee5ee1d0c0ffee5ee1"
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${*}" in
        "image inspect -- ${ins_full}"|"image inspect -- docker.io/library/tagonly:1") cat "${ins_fix}/image.json" ;;
        "image ls --format json")
            printf '[{"Id":"%s","Names":["docker.io/library/alpine:latest"]},{"Id":"sha256:%s","Names":["docker.io/library/tagonly:1"]}]\n' \
                "${ins_full}" "${ins_tagonly}"
            ;;
        "image inspect -- "*) printf '[]\n'; return 125 ;;
        "image exists -- "*) return 1 ;;
        *) return 2 ;;
    esac
}
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"abbc135a7d39"}')"
if printf '%s' "${ins_out}" | jq -e --argjson want "$(jq -c '.[0]' "${ins_fix}/image.json")" \
        '. == {kind: "image", ref: "abbc135a7d39", found: true, object: $want}' >/dev/null \
    && cockpit-validate-contract "${inspect_contract}" "${ins_out}" \
    && [[ "$(cat "${ins_calls}")" == "image inspect -- abbc135a7d39"$'\n'"image ls --format json"$'\n'"image inspect -- ${ins_full}" ]]; then
    ok "inspect-module-image-short-id"
else
    bad "inspect-module-image-short-id" "${ins_out} calls $(tr '\n' ';' < "${ins_calls}")"
fi
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect "{\"kind\":\"image\",\"ref\":\"${ins_full}\"}")"
if printf '%s' "${ins_out}" | jq -e --arg ref "${ins_full}" '.ref == $ref and .found == true and (.object | type) == "object"' >/dev/null \
    && [[ "$(cat "${ins_calls}")" == "image inspect -- ${ins_full}" ]]; then
    ok "inspect-module-image-full-id"
else
    bad "inspect-module-image-full-id" "${ins_out} calls $(tr '\n' ';' < "${ins_calls}")"
fi
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"sha256:5ee1d0c0ffee"}')"
if printf '%s' "${ins_out}" | jq -e '.ref == "sha256:5ee1d0c0ffee" and .found == true' >/dev/null \
    && grep -qx "image inspect -- ${ins_tagonly}" "${ins_calls}" \
    && grep -qx "image inspect -- docker.io/library/tagonly:1" "${ins_calls}"; then
    ok "inspect-module-image-tag-fallback"
else
    bad "inspect-module-image-tag-fallback" "${ins_out} calls $(tr '\n' ';' < "${ins_calls}")"
fi
: > "${ins_calls}"
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"0123456789ab"}')"
if [[ "${ins_out}" == '{"kind":"image","ref":"0123456789ab","found":false}' ]] \
    && grep -qx "image ls --format json" "${ins_calls}" && grep -qx "image exists -- 0123456789ab" "${ins_calls}"; then
    ok "inspect-module-image-no-match"
else
    bad "inspect-module-image-no-match" "${ins_out} calls $(tr '\n' ';' < "${ins_calls}")"
fi
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"alpine-gone"}')"
expect_eq "inspect-module-image-name-not-found" "${ins_out}" '{"kind":"image","ref":"alpine-gone","found":false}'
ins_rt2="${WORK}/runtime-image"
mkdir -p "${ins_rt2}"
ins_out="$(XDG_RUNTIME_DIR="${ins_rt2}" cockpit-module-inspect '{"kind":"image","ref":"abbc135a7d39","mode":"file"}')"
ins_path="$(printf '%s' "${ins_out}" | jq -r '.file.path // empty')"
[[ -f "${ins_path}" ]] && [[ "$(jq -c . "${ins_path}")" == "$(jq -c '.[0]' "${ins_fix}/image.json")" ]] \
    && printf '%s' "${ins_out}" | jq -e '.ref == "abbc135a7d39" and .found == true' >/dev/null
expect_status "inspect-module-image-short-id-file" $? "${ins_out}"
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${*}" in
        "image ls --format json") return 125 ;;
        "image inspect -- "*) printf '[]\n'; return 125 ;;
        "image exists -- "*) return 1 ;;
        *) return 2 ;;
    esac
}
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"abbc135a7d39"}')"
expect_eq "inspect-module-image-list-fails" "${ins_out}" '{"kind":"image","ref":"abbc135a7d39","found":false}'

# inspect module: too-large results and file mode, with podman stubbed and a temporary runtime directory.
ins_big="$(jq -n -c '[{Id: "big", Blob: ("x" * 140000)}]')"
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${2-} ${3-} ${4-}" in
        "inspect -- db") cat "${ins_fix}/${1}.json" ;;
        "inspect -- big") printf '%s\n' "${ins_big}" ;;
        "inspect -- "*) printf '[]\n'; return 125 ;;
        "exists -- "*) return 1 ;;
        *) return 2 ;;
    esac
}
ins_out="$(cockpit-module-inspect '{"kind":"image","ref":"big"}')"
ins_want="$(printf '%s' "${ins_big}" | jq --indent 4 '.[0]' | LC_ALL=C wc -c | tr -d '[:space:]')"
printf '%s' "${ins_out}" | jq -e --argjson want "${ins_want}" '. == {kind: "image", ref: "big", found: true, tooLarge: true, size: $want}' >/dev/null \
    && cockpit-validate-contract "${inspect_contract}" "${ins_out}"
expect_status "inspect-module-too-large" $? "${ins_out:0:300}"

ins_rt="${WORK}/runtime"
mkdir -p "${ins_rt}/podshift"
chmod 700 "${ins_rt}/podshift"
: > "${ins_rt}/podshift/inspect-old.json"
: > "${ins_rt}/podshift/keep.txt"
: > "${ins_rt}/podshift/inspect-new.json"
touch -t 202001010000 "${ins_rt}/podshift/inspect-old.json" "${ins_rt}/podshift/keep.txt"
ins_out="$(XDG_RUNTIME_DIR="${ins_rt}" cockpit-module-inspect '{"kind":"image","ref":"big","mode":"file"}')"
ins_path="$(printf '%s' "${ins_out}" | jq -r '.file.path // empty')"
ins_perm=""
[[ -f "${ins_path}" ]] && ins_perm="$(stat -c '%a' "${ins_path}" 2>/dev/null || stat -f '%Lp' "${ins_path}" 2>/dev/null)"
[[ "${ins_path}" == "${ins_rt}/podshift/inspect-"*.json && "${ins_perm}" == "600" ]] \
    && printf '%s' "${ins_out}" | jq -e --argjson want "${ins_want}" '.kind == "image" and .found == true and .file.size == $want and (has("object") | not)' >/dev/null \
    && [[ "$(LC_ALL=C wc -c < "${ins_path}" | tr -d '[:space:]')" == "${ins_want}" ]] \
    && [[ "$(jq -c . "${ins_path}")" == "$(printf '%s' "${ins_big}" | jq -c '.[0]')" ]] \
    && cockpit-validate-contract "${inspect_contract}" "${ins_out}"
expect_status "inspect-module-file-mode" $? "${ins_out} perm ${ins_perm}"
if [[ ! -e "${ins_rt}/podshift/inspect-old.json" && -e "${ins_rt}/podshift/inspect-new.json" && -e "${ins_rt}/podshift/keep.txt" ]]; then
    ok "inspect-module-file-cleanup"
else
    bad "inspect-module-file-cleanup" "$(ls "${ins_rt}/podshift")"
fi

ins_out="$(XDG_RUNTIME_DIR="${ins_rt}" cockpit-module-inspect '{"kind":"container","ref":"db","mode":"file"}')"
ins_path="$(printf '%s' "${ins_out}" | jq -r '.file.path // empty')"
[[ -f "${ins_path}" ]] && [[ "$(jq -c . "${ins_path}")" == "$(jq -c '.[0]' "${ins_fix}/container.json")" ]]
expect_status "inspect-module-file-mode-small" $? "${ins_out}"

ins_out="$(XDG_RUNTIME_DIR="${ins_rt}" cockpit-module-inspect '{"kind":"container","ref":"gone","mode":"file"}')"
expect_eq "inspect-module-file-mode-not-found" "${ins_out}" '{"kind":"container","ref":"gone","found":false}'

if ins_out="$(XDG_RUNTIME_DIR="${WORK}/no-such-runtime" cockpit-module-inspect '{"kind":"container","ref":"db","mode":"file"}' 2>/dev/null)"; then
    bad "inspect-module-file-no-runtime" "${ins_out}"
else
    ok "inspect-module-file-no-runtime"
fi

: > "${ins_calls}"
if ins_out="$(XDG_RUNTIME_DIR="${ins_rt}" cockpit-module-inspect '{"kind":"container","ref":"db","mode":"zip"}' 2>/dev/null)" || [[ -s "${ins_calls}" ]]; then
    bad "inspect-module-bad-mode" "${ins_out}"
else
    ok "inspect-module-bad-mode"
fi

