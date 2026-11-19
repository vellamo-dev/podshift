#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/install-vm-stop
# @group: test
# @category: entry
# @title: Stopping RPM installer VM
# @platforms: mac fedora
# @needs: host-check
# @description: Stops the RPM installer VM without removing it.
# @details:
#   The next install-vm-start starts it again with what is inside, and install-vm-create replaces
#   it with a fresh clone. The base VM is never touched.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
