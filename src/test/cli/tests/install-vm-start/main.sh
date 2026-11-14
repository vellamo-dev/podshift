#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/install-vm-start
# @group: test
# @category: entry
# @title: Starting RPM installer VM
# @platforms: mac fedora
# @needs: host-check host-container-start install-image
# @description: Creates a fresh RPM installer VM, boots it, waits for systemd and sets the VM user password if one is given.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
