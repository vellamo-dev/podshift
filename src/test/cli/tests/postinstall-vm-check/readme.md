# postinstall-vm-check

Checks that the installer VM is already running and has PodShift installed. It never creates or starts the VM, so tests that work on an installed system can use it first. If the VM is not ready, it stops with exit 3 and tells you how to set it up.

## Examples

```sh
./test postinstall-vm-check
```
