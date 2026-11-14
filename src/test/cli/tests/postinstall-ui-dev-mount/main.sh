#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/postinstall-ui-dev-mount
# @group: test
# @category: entry
# @title: Mounting the local UI dist into Cockpit
# @platforms: mac fedora
# @needs: host-check postinstall-vm-check
# @description: Checks Cockpit in the already installed VM, mounts the plugin share when it exists, and prints the Cockpit URL.
# @details:
#   It never creates or starts the VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
