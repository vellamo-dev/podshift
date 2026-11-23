#!/usr/bin/env bash
# @file: health-run-live-spinner.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @description: Shows a spinner and a health check title on one line until it is stopped.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Shows a spinner and the check title on one line until it is stopped.
# @arg: $1 - the check title.
# @stdout: the spinner line, redrawn in place.
health-run-live-spinner() {
    local title spinner j
    title="${1}"
    spinner='⠋⠙⠹⠸⠼⠴⠦⠧⠇⠏'
    while true; do
        for ((j = 0; j < ${#spinner}; j++)); do
            printf '\r\033[K        %s %s' "${spinner:j:1}" "${title}"
            sleep 0.1
        done
    done
}
