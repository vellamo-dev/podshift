#!/usr/bin/env bash
# @file: set-owner-rootless.sh
# @source-dir: src/server/opt/podshift/fn/rootless
# @dest-dir: /opt/podshift/fn/rootless
# @host-edit: no
# @group: rootless
# @category: helper
# @description: Gives the podshift user ownership of a file or directory.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Changes the owner to podshift; directories recursively, files directly.
# @arg: $1 - file or directory.
# @exitcode: 0 always; failures are logged.
set-owner-rootless() {
    local target
    target="${1}"

    if [ ! -e "${target}" ]; then
        logger -t podshift "set-owner-rootless: target not found: ${target}" 2>/dev/null || true
        return 0
    fi

    if [ -d "${target}" ]; then
        chown -R podshift:podshift -- "${target}" 2>/dev/null \
            || logger -t podshift "set-owner-rootless: chown failed: ${target}" 2>/dev/null || true
    else
        chown podshift:podshift -- "${target}" 2>/dev/null \
            || logger -t podshift "set-owner-rootless: chown failed: ${target}" 2>/dev/null || true
    fi

    return 0
}
