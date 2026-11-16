#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/clean-containers
# @group: test
# @category: entry
# @title: Cleaning test VMs, containers and images
# @platforms: all
# @purpose: maintenance
# @description: Removes the RPM installer VM, both RPM builder containers and every tag of the test images.
# @details:
#   The containers and images are those of the podshift and cockpit-podshift RPM builders, and the
#   RPM installer image.
#   On Fedora it also removes the VM's disk in the libvirt pool and the built VM disk. Nothing else
#   is touched.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
