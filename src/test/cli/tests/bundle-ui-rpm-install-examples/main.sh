#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/bundle-ui-rpm-install-examples
# @group: test
# @category: entry
# @title: Installing PodShift and its UI with example resources
# @platforms: mac fedora
# @needs: host-check host-container-start build-image build-container-start build-data-copy build-source-tar build-rpm build-rpm-export install-rpm-check install-image install-vm-start install-rpm-copy install-rpm install-validate bundle-build-install-validate ui-rpm-build postinstall-ui-install bundle-ui-rpm-install postinstall-vm-check postinstall-examples
# @description: Runs bundle-ui-rpm-install, then puts the example resources into the fresh installer VM.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
