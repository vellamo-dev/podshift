#!/usr/bin/env bash
# is-local-dev-run.sh
# /usr/local/etc/podshift/fn/utils

if [[ -z "${DIR_329985B1E57A:-}" ]]; then
    DIR_329985B1E57A="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_329985B1E57A
fi

# Returns 0 (true) if running from a local dev checkout rather than the installed app.
is-local-dev-run() {
    [[ "${DIR_329985B1E57A}" != /usr/local/* ]]
}

# Executes only when called or sourced with --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    [[ "${1}" == "--now" ]] && is-local-dev-run
fi
