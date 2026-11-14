# postinstall-vm-user-password

Sets the password of the VM login user (the current user on this computer, if that account exists in the VM) to `RPM_VM_USER_PSW`. The installer VM must already be running with PodShift installed (see `postinstall-vm-check`). It never creates or starts the VM.

`RPM_VM_USER_PSW` comes from the environment or from the project's local `.env` file (see [Local config](../../../readme.md#local-config)). The password is piped into `chpasswd` in the VM and is never printed. If the variable is empty or missing, the test skips.

`install-vm-start` already sets the password on every new VM with the same helper, so this test is only needed to set it again on a running VM, for example after changing `RPM_VM_USER_PSW`. Unlike `install-vm-start`, it fails when the user is not in the VM.

## Examples

```sh
./test postinstall-vm-user-password
```
