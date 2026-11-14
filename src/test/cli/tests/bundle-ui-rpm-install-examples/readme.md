# bundle-ui-rpm-install-examples

PodShift and its Cockpit UI with real data in one go: everything that `bundle-ui-rpm-install` does (build the podshift RPM, install it in a fresh installer VM, validate, build the cockpit-podshift RPM and install it there), then `postinstall-examples`, which puts the example secrets, networks, images, volumes and containers from `src/test/fixtures/examples/` into the VM as the `podshift` user. Its own last step prints the Cockpit URL again.

It is composed only through `@needs`, so it is one run with one log folder and one summary. The run stops at the first test that does not pass, so no examples are added when the bundle fails. If the cockpit-podshift project is missing, the UI tests show every step as `skipped` and the rest still runs. `./test cleanup-examples` removes the examples again.

## Examples

```sh
./test bundle-ui-rpm-install-examples
```
