# bundle-build-install-validate

The full run: builds the RPM, installs it in a fresh installer VM and validates the install. Its own last step runs `podshift health-check` in the VM to make sure it works. The health result does not fail the test; the full report is in `health-check.log` in the run folder.

## Examples

```sh
./test bundle-build-install-validate
```
