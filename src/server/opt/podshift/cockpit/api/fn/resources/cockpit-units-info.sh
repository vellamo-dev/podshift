#!/usr/bin/env bash
# @file: cockpit-units-info.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/resources
# @dest-dir: /opt/podshift/cockpit/api/fn/resources
# @host-edit: no
# @group: cockpit
# @category: helper
# @description: Prints the state, load state and source file of systemd user units, read with one systemctl show call.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Reads ActiveState, LoadState, SourcePath and FragmentPath of all units in one systemctl show call.
# @details:
#   systemctl show prints one block per unit, in the given order, with an empty line between them.
#   When the call fails or the block count does not match, for example because one unit name is
#   not valid, each unit is read on its own, and a unit that cannot be read gets empty values. The
#   file is SourcePath (the Quadlet file for a generated unit), else FragmentPath. systemctl runs
#   through the given function, the module's systemctl --user wrapper that the tests replace.
# @arg: $1 - name of the function that runs systemctl --user.
# @arg: $@ - from $2 on, the unit names.
# @stdout: one line per unit, in the given order: <unit><TAB><state><TAB><load state><TAB><file>.
# @exitcode: 0 always.
cockpit-units-info() {
    local runner out one unit line state load source fragment seen n i
    local -a units states loads files
    runner="${1-}"
    units=("${@:2}")
    (( ${#units[@]} > 0 )) || return 0
    out="$("${runner}" show -p ActiveState -p LoadState -p SourcePath -p FragmentPath -- "${units[@]}" 2>/dev/null)" || out=""
    for i in 1 2; do
        states=()
        loads=()
        files=()
        n=0
        seen=0
        state=""
        load=""
        source=""
        fragment=""
        while IFS= read -r line; do
            case "${line}" in
                "")
                    if (( seen == 1 )); then
                        states[n]="${state}"
                        loads[n]="${load}"
                        files[n]="${source:-${fragment}}"
                        n=$((n + 1))
                    fi
                    seen=0
                    state=""
                    load=""
                    source=""
                    fragment=""
                    continue
                    ;;
                ActiveState=*) state="${line#ActiveState=}" ;;
                LoadState=*) load="${line#LoadState=}" ;;
                SourcePath=*) source="${line#SourcePath=}" ;;
                FragmentPath=*) fragment="${line#FragmentPath=}" ;;
            esac
            seen=1
        done <<< "${out}"$'\n'
        (( n != ${#units[@]} )) || break
        # The second pass reads each unit on its own; "-" keeps a block for a unit that gave nothing.
        out=""
        for unit in "${units[@]}"; do
            one="$("${runner}" show -p ActiveState -p LoadState -p SourcePath -p FragmentPath -- "${unit}" 2>/dev/null)" || one=""
            out+="${one:--}"$'\n\n'
        done
    done
    for (( i = 0; i < ${#units[@]}; i++ )); do
        printf '%s\t%s\t%s\t%s\n' "${units[i]}" "${states[i]-}" "${loads[i]-}" "${files[i]-}"
    done
    return 0
}
