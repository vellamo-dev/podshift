#!/usr/bin/env bash
# @file: run-cockpit-api-cases.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts
# @group: test
# @category: entry
# @description: Runs the Cockpit API cases outside the podshift session, with systemd-run and logger mocked where a session is required.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Usage: run-cockpit-api-cases.sh [<run folder>] [<filter>]
# The cases are in cases/*.sh and run in name order in this shell, so they share PASS, FAIL, the
# mocks and the variables. A filter runs only the case files whose name contains it, for example
# drop. A case file may still rely on one before it, for example 410 on the files of 400.

set +e
umask 022

if ! command -v jq >/dev/null 2>&1; then
    echo "jq was not found"
    echo "Fix: install jq"
    exit 3
fi

PASS=0
FAIL=0
repo=""
here=""
filter="${2:-}"

here="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
# The shared helper is at the same place from every suite's scripts/ folder.
# shellcheck source=../../../shared/fn/utils/find-repo-root.sh
declare -F find-repo-root >/dev/null || source "${here}/../../../shared/fn/utils/find-repo-root.sh"
if ! repo="$(find-repo-root "${here}")"; then
    echo "DETAIL: FAIL repo root was not found"
    exit 2
fi

API="${repo}/src/server/opt/podshift/cockpit/api"
PODSHIFT="${repo}/src/server/opt/podshift"
MOCKS="${here}/mocks"
CASES_WORK="${repo}/artifacts/work/cockpit-capabilities"
mkdir -p "${CASES_WORK}"
WORK="$(mktemp -d)"
ARGV="${WORK}/argv"
LOG="${WORK}/log"
CHILD="${WORK}/child"
STDIN="${WORK}/stdin"
: >"${ARGV}"
: >"${STDIN}"
: >"${LOG}"

# The helpers, one function per file.
for helper in "${here}/fn/"*.sh; do
    # shellcheck source=/dev/null
    source "${helper}"
done
trap cleanup_cases EXIT

# The mocks the handler finds first on PATH.
cp "${MOCKS}/systemd-run.sh" "${WORK}/systemd-run"
cp "${MOCKS}/logger.sh" "${WORK}/logger"
chmod 755 "${WORK}/systemd-run" "${WORK}/logger"

# shellcheck source=/dev/null
source "${API}/fn/cockpit-validate-contract.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-validate-capability.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-load-capability.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-dispatch-action.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-read-request.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-log-request.sh"
# shellcheck source=/dev/null
source "${API}/fn/cockpit-stop-process-tree.sh"
# shellcheck source=/dev/null
source "${API}/modules/ping/module.sh"
# shellcheck source=/dev/null
source "${PODSHIFT}/fn/common/get-podshift-version.sh"

# The list and overview modules, loaded once, so a filter can run one case file on its own.
# shellcheck source=/dev/null
source "${API}/fn/overview/cockpit-overview-unit-state.sh"
# shellcheck source=/dev/null
source "${API}/fn/overview/cockpit-overview-ssh-port.sh"
# load_module also sources the fn/ helpers next to module.sh, which restores the real ones after a stub.
load_module overview-status
load_module overview-usage
load_module overview-info
load_module overview-config
load_module health-check
load_module networks-list
load_module images-list
load_module volumes-list
load_module containers-list
load_module inspect
load_module secrets-list
load_module services-list
load_module service-view
load_module service-logs
load_module quadlets-list
load_module quadlet-view

LAST_OUT=""
LAST_ERR=""
LAST_RC=0
MODE="fail"
EMIT=""
EMIT_RC="0"
LOGGER_FAIL=""

echo "NOTE: mocked session paths are not a live podshift@.host login"

for case_file in "${here}/cases/"*.sh; do
    [[ -z "${filter}" || "$(basename -- "${case_file}")" == *"${filter}"* ]] || continue
    # shellcheck source=/dev/null
    source "${case_file}"
done

echo "NOTE: ${PASS} passed, ${FAIL} failed. Session success was mocked. Live systemd-run was only checked for a failed tunnel."
if [[ "${FAIL}" -ne 0 ]]; then
    exit 2
fi
exit 0
