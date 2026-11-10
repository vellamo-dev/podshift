# postinstall-health-check

Runs `podshift --plain health-check --fail-if-unhealthy` as root in the installer VM, which must already be running with PodShift installed (see `postinstall-vm-check`). It passes only when the system is healthy; any warning or issue fails it with exit 2. The step shows the totals and every check by group, with a `Fix:` line under each note, warning and issue. The full report is in `health-check.log` in the run folder.

## Examples

```sh
./test postinstall-health-check
```
