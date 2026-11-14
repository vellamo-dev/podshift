#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/postinstall-vm-user-password
# @group: test
# @category: entry
# @title: Setting the VM user password
# @platforms: mac fedora
# @needs: host-check postinstall-vm-check
# @description: Sets the installer VM login user's password from RPM_VM_USER_PSW, or skips if that variable is empty.
# @details:
#   It never creates or starts the VM. The password is read from the environment or the project's
#   local .env file, and is piped to chpasswd; it is never printed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
