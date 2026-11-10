#!/usr/bin/env bash
# @file: podshift-help-main.sh
# @source-dir: src/server/opt/podshift/fn/common
# @dest-dir: /opt/podshift/fn/common
# @host-edit: no
# @group: common
# @category: helper
# @description: Prints the main PodShift help as plain text, with the command list built from the modules and shortcuts.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_7D1B405CEB8B:-}" ]]; then
    DIR_7D1B405CEB8B="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_7D1B405CEB8B
fi

# @description: Prints doc/help/podshift.txt with its {{commands}} line replaced by every module and shortcut.
# @details:
#   The commands are grouped by the user they run as. The realm of a module comes from its @run-as
#   tag, the realm of a shortcut from its folder. Each line shows the first sentence of the
#   @description tag.
# @stdout: the main help text.
# @exitcode: 0 on success, 1 if podshift.txt is missing.
podshift-help-main() {
    local base file line name realm desc group heading first
    local -a rows=()
    base="${DIR_7D1B405CEB8B}/../.."
    [[ -f "${base}/doc/help/podshift.txt" ]] || { echo "Missing help file: ${base}/doc/help/podshift.txt" >&2; return 1; }
    for file in "${base}"/cli/modules/*/main.sh "${base}"/shortcuts/root/*.sh "${base}"/shortcuts/rootless/*.sh; do
        [[ -f "${file}" ]] || continue
        case "${file}" in
            */cli/modules/*)
                name="$(basename -- "$(dirname -- "${file}")")"
                realm="$(sed -n 's/^# @run-as: *//p' "${file}" | head -n 1)"
                ;;
            */shortcuts/root/*)     name="$(basename -- "${file}" .sh)"; realm="root" ;;
            */shortcuts/rootless/*) name="$(basename -- "${file}" .sh)"; realm="podshift" ;;
        esac
        desc="$(sed -n 's/^# @description: *//p' "${file}" | head -n 1)"
        # Only the first sentence.
        desc="${desc%%. *}"
        desc="${desc%.}."
        rows+=("${realm:-any}"$'\t'"${name}"$'\t'"${desc}")
    done
    while IFS= read -r line; do
        if [[ "${line}" != "{{commands}}" ]]; then
            printf '%s\n' "${line}"
            continue
        fi
        first=1
        for group in any podshift root; do
            case "${group}" in
                any)      heading="Run as root or podshift:" ;;
                podshift) heading="Run as podshift:" ;;
                root)     heading="Run as root:" ;;
            esac
            while IFS=$'\t' read -r realm name desc; do
                [[ "${realm}" == "${group}" ]] || continue
                if [[ -n "${heading}" ]]; then
                    [[ "${first}" -eq 1 ]] || echo
                    printf '%s\n' "${heading}"
                    heading=""
                    first=0
                fi
                printf '    %-17s %s\n' "${name}" "${desc}"
            done < <(printf '%s\n' "${rows[@]}" | sort -t $'\t' -k2,2)
        done
    done < "${base}/doc/help/podshift.txt"
}
