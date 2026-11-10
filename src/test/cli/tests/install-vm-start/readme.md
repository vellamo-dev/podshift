# install-vm-start

Creates a fresh installer VM, boots it and waits for systemd. The VM is left running.

- **Mac:** clones the VM from the stopped Lima base VM that install-image keeps (`limactl clone`), with the CPUs, memory and MAC address set on the clone, boots it and waits until it answers over SSH. This takes seconds instead of minutes. At boot the clone runs the config's provision script again, so packages newer than the base are updated then. Lima's vzNAT network gives it its own IP address. Commands run in it as root over SSH with `~/.ssh/podshift-test-vm`, like on Fedora. Apple's `container` is still used for the RPM builder.
- **Fedora:** uploads a fresh copy of the disk from install-image to the libvirt pool `TST_VM_POOL`, creates the VM with `virt-install` and waits until it answers over SSH. Commands run in it as root over SSH with `~/.ssh/podshift-test-vm`.
