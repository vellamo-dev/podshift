# unit-cli-selinux

Runs the stubbed bats tests for `podshift selinux enforce`. It needs bats, but no VM, network or root.

The tests source the module, stub `require-admin`, `getenforce` and `setenforce`, and point `PODSHIFT_SELINUX_CONFIG` at a temporary config file. They cover already enforcing, a config file that is not yet set to enforcing, permissive mode with `--force` or a yes or no answer, disabled, a caller who is not root, and a bad subcommand.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```bash
./test --plain unit-cli-selinux
```
