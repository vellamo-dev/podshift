# host-check

Checks that this computer can run the tests: the host tools including glow, free disk space and the spec file. On a Mac it also checks Apple silicon, the Apple container CLI and its version (for the RPM builder), Lima (for the test VM) and the test VM SSH key. On Fedora it checks the needed packages, and what the test VM will need: KVM, the VM packages (libvirt, virt-install, guestfs-tools, xorriso), access to libvirt without a password, its default network and storage pool, and an SSH key.
