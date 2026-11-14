# bundle-ui-dev-mount-examples

The full run for a live UI mount with real data in one go: everything that `bundle-ui-dev-mount` does (build the RPM, install it in a fresh installer VM, validate, set the VM user password when `RPM_VM_USER_PSW` is set, mount the local UI dist when it exists), then `postinstall-examples`, which puts the example secrets, networks, images, volumes and containers from `src/test/fixtures/examples/` into the VM as the `podshift` user. Its own last step prints the Cockpit URL again.

It is composed only through `@needs`, so it is one run with one log folder and one summary. The run stops at the first test that does not pass, so no examples are added when the bundle fails. `./test cleanup-examples` removes the examples again.

## Examples

```sh
./test bundle-ui-dev-mount-examples
```
