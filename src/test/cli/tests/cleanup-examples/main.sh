#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/cleanup-examples
# @group: test
# @category: entry
# @title: Removing example resources
# @platforms: mac fedora
# @purpose: maintenance
# @needs: host-check postinstall-vm-check
# @description: Removes the example resources that postinstall-examples put into the installer VM.
# @details:
#   Only objects and files named example-* that come from src/test/fixtures/examples, or that carry
#   the podshift.example=1 label, are removed. Images cannot carry a label, so the image references
#   named in the example image files and lists are removed, and only when no container uses them. It never creates or starts the VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
