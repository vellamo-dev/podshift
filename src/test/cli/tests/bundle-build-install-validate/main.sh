#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/bundle-build-install-validate
# @group: test
# @category: entry
# @title: Building, installing and validating
# @platforms: mac fedora
# @needs: host-check host-container-start build-image build-container-start build-data-copy build-source-tar build-rpm build-rpm-export install-rpm-check install-image install-vm-start install-rpm-copy install-rpm install-validate
# @description: Builds the RPM, installs it in a fresh installer VM, validates the install, then runs the PodShift health check once.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
