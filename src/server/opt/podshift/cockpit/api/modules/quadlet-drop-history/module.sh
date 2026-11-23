#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-drop-history
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-drop-history
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Quadlet drop history module: prints the latest status of each dropped Quadlet, read from the journal as root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_4BF7E58E2C68:-}" ]]; then
    DIR_4BF7E58E2C68="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_4BF7E58E2C68
fi

# @description: Prints the latest status of each drop from the podshift-drop-history journal records.
# @details:
#   Runs in the root realm, because the podshift user cannot read the journal on Fedora. Runs
#   journalctl -n 1000 -o json --no-pager SYSLOG_IDENTIFIER=podshift-drop-history _UID=<uid> once,
#   and cockpit-drop-history-items keeps the newest record of each drop ID, newest first, at most
#   100. A permission error with no entry gives readable false with JOURNAL_UNREADABLE, as in
#   service-logs. When the result does not fit in 131072 bytes, 50, 25, 10 and then 1 items are
#   tried.
# @arg: $1 - action arguments, {}.
# @stdout: one JSON object {readable, items} plus error and reason when not readable.
# @exitcode: 0 when the result was written, 1 when the podshift UID is unknown or jq fails.
cockpit-module-quadlet-drop-history() {
    local uid out err_file err_text reason max result bytes
    # shellcheck source=./fn/cockpit-quadlet-drop-history-uid.sh
    declare -F cockpit-quadlet-drop-history-uid >/dev/null || source "${DIR_4BF7E58E2C68}/fn/cockpit-quadlet-drop-history-uid.sh"
    # shellcheck source=./fn/cockpit-quadlet-drop-history-journalctl.sh
    declare -F cockpit-quadlet-drop-history-journalctl >/dev/null || source "${DIR_4BF7E58E2C68}/fn/cockpit-quadlet-drop-history-journalctl.sh"
    # shellcheck source=../../fn/services/cockpit-services-journal-error.sh
    declare -F cockpit-services-journal-error >/dev/null || source "${DIR_4BF7E58E2C68}/../../fn/services/cockpit-services-journal-error.sh"
    # shellcheck source=../../fn/drop/cockpit-drop-history-items.sh
    declare -F cockpit-drop-history-items >/dev/null || source "${DIR_4BF7E58E2C68}/../../fn/drop/cockpit-drop-history-items.sh"
    uid="$(cockpit-quadlet-drop-history-uid)" || return 1
    [[ "${uid}" =~ ^[0-9]+$ ]] || return 1
    err_file="$(mktemp 2>/dev/null)" || return 1
    # The exit code is not used: journalctl can exit 1 when there are no entries yet.
    out="$(cockpit-quadlet-drop-history-journalctl -n 1000 -o json --no-pager \
        SYSLOG_IDENTIFIER=podshift-drop-history "_UID=${uid}" 2>"${err_file}")" || true
    err_text="$(head -c 4096 "${err_file}" 2>/dev/null)"
    rm -f -- "${err_file}"
    if reason="$(printf '%s' "${err_text}" | cockpit-services-journal-error)" && ! printf '%s\n' "${out}" | grep -q '^{'; then
        jq -n -c --arg reason "${reason}" \
            '{readable: false, error: "JOURNAL_UNREADABLE"} + (if $reason == "" then {} else {reason: $reason} end) + {items: []}'
        return
    fi
    for max in 100 50 25 10 1; do
        result="$(printf '%s\n' "${out}" | cockpit-drop-history-items "${max}")" || return 1
        bytes="$(printf '%s\n' "${result}" | LC_ALL=C wc -c | tr -d '[:space:]')"
        if (( bytes <= 131072 )); then
            printf '%s\n' "${result}"
            return 0
        fi
    done
    return 1
}
