#!/usr/bin/env bash
# @file: module.sh
# @source-dir: src/server/opt/podshift/cockpit/api/modules/service-logs
# @dest-dir: /opt/podshift/cockpit/api/modules/service-logs
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Service logs module: prints the last journal entries of one podshift user service, read as root.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_02E57747DD81:-}" ]]; then
    DIR_02E57747DD81="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_02E57747DD81
fi

# shellcheck source=../../fn/services/cockpit-services-args.sh
declare -F cockpit-services-args >/dev/null || source "${DIR_02E57747DD81}/../../fn/services/cockpit-services-args.sh"
# shellcheck source=../../fn/services/cockpit-services-loaded.sh
declare -F cockpit-services-loaded >/dev/null || source "${DIR_02E57747DD81}/../../fn/services/cockpit-services-loaded.sh"
# shellcheck source=../../fn/services/cockpit-services-log-entries.sh
declare -F cockpit-services-log-entries >/dev/null || source "${DIR_02E57747DD81}/../../fn/services/cockpit-services-log-entries.sh"
# shellcheck source=../../fn/services/cockpit-services-journal-error.sh
declare -F cockpit-services-journal-error >/dev/null || source "${DIR_02E57747DD81}/../../fn/services/cockpit-services-journal-error.sh"
# shellcheck source=../../fn/services/cockpit-services-journal-matches.sh
declare -F cockpit-services-journal-matches >/dev/null || source "${DIR_02E57747DD81}/../../fn/services/cockpit-services-journal-matches.sh"

# @description: Prints the UID of the podshift user.
# @stdout: the UID, from id -u podshift.
# @exitcode: the id exit code.
cockpit-service-logs-uid() {
    id -u podshift 2>/dev/null
}

# @description: Runs systemctl --user against the podshift user manager, from the root realm.
# @arg: $1 - the podshift UID.
# @arg: $@ - further systemctl arguments.
# @stdout: systemctl stdout.
# @exitcode: the systemctl exit code.
cockpit-service-logs-systemctl() {
    local uid
    uid="${1}"
    shift
    systemctl --machine="${uid}@.host" --user "$@"
}

# @description: Runs journalctl as root, so the system journal with the user's entries is readable.
# @arg: $@ - journalctl arguments.
# @stdout: journalctl stdout.
# @exitcode: the journalctl exit code.
cockpit-service-logs-journalctl() {
    journalctl "$@"
}

# @description: Prints the last 100 journal entries of one loaded user service of the podshift user.
# @details:
#   Runs in the root realm, because the podshift user cannot read the journal on Fedora. The unit
#   is checked by cockpit-services-args and must be one of the loaded units that services-list
#   shows: systemctl --machine=<uid>@.host --user list-units --type=service --all, filtered by
#   cockpit-services-loaded; else the result is found false. The UID comes from id -u podshift.
#   Then journalctl -n 100 -o json --no-pager runs as root with the matches of
#   cockpit-services-journal-matches (the --user-unit filter for that UID), without follow, and
#   cockpit-services-log-entries builds the entries. No output, -- No entries --, No journal files
#   were found or an exit code other than 0 give an empty list. Only when stderr shows a
#   permission error (cockpit-services-journal-error) and there is no entry, the result is readable
#   false with error JOURNAL_UNREADABLE, reason (the first stderr line, sanitized) and no entries.
#   When the result does not fit in the 131072-byte module output bound, fewer of the newest
#   entries are kept (50, then 25, then 10, then 1).
# @arg: $1 - action arguments as one JSON object with unit.
# @stdout: one JSON object {unit, found} plus readable and entries, and error and reason when not readable.
# @exitcode: 0 when the result was written, 1 when the arguments are refused, the podshift UID is unknown, or systemctl or jq fails.
cockpit-module-service-logs() {
    local parsed unit uid raw out err_file err_text reason max result bytes
    local -a matches
    parsed="$(cockpit-services-args "${1-}" no)" || return 1
    unit="${parsed%%$'\t'*}"
    uid="$(cockpit-service-logs-uid)" || return 1
    [[ "${uid}" =~ ^[0-9]+$ ]] || return 1
    raw="$(cockpit-service-logs-systemctl "${uid}" list-units --type=service --all --plain --no-legend --no-pager 2>/dev/null)" || return 1
    if ! cockpit-services-loaded "${raw}" | cut -f 1 | grep -F -x -q -- "${unit}"; then
        jq -n -c --arg unit "${unit}" '{unit: $unit, found: false}'
        return
    fi
    err_file="$(mktemp 2>/dev/null)" || return 1
    # The exit code is not used: journalctl can exit 1 when the unit has no entries yet.
    mapfile -t matches < <(cockpit-services-journal-matches "${unit}" "${uid}")
    [[ "${#matches[@]}" -gt 0 ]] || { rm -f -- "${err_file}"; return 1; }
    out="$(cockpit-service-logs-journalctl -n 100 -o json --no-pager "${matches[@]}" 2>"${err_file}")" || true
    err_text="$(head -c 4096 "${err_file}" 2>/dev/null)"
    rm -f -- "${err_file}"
    # Only a permission error with no entries at all is unreadable. No output, -- No entries --
    # or No journal files were found just mean that the unit has no entries.
    if reason="$(printf '%s' "${err_text}" | cockpit-services-journal-error)" && ! printf '%s\n' "${out}" | grep -q '^{'; then
        jq -n -c --arg unit "${unit}" --arg reason "${reason}" \
            '{unit: $unit, found: true, readable: false, error: "JOURNAL_UNREADABLE"} + (if $reason == "" then {} else {reason: $reason} end) + {entries: []}'
        return
    fi
    for max in 100 50 25 10 1; do
        result="$(printf '%s\n' "${out}" | cockpit-services-log-entries "${unit}" "${max}")" || return 1
        bytes="$(printf '%s\n' "${result}" | LC_ALL=C wc -c | tr -d '[:space:]')"
        if (( bytes <= 131072 )); then
            printf '%s\n' "${result}"
            return 0
        fi
    done
    return 1
}
