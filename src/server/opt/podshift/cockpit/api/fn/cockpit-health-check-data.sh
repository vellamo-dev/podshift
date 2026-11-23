#!/usr/bin/env bash
# @file: cockpit-health-check-data.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Builds the Cockpit health-check payload from health-check result lines.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_E732843725A5:-}" ]]; then
    DIR_E732843725A5="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_E732843725A5
fi

# @description: Prints the Cockpit health-check object: groups of rows, plus a summary.
# @details:
#   Result lines are group, id, title, status, detail, and an optional fix. Status values from
#   the CLI (OK, INFO, WARN, FAIL, SKIP, ERROR) are mapped to ok, note, warn or fail. The
#   summary label uses the same wording as the CLI Result line. failed is the FAIL count;
#   errors and skipped appear only in the label.
# @arg: $1 - the result lines from health-result, with an optional sixth fix field.
# @arg: $2 - the verdict line from health-verdict.
# @arg: $3 - path to groups.conf, which maps group keys to titles.
# @stdout: one JSON object with groups and summary.
# @exitcode: 0 when the object was written, 1 otherwise.
cockpit-health-check-data() {
    local results verdict_line groups_conf
    local group id title status detail fix
    local prev_group titles_json groups_json rows_json
    local verdict passed issues warnings errors skipped notes
    local state_key label group_label row_state row_json
    results="${1}"
    verdict_line="${2}"
    groups_conf="${3}"

    titles_json="{}"
    if [[ -f "${groups_conf}" ]]; then
        while IFS='=' read -r group title || [[ -n "${group}" ]]; do
            [[ "${group}" == \#* || -z "${group}" ]] && continue
            titles_json="$(jq -c -n --argjson titles "${titles_json}" --arg key "${group}" --arg value "${title}" '$titles + {($key): $value}')" || return 1
        done < "${groups_conf}"
    fi

    groups_json="[]"
    rows_json="[]"
    prev_group=""
    _cockpit_health_flush_group() {
        local key label_text
        key="${1}"
        [[ -n "${key}" ]] || return 0
        label_text="$(jq -r -n --argjson titles "${titles_json}" --arg key "${key}" 'if ($titles | has($key)) then $titles[$key] else $key end')" || return 1
        # Groups and rows are read from files, not arguments: Linux limits one argument to 128 KB.
        groups_json="$(jq -c -n --slurpfile groups <(printf '%s' "${groups_json}") --arg id "${key}" --arg label "${label_text}" \
            --slurpfile rows <(printf '%s' "${rows_json}") \
            '$groups[0] + [{id:$id, label:$label, rows:$rows[0]}]')" || return 1
    }

    while IFS=$'\t' read -r group id title status detail fix || [[ -n "${group}${id}${title}${status}${detail}" ]]; do
        [[ -n "${group}${id}${title}${status}${detail}" ]] || continue
        if [[ -n "${prev_group}" && "${group}" != "${prev_group}" ]]; then
            _cockpit_health_flush_group "${prev_group}" || return 1
            rows_json="[]"
        fi
        prev_group="${group}"
        case "${status}" in
            OK)         row_state="ok" ;;
            INFO|SKIP)  row_state="note" ;;
            WARN)       row_state="warn" ;;
            *)          row_state="fail" ;;
        esac
        row_json="$(jq -c -n \
            --arg id "${id}" \
            --arg label "${title}" \
            --arg state "${row_state}" \
            --arg value "${detail}" \
            --arg fix "${fix}" \
            '{id:$id, label:$label, state:$state, value:$value, fix:(if $fix == "" then null else $fix end)}')" || return 1
        rows_json="$(jq -c -n --slurpfile rows <(printf '%s' "${rows_json}") --argjson row "${row_json}" '$rows[0] + [$row]')" || return 1
    done <<< "${results}"
    _cockpit_health_flush_group "${prev_group}" || return 1

    IFS=$'\t' read -r verdict passed issues warnings errors skipped notes <<< "${verdict_line}"
    passed="${passed:-0}"
    issues="${issues:-0}"
    warnings="${warnings:-0}"
    notes="${notes:-0}"
    case "${verdict}" in
        healthy)         state_key="ok" ;;
        needs-attention) state_key="warn" ;;
        issues-found)    state_key="fail" ;;
        *)               state_key="fail" ;;
    esac
    # shellcheck source=./cockpit-health-check-label.sh
    declare -F cockpit-health-check-label >/dev/null || source "${DIR_E732843725A5}/cockpit-health-check-label.sh"
    label="$(cockpit-health-check-label "${verdict_line}")"
    jq -n -c \
        --slurpfile groups <(printf '%s' "${groups_json}") \
        --arg state "${state_key}" \
        --arg label "${label}" \
        --argjson passed "${passed}" \
        --argjson notes "${notes}" \
        --argjson warnings "${warnings}" \
        --argjson failed "${issues}" \
        '{groups:$groups[0], summary:{state:$state, label:$label, passed:$passed, notes:$notes, warnings:$warnings, failed:$failed}}'
}

