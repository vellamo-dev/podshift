# install-vm-start

Starts the existing installer VM and waits for systemd. It does not recreate the VM, so what is inside it is kept. The VM is left running. `install-vm-create` makes the VM, and the bundles run it first, so they always start a fresh VM. Run `install-vm-start` on its own to start a VM again after `install-vm-stop`. If the VM does not exist, it fails with `Fix: ./test install-vm-create`. If it is already running, it notes `already running` and carries on.

When `RPM_VM_USER_PSW` is set (in the environment or the local `.env`), the last setup step sets it as the password of the VM login user: the current user on this computer, if that account exists in the VM. It is never printed. If the variable is empty or the user is not in the VM, the step is skipped. This runs on every start.

- **Mac:** starts the clone with `limactl start`, up to `TST_LIMA_START_TIMEOUT`, and waits until it answers over SSH. At boot the clone runs the config's provision script again, so packages newer than the base are updated then. Lima's vzNAT network gives it its own IP address. Commands run in it as root over SSH with `~/.ssh/podshift-test-vm`, like on Fedora. Apple's `container` is still used for the RPM builder.
- **Fedora:** starts the VM with `virsh start` and waits until it answers over SSH. Commands run in it as root over SSH with `~/.ssh/podshift-test-vm`.

## Examples

```bash
./test install-vm-start                   # start the installer VM again, keep what is inside
./test install-vm-create install-vm-start # fresh VM, then start it
```
