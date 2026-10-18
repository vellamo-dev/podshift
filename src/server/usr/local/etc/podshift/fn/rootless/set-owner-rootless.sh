#!/usr/bin/env bash
# set-owner-rootless.sh
# /usr/local/etc/podshift/fn/rootless
# Changes the ownership of the specified file or directory to the rootless user.
# Directories are processed recursively. Files are changed directly (without -R).

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