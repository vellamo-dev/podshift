#!/usr/bin/env bash
# @file: cockpit-dispatch-action.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn
# @dest-dir: /opt/podshift/cockpit/api/fn
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Fixed action map: looks up an action or lists all entries; executes nothing.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_B6B2B07AEA96:-}" ]]; then
    DIR_B6B2B07AEA96="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_B6B2B07AEA96
fi

# @description: Looks up one literal action, or lists every entry, in the fixed dispatch map.
# @details:
#   Module paths come only from this map. Nothing is executed and no other process is started. The
#   map is one static table of action and realm in map order. The function is cockpit-module-<action>
#   and the directory is modules/<action> next to this folder, which must exist. List and lookup are
#   built from the same entries, in map order. fields prints the entry as one tab-separated line,
#   and all-fields every entry, so a caller can read them without jq.
# @arg: $1 - list, lookup, fields or all-fields.
# @arg: $2 - action name when the first argument is lookup or fields.
# @stdout: one JSON object for lookup, a JSON array for list, or lines "action TAB function TAB directory TAB realm" for fields (one) and all-fields (every action, in map order). Each JSON entry has action, function, directory and realm.
# @exitcode: 0 when the entry or the list was written, 1 when the action is unknown or the mode is not list, lookup, fields or all-fields.
cockpit-dispatch-action() {
    local mode action base entry name realm directory dir_json line collected found
    local -a table
    mode="${1:-}"
    action="${2:-}"
    case "${mode}" in
        list|lookup|fields|all-fields) ;;
        *)
            return 1
            ;;
    esac
    table=(
        "ping podshift"
        "capabilities root"
        "overview-status root"
        "overview-usage podshift"
        "overview-info podshift"
        "overview-config podshift"
        "health-check root"
        "networks-list podshift"
        "images-list podshift"
        "volumes-list podshift"
        "containers-list podshift"
        "inspect podshift"
        "secrets-list podshift"
        "services-list podshift"
        "service-view podshift"
        "service-logs root"
        "quadlets-list podshift"
        "quadlet-view podshift"
        "config-set podshift"
        "config-unset podshift"
        "env-set root"
        "quadlet-drop podshift"
        "quadlet-drop-history root"
        "quadlet-install-log root"
        "quadlet-remove podshift"
    )
    base="${DIR_B6B2B07AEA96%/*}/modules"
    collected=""
    found=""
    for entry in "${table[@]}"; do
        name="${entry%% *}"
        realm="${entry#* }"
        # list and all-fields walk every entry; lookup and fields stop at the action.
        if [[ "${mode}" == "lookup" || "${mode}" == "fields" ]] && [[ "${name}" != "${action}" ]]; then
            continue
        fi
        directory="${base}/${name}"
        [[ -d "${directory}" ]] || return 1
        if [[ "${mode}" == "fields" || "${mode}" == "all-fields" ]]; then
            printf '%s\t%s\t%s\t%s\n' "${name}" "cockpit-module-${name}" "${directory}" "${realm}"
            [[ "${mode}" == "all-fields" ]] || return 0
            continue
        fi
        dir_json="${directory//\\/\\\\}"
        dir_json="${dir_json//\"/\\\"}"
        line="{\"action\":\"${name}\",\"function\":\"cockpit-module-${name}\",\"directory\":\"${dir_json}\",\"realm\":\"${realm}\"}"
        if [[ "${mode}" == "lookup" ]]; then
            printf '%s\n' "${line}"
            return 0
        fi
        collected="${collected}${found}${line}"
        found=","
    done
    if [[ "${mode}" == "list" ]]; then
        printf '[%s]\n' "${collected}"
        return 0
    fi
    [[ "${mode}" == "all-fields" ]] && return 0
    return 1
}
