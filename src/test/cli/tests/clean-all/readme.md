# clean-all

Runs `clean-containers`, `clean-rpm-output`, `clean-tmp`, `clean-work` and `clean-logs`, then checks that nothing is left: no container, images, RPM packages, temporary or work files or logs, and no test VM (on a Mac also no Lima base VM, on Fedora no VM disks).

## Examples

```sh
./test clean-all
```
