#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/quadlet-install-log
# @dest-dir: /opt/podshift/cockpit/api/modules/quadlet-install-log
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Quadlet install log module: prints the last journal entries of the install pipeline and the Quadlet units it starts.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_1F82A114DB13:-}" ]]; then
    DIR_1F82A114DB13="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_1F82A114DB13
fi

# @description: Prints the last 100 journal entries of the pipeline tags and of the Quadlet units they start.
# @details:
#   Runs in the root realm, because the podshift user cannot read the journal on Fedora. Runs
#   journalctl -n 2000 -p info -o json --output-fields=... --no-pager with the matches of
#   cockpit-install-log-matches once, so debug lines such as "still settling" are left out. The
#   systemd matches also bring one line per API call and per health check run, so 2000 lines are
#   read and cockpit-install-log-filter keeps the pipeline lines, and the systemd lines (for example
#   Started boy.service) and Podman container events only of the units that PodShift started
#   ("queued start of <unit>") or removed (podshift-qdl-remove lines) in the same 2000 lines.
#   --output-fields keeps only the fields used, so the 2000 lines stay small. Entries are built by
#   cockpit-services-log-entries from the newest 100 kept lines, oldest first, as in service-logs.
#   A permission error with no entry gives readable false with JOURNAL_UNREADABLE. When the result
#   does not fit in 131072 bytes, 50, 25, 10 and then 1 newest entries are tried.
# @arg: $1 - action arguments, {}.
# @stdout: one JSON object {readable, entries} plus error and reason when not readable.
# @exitcode: 0 when the result was written, 1 when the podshift UID is unknown or jq fails.
cockpit-module-quadlet-install-log() {
    local uid out err_file err_text reason max result bytes
    local -a matches
    # shellcheck source=./fn/cockpit-quadlet-install-log-uid.sh
    declare -F cockpit-quadlet-install-log-uid >/dev/null || source "${DIR_1F82A114DB13}/fn/cockpit-quadlet-install-log-uid.sh"
    # shellcheck source=../../fn/drop/cockpit-install-log-matches.sh
    declare -F cockpit-install-log-matches >/dev/null || source "${DIR_1F82A114DB13}/../../fn/drop/cockpit-install-log-matches.sh"
    # shellcheck source=./fn/cockpit-quadlet-install-log-journalctl.sh
    declare -F cockpit-quadlet-install-log-journalctl >/dev/null || source "${DIR_1F82A114DB13}/fn/cockpit-quadlet-install-log-journalctl.sh"
    # shellcheck source=../../fn/services/cockpit-services-journal-error.sh
    declare -F cockpit-services-journal-error >/dev/null || source "${DIR_1F82A114DB13}/../../fn/services/cockpit-services-journal-error.sh"
    # shellcheck source=../../fn/drop/cockpit-install-log-filter.sh
    declare -F cockpit-install-log-filter >/dev/null || source "${DIR_1F82A114DB13}/../../fn/drop/cockpit-install-log-filter.sh"
    # shellcheck source=../../fn/services/cockpit-services-log-entries.sh
    declare -F cockpit-services-log-entries >/dev/null || source "${DIR_1F82A114DB13}/../../fn/services/cockpit-services-log-entries.sh"
    uid="$(cockpit-quadlet-install-log-uid)" || return 1
    [[ "${uid}" =~ ^[0-9]+$ ]] || return 1
    mapfile -t matches < <(cockpit-install-log-matches "${uid}")
    [[ "${#matches[@]}" -gt 0 ]] || return 1
    err_file="$(mktemp 2>/dev/null)" || return 1
    # The exit code is not used: journalctl can exit 1 when there are no entries yet.
    out="$(cockpit-quadlet-install-log-journalctl -n 2000 -p info -o json \
        --output-fields=SYSLOG_IDENTIFIER,_COMM,USER_UNIT,PRIORITY,MESSAGE,_PID,SYSLOG_PID,_HOSTNAME \
        --no-pager "${matches[@]}" 2>"${err_file}")" || true
    err_text="$(head -c 4096 "${err_file}" 2>/dev/null)"
    rm -f -- "${err_file}"
    if reason="$(printf '%s' "${err_text}" | cockpit-services-journal-error)" && ! printf '%s\n' "${out}" | grep -q '^{'; then
        jq -n -c --arg reason "${reason}" \
            '{readable: false, error: "JOURNAL_UNREADABLE"} + (if $reason == "" then {} else {reason: $reason} end) + {entries: []}'
        return
    fi
    out="$(printf '%s\n' "${out}" | cockpit-install-log-filter)" || return 1
    for max in 100 50 25 10 1; do
        result="$(printf '%s\n' "${out}" | cockpit-services-log-entries install-log "${max}" | jq -c '{readable: true, entries: .entries}')" || return 1
        bytes="$(printf '%s\n' "${result}" | LC_ALL=C wc -c | tr -d '[:space:]')"
        if (( bytes <= 131072 )); then
            printf '%s\n' "${result}"
            return 0
        fi
    done
    return 1
}
