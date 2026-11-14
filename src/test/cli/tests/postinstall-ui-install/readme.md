# postinstall-ui-install

Installs the cockpit-podshift RPM built by `ui-rpm-build` in the installer VM, checks it, and leaves it installed. The VM must already be running with PodShift installed (`./test bundle-build-install-validate`). It never creates or starts the VM.

## What it does

1. Skips every step with `cockpit-podshift not found, skipped` when the cockpit-podshift project is missing (`TST_UI_PRESENT`, the same check as `ui-rpm-build`). Otherwise it stops with exit 3 when the VM is not running, PodShift is not installed, or there is no `cockpit-podshift-*.noarch.rpm` in `../cockpit-podshift/artifacts/rpm/` (`TST_UI_RPM_SHARE_DIR`).
2. Checks what the podshift RPM put in the VM: the COPR repo file `/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:vellamo:cockpit-podshift.repo`, and the catalogue `/usr/share/swcatalog/xml/podshift.xml` with `<pkgname>cockpit-podshift</pkgname>`.
3. Removes cockpit-podshift if it is already installed, so every run starts clean. The output is in `ui-remove.log`.
4. Copies the newest local RPM into the VM with scp, the same way as `install-rpm-copy`, and installs it with `dnf install -y`. The output is in `ui-install.log`.
5. Checks the installed package: its version matches the RPM file, `manifest.json` and the metainfo file are there, and `cockpit-bridge --packages` lists `podshift`.
6. Prints the Cockpit URL.

If `postinstall-ui-dev-mount` has bind-mounted the dev build at `/usr/local/share/cockpit/podshift`, Cockpit serves that one instead of the package. The test then prints a note.

## Examples

```sh
./test ui-rpm-build postinstall-ui-install   # build the RPM, then install it in the VM
./test postinstall-ui-install                # install the RPM that is already built
```
