#!/usr/bin/env bash
# @file: precheck-make-root.sh
# @source-dir: src/test/cli/tests/precheck-unit/scripts
# @group: test
# @category: helper
# @description: Builds a fake system folder for the precheck bats tests.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Builds a fake PRECHECK_ROOT folder with os-release, meminfo, mounts, passwd, an SSH key and a stub bash.
# @details:
#   The stub bash prints STUB_BASH_VERSION, 5.2.37 by default, so a test can fake the system Bash.
# @arg: $1 - the folder to fill.
# @arg: $2 - the os-release ID, for example fedora.
# @arg: $3 - the os-release VERSION_ID, for example 45.
# @arg: $4 - the os-release VARIANT_ID, for example server, or empty for none.
# @arg: $5 - the os-release NAME, for example Fedora Linux.
# @exitcode: 0 always.
precheck-make-root() {
    local dir id ver variant name
    dir="${1}"
    id="${2}"
    ver="${3}"
    variant="${4}"
    name="${5}"
    mkdir -p "${dir}/etc/yum.repos.d" "${dir}/proc" "${dir}/bin" "${dir}/home/ivor/.ssh" "${dir}/run"
    {
        echo "NAME=\"${name}\""
        echo "ID=${id}"
        echo "VERSION_ID=${ver}"
        [ -n "${variant}" ] && echo "VARIANT_ID=${variant}"
        echo "PRETTY_NAME=\"${name} ${ver}\""
    } >"${dir}/etc/os-release"
    printf 'MemTotal:        8000000 kB\n' >"${dir}/proc/meminfo"
    printf '/dev/vda3 / btrfs rw,relatime 0 0\nproc /proc proc rw 0 0\n' >"${dir}/proc/mounts"
    printf 'root:x:0:0:root:/root:/bin/bash\nivor:x:1000:1000:Ivor:/home/ivor:/bin/bash\nnobody:x:65534:65534:Nobody:/:/usr/sbin/nologin\n' >"${dir}/etc/passwd"
    printf 'ssh-ed25519 AAAA test\n' >"${dir}/home/ivor/.ssh/authorized_keys"
    printf '#!/bin/sh\nprintf %%s "${STUB_BASH_VERSION:-5.2.37}"\n' >"${dir}/bin/bash"
    chmod 0755 "${dir}/bin/bash"
    return 0
}
