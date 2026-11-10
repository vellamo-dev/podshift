#!/usr/bin/env bash
# @file: make-tar-from-source.sh
# @source-dir: src/test/cli/tests/build-source-tar/scripts
# @group: test
# @category: entry
# @description: Packs the PodShift source tree into the RPM source tarball and stages postun.sh.
# @details:
#   Runs inside the RPM builder container, where the source is in /builder/input/podshift-<branch>.
# @arg: $1 - the branch name, from the spec's %global branch line.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

branch="${1:?branch name missing}"

cd /builder/input || exit 1

find . -name ".DS_Store" -delete
find . -name ".gitattributes" -delete
find . -name ".gitignore" -delete
find . -type d -name ".idea" -exec rm -rf {} +
find . -type d -name ".git" -exec rm -rf {} +
find . -type d -name ".run" -exec rm -rf {} +

tar --format=gnu \
    --no-acls --no-xattrs --no-selinux \
    --numeric-owner \
    -czf "/builder/output/SOURCES/${branch}.tar.gz" -C . "podshift-${branch}"

# Stage postun.sh as Source1 for the %postun -f %{SOURCE1} scriptlet.
cp -p "podshift-${branch}/src/server/opt/podshift/rpm/postun.sh" /builder/output/SOURCES/postun.sh
