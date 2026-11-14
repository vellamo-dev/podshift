#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/postinstall-examples
# @group: test
# @category: entry
# @title: Adding example resources
# @platforms: mac fedora
# @needs: host-check postinstall-vm-check
# @description: Puts the example resources from src/test/fixtures/examples into the installer VM as the podshift user.
# @details:
#   Development and test data only, run on demand. It never creates or starts the VM. Running it
#   again leaves the same state. ./test cleanup-examples removes everything it adds.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
