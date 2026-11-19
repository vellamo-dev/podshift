#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/install-vm-start
# @group: test
# @category: entry
# @title: Starting RPM installer VM
# @platforms: mac fedora
# @needs: host-check
# @description: Starts the existing RPM installer VM, waits for systemd and sets the VM user password if one is given.
# @details:
#   It keeps what is inside the VM, so run on its own it starts a VM again after install-vm-stop.
#   install-vm-create makes the VM. The bundles run install-vm-create first, so they always get a
#   fresh VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
