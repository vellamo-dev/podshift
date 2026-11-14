# bundle-ui-dev-mount

The full run that prepares a live UI mount: builds the RPM, installs it in a fresh installer VM, validates the install, sets the VM login user's password when `RPM_VM_USER_PSW` is set (see `postinstall-vm-user-password`), then runs `postinstall-ui-dev-mount` and prints the URL. If `../cockpit-podshift/dist` exists, it is mounted into the VM. After the run, open the URL, rebuild the plugin in cockpit-podshift with `./src/dev/run make watch`, and refresh the browser. The mount is gone after a reboot, so run `postinstall-ui-dev-mount` again then.

## Examples

```sh
./test bundle-ui-dev-mount
```
