# install-vm-start

Creates a fresh installer VM, boots it and waits for systemd. The VM is left running. If `../cockpit-podshift/dist` exists next to this project, it is mounted read-only in the VM at `/mnt/cockpit-podshift`.

When `RPM_VM_USER_PSW` is set (in the environment or the local `.env`), the last setup step sets it as the password of the VM login user: the current user on this computer, if that account exists in the VM. It is never printed. If the variable is empty or the user is not in the VM, the step is skipped.

- **Mac:** clones the VM from the stopped Lima base VM that install-image keeps (`limactl clone`), with the CPUs, memory and MAC address set on the clone, boots it and waits until it answers over SSH. This takes seconds instead of minutes. The optional plugin share is added on the clone only, not on the base image. At boot the clone runs the config's provision script again, so packages newer than the base are updated then. Lima's vzNAT network gives it its own IP address. Commands run in it as root over SSH with `~/.ssh/podshift-test-vm`, like on Fedora. Apple's `container` is still used for the RPM builder.
- **Fedora:** uploads a fresh copy of the disk from install-image to the libvirt pool `TST_VM_POOL`, creates the VM with `virt-install` and waits until it answers over SSH. The optional plugin share is a read-only virtiofs filesystem. Commands run in it as root over SSH with `~/.ssh/podshift-test-vm`.
