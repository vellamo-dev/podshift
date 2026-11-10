#!/usr/bin/env bash
# @file: health-route.sh
# @source-dir: src/server/opt/podshift/cli/modules/health-check/fn
# @dest-dir: /opt/podshift/cli/modules/health-check/fn
# @host-edit: no
# @group: health-check
# @category: helper
# @unit-test: yes
# @description: Decides how one health check is started.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Decides how a check is started, from its realm and the caller.
# @arg: $1 - the check's @run-as value: any, podshift, or root.
# @arg: $2 - the caller: root, podshift, or other.
# @stdout: direct, podshift-session, skip-podshift, skip-root, or invalid.
# @exitcode: 0 always.
health-route() {
    local run_as caller
    run_as="${1}"
    caller="${2}"
    case "${run_as}:${caller}" in
        any:*)             echo "direct" ;;
        podshift:podshift) echo "direct" ;;
        podshift:root)     echo "podshift-session" ;;
        podshift:other)    echo "skip-podshift" ;;
        root:root)         echo "direct" ;;
        root:*)            echo "skip-root" ;;
        *)                 echo "invalid" ;;
    esac
    return 0
}
