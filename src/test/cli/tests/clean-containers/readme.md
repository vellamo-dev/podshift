# clean-containers

Removes what the tests create: the RPM builder container, every tag of the RPM builder and installer images, on a Mac the RPM installer VM and its Lima base VM, and on Fedora the RPM installer VM, its disk in the libvirt pool and the built VM disk. The downloaded Fedora Server image is kept. Other images, containers and VMs are not touched. It has no needs, so it also works when the disk is full.

## Examples

```sh
./test clean-containers
./test clean-containers clean-logs   # containers, then logs
```
