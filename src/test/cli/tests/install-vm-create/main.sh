#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/install-vm-create
# @group: test
# @category: entry
# @title: Creating RPM installer VM
# @platforms: mac fedora
# @needs: host-check host-container-start install-image
# @description: Replaces the RPM installer VM with a fresh one from install-image, without starting it.
# @details:
#   The old installer VM is stopped and removed first. install-vm-start starts the new one. The
#   base VM is never changed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
