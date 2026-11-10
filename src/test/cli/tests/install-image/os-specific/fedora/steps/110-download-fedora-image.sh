#!/usr/bin/env bash
# @file: 110-download-fedora-image.sh
# @source-dir: src/test/cli/tests/install-image/os-specific/fedora/steps
# @group: test
# @category: step
# @description: Download Fedora Server image.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Downloads the Fedora Server image, or reuses the one already downloaded.
# @details:
#   Either way, its SHA256 must match Fedora's checksum file. With TST_RPM_INSTALLER_NO_CACHE=true
#   it always downloads again.
# @arg: $1 - the run folder.
# @stdout: NOTE with what happened, or the problem.
# @exitcode: 0 if the image is ready, 1 otherwise.
download-fedora-image() {
    local run_dir name file sums want got
    run_dir="${1}"
    name="${TST_FEDORA_IMAGE_URL##*/}"
    file="${TST_VM_IMAGE_DIR}/${name}"
    if ! mkdir -p "${TST_VM_IMAGE_DIR}"; then
        write-log "${run_dir}" install-image "Base image: cannot create ${TST_VM_IMAGE_DIR}"
        echo "Cannot create the folder ${TST_VM_IMAGE_DIR}"
        return 1
    fi
    if ! sums="$(curl -fsSL --retry 3 "${TST_FEDORA_CHECKSUM_URL}")"; then
        write-log "${run_dir}" install-image "Base image: checksum file download failed, ${TST_FEDORA_CHECKSUM_URL}"
        echo "Could not download the checksum file ${TST_FEDORA_CHECKSUM_URL}"
        return 1
    fi
    want="$(printf '%s\n' "${sums}" | awk -v f="(${name})" '$1 == "SHA256" && $2 == f { print $4 }')"
    if [[ -z "${want}" ]]; then
        write-log "${run_dir}" install-image "Base image: no checksum for ${name}"
        echo "The checksum file has no line for ${name}"
        return 1
    fi
    if [[ "${TST_RPM_INSTALLER_NO_CACHE}" != "true" && -f "${file}" ]] \
        && [[ "$(sha256sum "${file}" | awk '{ print $1 }')" == "${want}" ]]; then
        write-log "${run_dir}" install-image "Base image: reused ${file}, checksum ok"
        echo "NOTE: reused, checksum ok"
        return 0
    fi
    if ! curl -fsSL --retry 3 -o "${file}.part" "${TST_FEDORA_IMAGE_URL}"; then
        rm -f "${file}.part"
        write-log "${run_dir}" install-image "Base image: download failed, ${TST_FEDORA_IMAGE_URL}"
        echo "Could not download ${TST_FEDORA_IMAGE_URL}"
        return 1
    fi
    got="$(sha256sum "${file}.part" | awk '{ print $1 }')"
    if [[ "${got}" != "${want}" ]]; then
        rm -f "${file}.part"
        write-log "${run_dir}" install-image "Base image: checksum mismatch, got ${got}, want ${want}"
        echo "The downloaded image does not match its checksum"
        return 1
    fi
    mv -f "${file}.part" "${file}"
    write-log "${run_dir}" install-image "Base image: downloaded ${file}, checksum ok"
    echo "NOTE: downloaded, checksum ok"
}
