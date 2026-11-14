# postinstall-ui-sync-files

Copies `../cockpit-podshift/dist` over the installed UI files in `/usr/share/cockpit/podshift` on the installer VM. The VM must already be running with PodShift installed (see `postinstall-vm-check`), and cockpit-podshift must already be installed there (see `postinstall-ui-install`). It never creates or starts the VM.

The copy overwrites the RPM's installed UI files: files in `dist/` are added or replaced, and files that `dist/` no longer has are removed. Reinstalling the UI RPM restores the packaged version. After a rebuild of `dist/`, run this test again and refresh the browser.

If `/usr/share/cockpit/podshift` or `/usr/local/share/cockpit/podshift` is a mount point, the dev mount from `postinstall-ui-dev-mount` is already in use, so this test does nothing and passes. If `../cockpit-podshift/dist` is missing, every step is skipped.

## Examples

```sh
./test postinstall-ui-sync-files
```
