#!/usr/bin/env bash
# @file: _load.sh
# @dir: src/deployment/fn
# @group: deployment
# @description: Sources the deployment helper functions.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

set -euo pipefail

PS_DEP_FN_SCRIPT_DIR="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
readonly PS_DEP_FN_SCRIPT_DIR

# Load source files
source "${PS_DEP_FN_SCRIPT_DIR}/utils/print-step.sh"
source "${PS_DEP_FN_SCRIPT_DIR}/generate-rpm-dirs-list.sh"
source "${PS_DEP_FN_SCRIPT_DIR}/deploy-dirs.sh"
source "${PS_DEP_FN_SCRIPT_DIR}/deploy-sh-scripts.sh"
source "${PS_DEP_FN_SCRIPT_DIR}/deploy-files.sh"
source "${PS_DEP_FN_SCRIPT_DIR}/generate-files-list-for-rpm.sh"