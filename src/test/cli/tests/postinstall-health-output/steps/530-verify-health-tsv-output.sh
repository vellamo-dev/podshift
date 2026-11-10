#!/usr/bin/env bash
# @file: 530-verify-health-tsv-output.sh
# @source-dir: src/test/cli/tests/postinstall-health-output/steps
# @group: test
# @category: step
# @description: TSV output.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks the --tsv output: four tab-separated fields per check, and a last line with the verdict and eight fields.
# @arg: $1 - the run folder.
# @stdout: NOTE with the number of checks, or the problem.
# @exitcode: 0 if it looks right, 2 otherwise (PodShift problem).
verify-health-tsv-output() {
    local run_dir tsv bad checks
    run_dir="${1}"
    tsv="${run_dir}/health-output.tsv"
    bad="$(awk -F '\t' '$1 == "verdict" { if (NF != 8 || NR != total) print "line " NR ": verdict line"; next } NF != 4 { print "line " NR ": " NF " fields" }' total="$(wc -l <"${tsv}" | tr -d ' ')" "${tsv}")"
    tail -n 1 "${tsv}" | grep -q $'^verdict\t' || bad="${bad:+${bad}$'\n'}no verdict line at the end"
    checks="$(grep -vc $'^verdict\t' "${tsv}")"
    write-log "${run_dir}" postinstall-health-output "TSV output: ${checks} checks${bad:+, problems: ${bad//$'\n'/; }}"
    if [[ -n "${bad}" ]]; then
        echo "The TSV output is not in the expected format"
        printf '%s\n' "${bad}" | head -n 5 | sed 's/^/DETAIL: /'
        return 2
    fi
    echo "NOTE: ${checks} checks"
}
