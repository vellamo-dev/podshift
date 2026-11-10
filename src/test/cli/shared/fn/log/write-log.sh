#!/usr/bin/env bash
# @file: write-log.sh
# @source-dir: src/test/cli/shared/fn/log
# @group: test
# @category: helper
# @description: Writes one line to a log file in the run folder.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Appends a timestamped line to <run_dir>/<name>.log.
# @details:
#   Writes nothing if the run folder is gone.
# @arg: $1 - the run folder.
# @arg: $2 - the log name, for example host-check.
# @arg: $3 - the text to write.
# @exitcode: 0 always.
write-log() {
    local run_dir name text
    run_dir="${1}"
    name="${2}"
    text="${3}"
    [[ -d "${run_dir}" ]] || return 0
    printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "${text}" >>"${run_dir}/${name}.log"
}
