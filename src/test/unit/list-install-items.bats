#!/usr/bin/env bats
# Unit test for list-install-items (src/server/opt/podshift/fn/quadlet/list-install-items.sh).
# Run with: ./test unit-pure-functions

setup() {
    source "${TST_PODSHIFT_DIR}/fn/quadlet/list-install-items.sh"
    S="${BATS_TEST_TMPDIR}/source"
    mkdir -p "${S}"
}

# Creates a file or a folder if the name ends with /, with a modification time: touch -t <YYYYMMDDhhmm>.
make-item() {
    local name stamp
    name="${1}"
    stamp="${2}"
    if [[ "${name}" == */ ]]; then
        mkdir -p "${S}/${name}"
        touch -t "${stamp}" "${S}/${name}"
    else
        : > "${S}/${name}"
        touch -t "${stamp}" "${S}/${name}"
    fi
}

# An empty source has nothing to install.
@test "an empty directory prints nothing and returns 0" {
    run list-install-items "${S}"
    [ "${status}" -eq 0 ]
    [ -z "${output}" ]
}

# A missing source fails silently.
@test "a missing directory returns 1 and prints nothing" {
    run list-install-items "${BATS_TEST_TMPDIR}/nope"
    [ "${status}" -eq 1 ]
    [ -z "${output}" ]
}

# Install order by type: network, volume, image, container.
@test "files go by type: network, volume, image, container" {
    make-item a.container 202601010100
    make-item b.image 202601010200
    make-item c.volume 202601010300
    make-item d.network 202601010400
    run list-install-items "${S}"
    [ "${status}" -eq 0 ]
    [ "${output}" = "${S}/d.network"$'\n'"${S}/c.volume"$'\n'"${S}/b.image"$'\n'"${S}/a.container" ]
}

# Within a type, the oldest file installs first.
@test "inside a type the oldest comes first" {
    make-item new.container 202601010300
    make-item old.container 202601010100
    make-item mid.container 202601010200
    run list-install-items "${S}"
    [ "${output}" = "${S}/old.container"$'\n'"${S}/mid.container"$'\n'"${S}/new.container" ]
}

# Bundles install after single files, oldest first.
@test "bundles come last, oldest first" {
    make-item newer.qdl-bundle/ 202601010200
    make-item web.container 202601010900
    make-item older.qdl-bundle/ 202601010100
    make-item net.network 202601010800
    run list-install-items "${S}"
    [ "${output}" = "${S}/net.network"$'\n'"${S}/web.container"$'\n'"${S}/older.qdl-bundle"$'\n'"${S}/newer.qdl-bundle" ]
}

# A collision suffix does not change a file's type.
@test "the collision suffix does not change the type" {
    make-item web.container.1761612345123456789 202601010100
    make-item db.volume.1761612345123456789 202601010200
    make-item app.qdl-bundle.1761612345123456789/ 202601010050
    run list-install-items "${S}"
    [ "${output}" = "${S}/db.volume.1761612345123456789"$'\n'"${S}/web.container.1761612345123456789"$'\n'"${S}/app.qdl-bundle.1761612345123456789" ]
}

# Equal mtimes sort by name for a stable order.
@test "a tie in time is sorted by name" {
    make-item b.container 202601010100
    make-item a.container 202601010100
    make-item a.container.1761612345123456789 202601010100
    run list-install-items "${S}"
    [ "${output}" = "${S}/a.container"$'\n'"${S}/a.container.1761612345123456789"$'\n'"${S}/b.container" ]
}

# Unknown items sort last; dotfiles are skipped.
@test "unknown items come after the bundles, hidden items are not listed" {
    make-item notes.txt 202601010100
    make-item plain/ 202601010100
    make-item .hidden.container 202601010100
    make-item web.container 202601010900
    make-item app.qdl-bundle/ 202601011000
    run list-install-items "${S}"
    [ "${output}" = "${S}/web.container"$'\n'"${S}/app.qdl-bundle"$'\n'"${S}/notes.txt"$'\n'"${S}/plain" ]
}

# A bundle folder is one item; its contents are not listed.
@test "files inside a bundle folder are not listed" {
    make-item app.qdl-bundle/ 202601010100
    : > "${S}/app.qdl-bundle/web.container"
    run list-install-items "${S}"
    [ "${output}" = "${S}/app.qdl-bundle" ]
}
