#!/usr/bin/env bats
# Stubbed tests for the drop ID: set-drop-id, get-drop-id, process-bundle (with its size limits and the .pod refusal), qdl-install and install-item.
# Run with: ./test unit-quadlet-lifecycle

setup() {
    load stubs
    stubs-setup
    source "${FN}/quadlet/set-drop-id.sh"
    source "${FN}/quadlet/get-drop-id.sh"
    W="${BATS_TEST_TMPDIR}/work"
    mkdir -p "${W}"
    ID="018bcfe5-6800-7012-b456-789abcdef012"
    OLD="018bcfe5-6800-7000-8000-000000000000"
    export PODSHIFT_DROP_MAX_BUNDLE_FILES=100
    export PODSHIFT_DROP_MAX_BUNDLE_UNPACKED=1024
}

# mode <file>: octal mode, GNU stat first, BSD stat second.
mode() {
    stat -c '%a' "${1}" 2>/dev/null || stat -f '%Lp' "${1}"
}

@test "set-drop-id writes the ID as line 1 and removes older ID lines" {
    printf '# podshift-drop-id: %s\n[Container]\n# podshift-drop-id: %s\nImage=x\n' "${OLD}" "${OLD}" > "${W}/web.container"
    run set-drop-id "${W}/web.container" "${ID}"
    [ "${status}" -eq 0 ]
    [ "$(cat "${W}/web.container")" = "# podshift-drop-id: ${ID}"$'\n[Container]\nImage=x' ]
    [ "$(mode "${W}/web.container")" = "644" ]
    [ -z "$(find "${W}" -name '.drop-id.*')" ]
}

@test "set-drop-id with a target keeps the source and refuses a bad ID" {
    printf '[Container]\n' > "${W}/web.container"
    mkdir -p "${W}/queue"
    run set-drop-id "${W}/web.container" "${ID}" "${W}/queue/web.container"
    [ "${status}" -eq 0 ]
    [ "$(head -n 1 "${W}/queue/web.container")" = "# podshift-drop-id: ${ID}" ]
    [ "$(cat "${W}/web.container")" = "[Container]" ]
    run set-drop-id "${W}/web.container" not-an-id
    [ "${status}" -eq 1 ]
    run set-drop-id "${W}/missing.container" "${ID}"
    [ "${status}" -eq 1 ]
}

@test "get-drop-id reads a file, a queued zip name and a bundle folder" {
    printf '# podshift-drop-id: %s\n[Container]\n' "${ID}" > "${W}/web.container"
    run get-drop-id "${W}/web.container"
    [ "${output}" = "${ID}" ]
    : > "${W}/shop.zip.${ID}.1761612345123456789"
    run get-drop-id "${W}/shop.zip.${ID}.1761612345123456789"
    [ "${output}" = "${ID}" ]
    mkdir -p "${W}/shop.qdl-bundle"
    printf '[Network]\n' > "${W}/shop.qdl-bundle/a.network"
    printf '# podshift-drop-id: %s\n[Container]\n' "${ID}" > "${W}/shop.qdl-bundle/b.container"
    run get-drop-id "${W}/shop.qdl-bundle"
    [ "${output}" = "${ID}" ]
}

@test "get-drop-id fails without a valid ID" {
    printf '[Container]\n' > "${W}/a.container"
    run get-drop-id "${W}/a.container"
    [ "${status}" -eq 1 ]
    printf '# podshift-drop-id: 018bcfe5-6800-4012-b456-789abcdef012\n' > "${W}/b.container"
    run get-drop-id "${W}/b.container"
    [ "${status}" -eq 1 ]
    : > "${W}/shop.zip"
    run get-drop-id "${W}/shop.zip"
    [ "${status}" -eq 1 ]
}

@test "process-bundle gives every file of a bundle the same ID and logs it" {
    source "${FN}/quadlet/process-bundle.sh"
    mkdir -p "${W}/in" "${W}/source" "${W}/rejected" "${W}/trash"
    printf '[Unit]\nDescription=Shop net\n\n[Network]\nNetworkName=shopnet\n' > "${W}/in/shopnet.network"
    printf '[Unit]\nDescription=Shop web\n\n[Container]\nContainerName=shopweb\nImage=docker.io/library/nginx:latest\nNetwork=shopnet.network\n\n[Service]\nRestart=always\n\n[Install]\nWantedBy=default.target\n' > "${W}/in/shopweb.container"
    (cd "${W}/in" && zip -q "${W}/shop.zip.${ID}" shopnet.network shopweb.container)
    run process-bundle "${W}/shop.zip.${ID}" "${W}/source" "${W}/rejected" "${W}/trash" "${Q}"
    [ "${status}" -eq 0 ]
    [ "$(history-lines)" = "shop.zip validated" ]
    [ "$(history-ids)" = "${ID}" ]
    [ "$(head -n 1 "${W}/source/shop.qdl-bundle/shopnet.network")" = "# podshift-drop-id: ${ID}" ]
    [ "$(head -n 1 "${W}/source/shop.qdl-bundle/shopweb.container")" = "# podshift-drop-id: ${ID}" ]
    [ -z "$(find "${W}/source" -name '.drop-id.*')" ]
}

@test "process-bundle rejects a bundle with a .pod file, as pods are not supported yet" {
    source "${FN}/quadlet/process-bundle.sh"
    mkdir -p "${W}/in" "${W}/source" "${W}/rejected" "${W}/trash"
    printf '[Unit]\nDescription=Shop pod\n\n[Pod]\nPodName=shop\n' > "${W}/in/shop.pod"
    printf '[Unit]\nDescription=Shop web\n\n[Container]\nContainerName=shopweb\nImage=docker.io/library/nginx:latest\n' > "${W}/in/shopweb.container"
    (cd "${W}/in" && zip -q "${W}/shop.zip.${ID}" shop.pod shopweb.container)
    run process-bundle "${W}/shop.zip.${ID}" "${W}/source" "${W}/rejected" "${W}/trash" "${Q}"
    [ "${status}" -eq 0 ]
    [ "$(history-lines)" = "shop.zip failed shop.pod: .pod files are not accepted" ]
    [ ! -e "${W}/source/shop.qdl-bundle" ]
    [ -n "$(find "${W}/rejected" -type f)" ]
}

@test "process-bundle refuses a bundle with too many files before it unpacks" {
    source "${FN}/quadlet/process-bundle.sh"
    mkdir -p "${W}/in" "${W}/source" "${W}/rejected" "${W}/trash"
    printf '[Network]\n' > "${W}/in/a.network"
    printf '[Network]\n' > "${W}/in/b.network"
    (cd "${W}/in" && zip -q "${W}/shop.zip.${ID}" a.network b.network)
    PODSHIFT_DROP_MAX_BUNDLE_FILES=1
    run process-bundle "${W}/shop.zip.${ID}" "${W}/source" "${W}/rejected" "${W}/trash" "${Q}"
    [ "${status}" -eq 0 ]
    [ "$(history-lines)" = "shop.zip refused the bundle has 2 files, more than 1" ]
    [ ! -e "${W}/source/shop.qdl-bundle" ]
    [ -n "$(find "${W}/rejected" -type f)" ]
}

@test "process-bundle refuses a bundle that unpacks over the size limit" {
    source "${FN}/quadlet/process-bundle.sh"
    mkdir -p "${W}/in" "${W}/source" "${W}/rejected" "${W}/trash"
    head -c 3000 /dev/zero | tr '\0' 'a' > "${W}/in/big.network"
    (cd "${W}/in" && zip -q "${W}/shop.zip.${ID}" big.network)
    PODSHIFT_DROP_MAX_BUNDLE_UNPACKED=2
    run process-bundle "${W}/shop.zip.${ID}" "${W}/source" "${W}/rejected" "${W}/trash" "${Q}"
    [ "${status}" -eq 0 ]
    [ "$(history-lines)" = "shop.zip refused the bundle unpacks to 3 KB, more than 2 KB" ]
    [ ! -e "${W}/source/shop.qdl-bundle" ]
}

@test "process-bundle refuses a bundle when a limit is not set" {
    source "${FN}/quadlet/process-bundle.sh"
    mkdir -p "${W}/in" "${W}/source" "${W}/rejected" "${W}/trash"
    printf '[Network]\n' > "${W}/in/a.network"
    (cd "${W}/in" && zip -q "${W}/shop.zip.${ID}" a.network)
    unset PODSHIFT_DROP_MAX_BUNDLE_UNPACKED
    run process-bundle "${W}/shop.zip.${ID}" "${W}/source" "${W}/rejected" "${W}/trash" "${Q}"
    [ "${status}" -eq 0 ]
    [ "$(history-lines)" = "shop.zip refused the bundle limits are not set" ]
    grep -q 'PODSHIFT_DROP_MAX_BUNDLE_UNPACKED is not set to a whole number' "${STUB}/logger.log"
}

@test "qdl-install logs the ID of each item and gives a hand-placed item a new one" {
    mkdir -p "${W}/source" "${W}/staging" "${W}/backup" "${W}/failed" "${W}/trash"
    load-podshift-conf-main() {
        local new
        PODSHIFT_QUADLET_SOURCE_DIR="${W}/source"
        PODSHIFT_QUADLET_STAGING_DIR="${W}/staging"
        PODSHIFT_QUADLET_INSTALLED_BACKUP_DIR="${W}/backup"
        PODSHIFT_QUADLET_FAILED_DIR="${W}/failed"
        PODSHIFT_TRASH_DIR="${W}/trash"
        PODSHIFT_PODMAN_QUADLETS_DIR="${Q}"
    }
    load-podshift-conf-nw() { :; }
    install-item() { rm -rf -- "${1}"; return 0; }
    source "${FN}/service/qdl-install.sh" || true
    printf '# podshift-drop-id: %s\n[Network]\n' "${ID}" > "${W}/source/front.network"
    printf '[Container]\nImage=x\n' > "${W}/source/web.container"
    run podshift-qdl-install
    [ "${status}" -eq 0 ]
    [ "$(history-lines)" = "front.network installing"$'\n'"front.network installed"$'\n'"web.container installing"$'\n'"web.container installed" ]
    [ "$(history-ids | sed -n 1p)" = "${ID}" ]
    new="$(history-ids | sed -n 3p)"
    [ "${new}" != "${ID}" ]
    [ "$(history-ids | sed -n 4p)" = "${new}" ]
    [[ "${new}" =~ ^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$ ]]
}

@test "install-item keeps the ID line in the copy it installs" {
    local installed
    source "${FN}/quadlet/install-item.sh"
    dry-run-quadlet() { return 0; }
    mkdir -p "${W}/source" "${W}/staging" "${W}/backup" "${W}/failed" "${W}/trash"
    printf '# podshift-drop-id: %s\n[Container]\nImage=x\n' "${ID}" > "${W}/source/web.container"
    run install-item "${W}/source/web.container" "${W}/staging" "${Q}" "${W}/backup" "${W}/failed" "${W}/trash"
    [ "${status}" -eq 0 ]
    grep -q "^podman quadlet install .*/web.container$" "${STUB}/calls.log"
    installed="$(find "${W}/backup" -path '*/installed/web.container')"
    [ "$(head -n 1 "${installed}")" = "# podshift-drop-id: ${ID}" ]
}
