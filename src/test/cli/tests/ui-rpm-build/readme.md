# ui-rpm-build

Builds the cockpit-podshift RPM the way COPR does, in its own Fedora container, checks it and exports it.

It uses its own image (`ps-ui-rpm-builder`) and container (`ps-ui-rpm-builder-fc45`). The podshift RPM builder, the test VM and `artifacts/rpm/` of this project are not touched.

## What it does

1. Looks for the cockpit-podshift project, `../cockpit-podshift` by default (`TST_UI_SOURCE`). It needs `cockpit-podshift.spec` and `dist/manifest.json`. If they are missing, every step shows `skipped` and the test passes, so podshift alone still runs.
2. Builds the builder image, or reuses it when it is new enough. The image has only `rpm-build`, `dnf builddep`, `tar`, `gzip` and `rpmlint`.
3. Creates a fresh container, with the cockpit-podshift `artifacts/rpm/` folder mounted at `/share`.
4. Packs the project like the GitHub archive: `SOURCES/<branch>.tar.gz` with the folder `cockpit-podshift-<branch>` inside. `node_modules`, `artifacts`, `.git`, `.idea`, `.run`, `.env` and `.DS_Store` are left out.
5. Installs only the spec's BuildRequires with `dnf builddep`, then runs `rpmbuild -ba`.
6. Checks the RPM: one noarch RPM and one source RPM, the version from the spec, `manifest.json`, `index.js` and the metainfo file inside, and no dependency on `podshift`.
7. Copies the RPM and the source RPM to `../cockpit-podshift/artifacts/rpm/` (`TST_UI_RPM_SHARE_DIR`). Only old `cockpit-podshift-*.rpm` files there are removed first.
8. Runs `rpmlint` as a warning only. Its output is in `ui-rpmlint.log`.

The run folder has `ui-builddep.log`, `ui-rpmbuild.log` and `ui-rpmlint.log`.

`dnf builddep` and the image build download packages, so the container needs network.

## Examples

```sh
./test ui-rpm-build                                     # build and export the cockpit-podshift RPM
./test --fresh ui-rpm-build                             # rebuild the builder image first
TST_UI_SOURCE=/path/to/cockpit-podshift ./test ui-rpm-build   # another checkout
```
