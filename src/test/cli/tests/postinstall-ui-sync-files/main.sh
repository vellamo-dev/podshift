#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/postinstall-ui-sync-files
# @group: test
# @category: entry
# @title: Copying the local UI dist over the installed files
# @platforms: mac fedora
# @needs: host-check postinstall-vm-check
# @description: Copies the local UI dist over the installed UI in the VM, or skips when it is missing or the dev mount is in use.
# @details:
#   It never creates or starts the VM. It overwrites the RPM's installed UI files in
#   /usr/share/cockpit/podshift. Reinstalling the RPM restores the packaged version. When the
#   dev mount is in use, it does nothing.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
