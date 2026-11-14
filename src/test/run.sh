#!/usr/bin/env bash
# @file: run.sh
# @source-dir: src/test
# @group: test
# @category: entry
# @description: Runs tests from cli/tests on this computer, with everything in their @needs, each test once.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

if [[ -z "${DIR_3C8E61A94F27:-}" ]]; then
    DIR_3C8E61A94F27="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_3C8E61A94F27
fi

# shellcheck source=cli/shared/fn/output/run-task.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/run-task.sh"
# shellcheck source=cli/shared/fn/output/print-run-header.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/print-run-header.sh"
# shellcheck source=cli/shared/fn/output/print-test-header.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/print-test-header.sh"
# shellcheck source=cli/shared/fn/output/print-verdict.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/print-verdict.sh"
# shellcheck source=cli/shared/fn/output/print-summary.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/print-summary.sh"
# shellcheck source=cli/shared/fn/output/show-markdown.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/show-markdown.sh"
# shellcheck source=cli/shared/fn/output/print-test-list.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/print-test-list.sh"
# shellcheck source=cli/shared/fn/output/print-unknown-test.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/print-unknown-test.sh"
# shellcheck source=cli/shared/fn/output/print-help.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/print-help.sh"
# shellcheck source=cli/shared/fn/output/print-test-help.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/print-test-help.sh"
# shellcheck source=cli/shared/fn/output/format-age.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/format-age.sh"
# shellcheck source=cli/shared/fn/output/format-duration.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/format-duration.sh"
# shellcheck source=cli/shared/fn/output/detect-output-mode.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/output/detect-output-mode.sh"
# shellcheck source=cli/shared/fn/log/create-run-folder.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/log/create-run-folder.sh"
# shellcheck source=cli/shared/fn/log/write-log.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/log/write-log.sh"
# shellcheck source=cli/shared/fn/utils/text-distance.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/utils/text-distance.sh"
# shellcheck source=cli/shared/fn/utils/is-version-at-least.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/utils/is-version-at-least.sh"
# shellcheck source=cli/shared/fn/rpm/run-check-in-builder.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/rpm/run-check-in-builder.sh"
# shellcheck source=cli/shared/fn/rpm/run-check-in-ui-builder.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/rpm/run-check-in-ui-builder.sh"
# shellcheck source=cli/shared/fn/rpm/find-exported-rpm.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/rpm/find-exported-rpm.sh"
# shellcheck source=cli/shared/fn/rpm/find-ui-rpm.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/rpm/find-ui-rpm.sh"
# shellcheck source=cli/shared/fn/podshift/is-valid-cli-name.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/podshift/is-valid-cli-name.sh"
# shellcheck source=cli/shared/fn/podshift/podshift-command-list.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/podshift/podshift-command-list.sh"
# shellcheck source=cli/shared/fn/image/build-or-reuse-image.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/image/build-or-reuse-image.sh"
# shellcheck source=cli/shared/fn/image/image-exists.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/image/image-exists.sh"
# shellcheck source=cli/shared/fn/tests/is-platform-allowed.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/is-platform-allowed.sh"
# shellcheck source=cli/shared/fn/tests/require-bash-version.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/require-bash-version.sh"
# shellcheck source=cli/shared/fn/tests/ensure-artifact-dirs.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/ensure-artifact-dirs.sh"
# shellcheck source=cli/shared/fn/tests/validate-test.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/validate-test.sh"
# shellcheck source=cli/shared/fn/tests/list-test-steps.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/list-test-steps.sh"
# shellcheck source=cli/shared/fn/tests/list-test-needs.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/list-test-needs.sh"
# shellcheck source=cli/shared/fn/tests/print-test-title.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/print-test-title.sh"
# shellcheck source=cli/shared/fn/tests/print-test-purpose.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/print-test-purpose.sh"
# shellcheck source=cli/shared/fn/tests/load-local-env.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/tests/load-local-env.sh"
# shellcheck source=cli/shared/fn/vm/vm-podshift-run.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/vm/vm-podshift-run.sh"
# shellcheck source=cli/shared/fn/vm/vm-set-user-password.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/vm/vm-set-user-password.sh"
# shellcheck source=cli/shared/fn/vm/example-network-lines.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/vm/example-network-lines.sh"
# shellcheck source=cli/shared/fn/vm/example-image-lines.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/vm/example-image-lines.sh"
# shellcheck source=cli/shared/fn/vm/example-container-lines.sh
source "${DIR_3C8E61A94F27}/cli/shared/fn/vm/example-container-lines.sh"

# @description: Finds the platform of this computer with the first is-this-os.sh that says yes.
# @arg: $1 - path of the cli folder.
# @stdout: the platform name, for example mac.
# @exitcode: 0 if a platform was found, 1 otherwise.
lab-detect-platform() {
    local cli_dir check
    cli_dir="${1}"
    for check in "${cli_dir}/os-specific"/*/is-this-os.sh; do
        [[ -f "${check}" ]] || continue
        bash "${check}" || continue
        basename "$(dirname "${check}")"
        return 0
    done
    return 1
}

# @description: Runs a test's steps in number order, one line per step with its icon.
# @details:
#   Each step gets the run folder as $1 and returns 0 pass, 2 fail, 3 cannot run here, or anything
#   else for an error. A setup step (100 to 499) that does not pass stops the rest.
# @arg: $1 - path of the test folder.
# @arg: $2 - the platform name, for example mac.
# @arg: $3 - the run folder.
# @arg: $4 - the output mode: interactive or plain.
# @stdout: one line per step.
# @exitcode: 0 if all steps passed, 1 if a step had an error, 2 if a step failed, 3 if a step says it cannot run here or there are no steps.
lab-run-test-steps() {
    local test_dir os run_dir mode steps step file name title rc errors failed blocked
    test_dir="${1}"
    os="${2}"
    run_dir="${3}"
    mode="${4}"
    errors=0
    failed=0
    blocked=0
    steps="$(list-test-steps "${test_dir}" "${os}")" || return 1
    [[ -n "${steps}" ]] || { echo "No steps found in ${test_dir}" >&2; return 3; }
    while IFS= read -r step; do
        file="$(basename "${step}" .sh)"
        name="${file#*-}"
        title="$(sed -n 's/^# @description: //p' "${step}" | head -n 1)"
        # shellcheck source=/dev/null
        source "${step}"
        run-task "${mode}" "${run_dir}/$(basename "${test_dir}").problem" "${title:-${name}}" "${name}" "${run_dir}"
        rc=$?
        case "${rc}" in
            0) ;;
            2) failed=$((failed + 1)) ;;
            3) blocked=$((blocked + 1)) ;;
            *) errors=$((errors + 1)) ;;
        esac
        [[ "${rc}" -eq 0 || "${file%%-*}" -ge 500 ]] || break
    done <<<"${steps}"
    [[ "${errors}" -eq 0 ]] || return 1
    [[ "${blocked}" -eq 0 ]] || return 3
    [[ "${failed}" -eq 0 ]] || return 2
    return 0
}

# @description: Runs one test as its own block: its title, its work under Progress, then its verdict.
# @details:
#   If main.sh defines podshift-test-<name>, that function does the work, otherwise the numbered
#   steps run. If main.sh defines podshift-test-<name>-cleanup, it always runs at the end.
# @arg: $1 - path of the test folder.
# @arg: $2 - the platform name, for example mac.
# @arg: $3 - the run folder, shared by all tests of the run.
# @arg: $4 - the output mode: interactive or plain. podshift-test-<name> gets it as $3.
# @stdout: the test block.
# @exitcode: 0 passed, 1 test error, 2 product failed, 3 cannot run here.
lab-run-one-test() {
    local test_dir os run_dir mode entry rc
    test_dir="${1}"
    os="${2}"
    run_dir="${3}"
    mode="${4}"
    entry="podshift-test-$(basename "${test_dir}")"
    unset -f "${entry}" "${entry}-cleanup"
    # shellcheck source=/dev/null
    source "${test_dir}/main.sh"
    print-test-header "${mode}" "$(print-test-title "${test_dir}")"
    printf '\n    Progress:\n'
    if declare -F "${entry}" >/dev/null; then
        "${entry}" "${run_dir}" "${os}" "${mode}"
    else
        lab-run-test-steps "${test_dir}" "${os}" "${run_dir}" "${mode}"
    fi
    rc=$?
    declare -F "${entry}-cleanup" >/dev/null && { run-task "${mode}" "${run_dir}/$(basename "${test_dir}").problem" "Clean up" "${entry}-cleanup" "${run_dir}" "${os}" "${mode}" || [[ "${rc}" -ne 0 ]] || rc=1; }
    unset -f "${entry}" "${entry}-cleanup"
    print-verdict "${mode}" "${rc}"
    return "${rc}"
}

# @description: Checks that a test's @needs lists its full chain in run order.
# @details:
#   Every test there exists, the test does not list itself, and the needs of each listed test come
#   earlier in the same list.
# @arg: $1 - path of the cli folder.
# @arg: $2 - the test name, for example build-rpm.
# @stderr: what is wrong with the list.
# @exitcode: 0 if the list is valid, 1 otherwise.
lab-validate-test-needs() {
    local cli_dir test_name earlier need inner bad
    cli_dir="${1}"
    test_name="${2}"
    earlier=" "
    bad=0
    for need in $(list-test-needs "${cli_dir}/tests/${test_name}"); do
        [[ "${need}" != "${test_name}" ]] || { echo "${test_name}: @needs lists the test itself" >&2; bad=1; continue; }
        [[ -f "${cli_dir}/tests/${need}/main.sh" ]] || { echo "${test_name}: @needs lists unknown test ${need}" >&2; bad=1; continue; }
        for inner in $(list-test-needs "${cli_dir}/tests/${need}"); do
            [[ "${earlier}" == *" ${inner} "* ]] || { echo "${test_name}: ${need} needs ${inner}, so @needs must list ${inner} before ${need}" >&2; bad=1; }
        done
        earlier="${earlier}${need} "
    done
    return "${bad}"
}

# @description: Makes the run plan: for each requested test, its @needs and then the test, each test only once and in first-seen order.
# @details:
#   Every test on the plan is checked before anything runs.
# @arg: $1 - path of the cli folder.
# @arg: $2 - the platform name, for example mac.
# @arg: $3... - the requested test names.
# @stdout: one test name per line, in run order.
# @stderr: why the plan is not valid.
# @exitcode: 0 if valid, 1 if a @needs list is wrong, 3 if a test cannot run here.
lab-build-run-plan() {
    local cli_dir os plan name item
    cli_dir="${1}"
    os="${2}"
    shift 2
    plan=" "
    [[ $# -gt 0 ]] || { echo "No test given" >&2; return 3; }
    for name in "$@"; do
        if [[ ! "${name}" =~ ^[a-z0-9-]+$ || ! -f "${cli_dir}/tests/${name}/main.sh" ]]; then
            print-unknown-test "${cli_dir}" "${os}" "${name}"
            return 3
        fi
        validate-test "${cli_dir}/tests/${name}" "${os}" || return 3
        lab-validate-test-needs "${cli_dir}" "${name}" || return 1
        for item in $(list-test-needs "${cli_dir}/tests/${name}") "${name}"; do
            [[ "${plan}" == *" ${item} "* ]] || plan="${plan}${item} "
        done
    done
    for item in ${plan}; do
        validate-test "${cli_dir}/tests/${item}" "${os}" || return 3
        printf '%s\n' "${item}"
    done
}

# @description: Runs the requested tests and everything in their @needs, each test once.
# @details:
#   All of them share one run folder. The run header is shown once, then one block per test.
# @arg: $1... - the test names, for example, build-rpm install-rpm, and optionally --plain for plain output and --fresh to rebuild the RPM builder image and the installer VM image instead of reusing them. --help shows the help instead: --help --md the testing guide, --help <test> one test.
# @stdout: the run header and one block per test.
# @stderr: an unknown option, or why the tests cannot run here.
# @exitcode: 0 passed, 1 test error, 2 product failed, 3 cannot run here. With several tests, the worst result wins in the order 1, 2, 3.
lab-cli-run() {
    local cli_dir repo_root arg plain_flag help_flag md_flag fresh_flag tests os plan environment tty output mode run_dir name test_dir worst rc problem rows last_purpose summary helper
    cli_dir="${DIR_3C8E61A94F27}/cli"
    repo_root="$(CDPATH='' cd -P -- "${DIR_3C8E61A94F27}/../.." && pwd -P)"

    # 1. Options and test names.
    plain_flag="no"
    help_flag="no"
    md_flag="no"
    fresh_flag="no"
    tests=()
    for arg in "$@"; do
        case "${arg}" in
            --plain) plain_flag="yes" ;;
            --help) help_flag="yes" ;;
            --md) md_flag="yes" ;;
            --fresh) fresh_flag="yes" ;;
            --*) echo "Unknown option: ${arg}" >&2; return 1 ;;
            *) tests+=("${arg}") ;;
        esac
    done
    if [[ "${help_flag}" == "yes" ]]; then
        [[ "${md_flag}" == "no" || ${#tests[@]} -eq 0 ]] || { echo "--md works only with --help, not with a test" >&2; return 1; }
        (( ${#tests[@]} <= 1 )) || { echo "--help takes one test" >&2; return 1; }
    elif [[ "${md_flag}" == "yes" ]]; then
        echo "--md works only with --help" >&2
        return 1
    fi

    # 2. Which computer?
    if ! os="$(lab-detect-platform "${cli_dir}")"; then
        echo "Unsupported OS: $(uname -s)" >&2
        return 3
    fi

    # 3. Settings and helpers. --fresh turns reuse off before the settings fill in their defaults.
    if [[ "${fresh_flag}" == "yes" ]]; then
        TST_RPM_BUILDER_REUSE="false"
        TST_RPM_INSTALLER_REUSE="false"
    fi
    # shellcheck source=cli/shared/conf/tests.conf
    source "${cli_dir}/shared/conf/tests.conf"
    # shellcheck source=/dev/null
    source "${cli_dir}/os-specific/${os}/conf/os.conf"
    for helper in "${cli_dir}/os-specific/${os}/fn"/*.sh; do
        # shellcheck source=/dev/null
        source "${helper}"
    done
    cd "${repo_root}" || return 1
    load-local-env "${repo_root}" || return 1
    # The whole lab refuses to run on a Fedora computer that is not marked as a desktop.
    [[ "${os}" != "fedora" ]] || check-desktop-flag "${repo_root}" || return 3
    require-bash-version || return $?
    ensure-artifact-dirs "${repo_root}" || return $?
    tty="no"
    [[ ! -t 1 ]] || tty="yes"
    output="$(detect-output-mode "${tty}" "${plain_flag}")"
    mode="${output%% *}"

    # 4. Help instead of a run. It creates no run folder.
    if [[ "${help_flag}" == "yes" ]]; then
        if [[ "${md_flag}" == "yes" ]]; then
            show-markdown "${mode}" "src/test/readme.md"
        elif (( ${#tests[@]} == 1 )); then
            print-test-help "${cli_dir}" "${os}" "${mode}" "${tests[0]}"
        else
            print-help "${cli_dir}" "${os}"
        fi
        return
    fi

    # 5. No test given: the short help, as an error, so an empty run never counts as a pass.
    if (( ${#tests[@]} == 0 )); then
        echo "No test given" >&2
        echo >&2
        print-help "${cli_dir}" "${os}" >&2
        return 1
    fi

    # 6. Which tests, in which order? Nothing runs if the plan is not valid.
    plan="$(lab-build-run-plan "${cli_dir}" "${os}" ${tests[@]+"${tests[@]}"})" || return $?
    environment="$(print-os-version)"

    # 7. Run folder and run header, once per run. The steps decide what to log there.
    run_dir="$(create-run-folder "${repo_root}" "${tests[*]}" "${environment}" "${output}")" || return 1
    print-run-header "${mode}" "${environment}" "${output}" "${run_dir#"${repo_root}/"}/"

    # 8. Each test once, in plan order. The run stops at the first test that does not pass.
    # A maintenance test may remove the run folder, so it is created again for the next test.
    worst=0
    rows=""
    last_purpose="test"
    while IFS= read -r name; do
        test_dir="${cli_dir}/tests/${name}"
        if [[ "${worst}" -ne 0 ]]; then
            rows="${rows}|$(print-test-title "${test_dir}")|"$'\n'
            continue
        fi
        mkdir -p "${run_dir}"
        lab-run-one-test "${test_dir}" "${os}" "${run_dir}" "${mode}"
        rc=$?
        worst="${rc}"
        last_purpose="$(print-test-purpose "${test_dir}")"
        problem=""
        [[ "${rc}" -eq 0 || ! -f "${run_dir}/${name}.problem" ]] || problem="$(head -n 1 "${run_dir}/${name}.problem")"
        rows="${rows}${rc}|$(print-test-title "${test_dir}")|${problem}"$'\n'
    done <<<"${plan}"

    # 9. Summary on screen, and in summary.log unless the last test was maintenance.
    rows="${rows%$'\n'}"
    summary="$(print-summary "${mode}" "${worst}" "${rows}")"
    printf '%s\n\n' "${summary}"
    [[ "${last_purpose}" == "maintenance" ]] || print-summary plain "${worst}" "${rows}" >"${run_dir}/summary.log"
    return "${worst}"
}

lab-cli-run "$@"
