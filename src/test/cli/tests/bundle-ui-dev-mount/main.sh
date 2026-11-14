#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/bundle-ui-dev-mount
# @group: test
# @category: entry
# @title: Building, installing and mounting the UI dist
# @platforms: mac fedora
# @needs: host-check host-container-start build-image build-container-start build-data-copy build-source-tar build-rpm build-rpm-export install-rpm-check install-image install-vm-start install-rpm-copy install-rpm install-validate postinstall-vm-check postinstall-vm-user-password postinstall-ui-dev-mount
# @description: Builds the RPM, installs it in a fresh installer VM, then mounts the local UI dist into Cockpit when it exists.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
