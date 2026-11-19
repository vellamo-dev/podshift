# install-vm-stop

Stops the RPM installer VM (`ps-rpm-installer-fc45`) without removing it. It never touches the base VM.

A VM that is not running shows `not running`. If the VM is already gone, the check still passes and notes `no VM`. The next `install-vm-start` starts it again and keeps what is inside. `install-vm-create` replaces it with a fresh clone from the base.

This test is not part of the bundles. Run it by hand when you want the installer VM stopped.

## Examples

```sh
./test install-vm-stop                    # stop the installer VM, leave it in place
```
