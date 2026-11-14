# postinstall-ui-dev-mount

Checks Cockpit on the installer VM, which must already be running with PodShift installed (see `postinstall-vm-check`). It never creates or starts the VM. The Cockpit packages, socket and firewall are expected to be already in place from the installer image; the test only checks them. It then checks that the handler `/opt/podshift/cockpit/api/main.sh` exists and prints the Cockpit URL.

If `../cockpit-podshift/dist` exists next to this project, that folder is mounted read-only at `/mnt/cockpit-podshift` and bind-mounted read-only into `/usr/local/share/cockpit/podshift`, so every Cockpit login sees it (Cockpit does not read `/root` for an admin session). The mount lasts until the VM reboots or the bind is unmounted. If `dist/` is missing, the test prints a note and continues. Rebuild the plugin with `./src/dev/run make watch` in cockpit-podshift, then refresh the browser. The steps are safe to run again.

To copy `dist/` over the installed UI files instead, so the copy survives a reboot, use `postinstall-ui-sync-files`. That test does nothing when this mount is already in use.

## Examples

```sh
./test postinstall-ui-dev-mount
```
