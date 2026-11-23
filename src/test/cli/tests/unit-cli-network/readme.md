# unit-cli-network

Runs the stubbed bats tests for `podshift network` (`cli/modules/network/main.sh` and its `fn/` files) and the shared network helpers `nw-list-devices` and `is-cloud-init-present`. It needs bats, but no VM, network or root.

The module runs from the source tree. The network facts (`nw-backend`, `nw-device` and the others), the config loaders and `update-podshift-conf` are stubbed as functions. `curl`, `ls` for `/sys/class/net`, `ip` and, in some tests, `cloud-init` are fakes on PATH, so no real network is touched and nothing is written.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

Run the network tests.

```bash
./test --plain unit-cli-network
```
