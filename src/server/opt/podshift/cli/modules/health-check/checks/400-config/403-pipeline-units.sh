#!/usr/bin/env bash
# @file: 403-pipeline-units.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/checks/400-config
# @dest-dir: /opt/podshift/cli/modules/health-check/checks/400-config
# @host-edit: no
# @group: health-check
# @category: check
# @title: Quadlet pipeline units
# @run-as: podshift
# @description: Verifies the drop, drop safety, validation and install watcher units are enabled and active.
# @rationale: Without them, dropped quadlets are not picked up, validated or installed.
# @fix: As the podshift user: systemctl --user enable --now podshift-drop.path podshift-drop-safety.timer podshift-qdl-validate.path podshift-qdl-install.path
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_2F105892F9E9:-}" ]]; then
    DIR_2F105892F9E9="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_2F105892F9E9
fi

# @description: Runs the pipeline-units check.
# @stdout: one TSV line: pipeline-units<TAB><status><TAB><detail>.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.

health-check-pipeline-units() {
    local unit bad
    bad=""
    for unit in podshift-drop.path podshift-drop-safety.timer podshift-qdl-validate.path podshift-qdl-install.path; do
        if ! systemctl --user is-enabled --quiet "${unit}" 2>/dev/null; then
            bad+="${bad:+, }${unit} not enabled"
        elif ! systemctl --user is-active --quiet "${unit}" 2>/dev/null; then
            bad+="${bad:+, }${unit} inactive"
        fi
    done
    if [[ -z "${bad}" ]]; then
        printf 'pipeline-units\tOK\tenabled and active\n'
        return 0
    fi
    printf 'pipeline-units\tFAIL\t%s\n' "${bad}"
    return 2
}

[[ "${BASH_SOURCE[0]}" == "${0}" ]] && health-check-pipeline-units
