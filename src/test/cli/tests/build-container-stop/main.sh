#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/build-container-stop
# @group: test
# @category: entry
# @title: Stopping RPM builder containers
# @platforms: all
# @needs: host-check host-container-start
# @description: Stops the RPM builder containers after use, so they free their memory. They are not removed.
# @details:
#   The next build-container-start or ui-rpm-build replaces them with fresh containers. With
#   TST_KEEP_BUILDERS=true they are kept running, for debugging.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
