# bundle-ui-rpm-install

The full run for PodShift with its Cockpit UI: everything that `bundle-build-install-validate` does (build the podshift RPM, install it in a fresh installer VM, validate, run the health check), then `ui-rpm-build`, which builds the cockpit-podshift RPM into `../cockpit-podshift/artifacts/rpm/`, then `postinstall-ui-install`, which installs that RPM in the VM, checks it and keeps it installed. Its own last step prints the Cockpit URL.

It is composed only through `@needs`, so it is one run with one log folder and one summary. The run stops at the first test that does not pass.

If the cockpit-podshift project is missing next to this one, the two UI tests pass with every step shown as `skipped`, and the podshift part still runs.

## Examples

```sh
./test bundle-ui-rpm-install
```
