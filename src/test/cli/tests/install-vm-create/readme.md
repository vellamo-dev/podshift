# install-vm-create

Replaces the RPM installer VM with a fresh one, without starting it. The old installer VM is stopped and removed first, so anything installed in it is gone. `install-vm-start` starts the new VM. The base VM is never changed. If `../cockpit-podshift/dist` exists next to this project, the new VM gets a read-only share of it, mounted at `/mnt/cockpit-podshift` once the VM runs.

- **Mac:** clones the VM from the stopped Lima base VM that install-image keeps (`limactl clone`), with the CPUs, memory and MAC address set on the clone. This takes seconds instead of minutes. The optional plugin share is added on the clone only, not on the base image.
- **Fedora:** uploads a fresh copy of the disk from install-image to the libvirt pool `TST_VM_POOL`, writes the VM definition with `virt-install --print-xml` and adds it with `virsh define`, so the VM is not booted. The optional plugin share is a read-only virtiofs filesystem.

The share is set when the VM is created, so to add or change it, run this test again.

## Examples

```bash
./test install-vm-create                  # fresh installer VM, not started
./test install-vm-start                   # start it, or start it again after install-vm-stop
```
