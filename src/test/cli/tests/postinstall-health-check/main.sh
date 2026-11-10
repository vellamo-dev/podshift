#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/postinstall-health-check
# @group: test
# @category: entry
# @title: Running health check
# @platforms: mac fedora
# @needs: host-check postinstall-vm-check
# @description: Runs podshift health-check as root in the installed VM and passes only when the system is healthy.
# @details:
#   It reports every warning and issue with its fix.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
