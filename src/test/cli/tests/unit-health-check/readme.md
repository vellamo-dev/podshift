# unit-health-check

Runs the stubbed bats tests for health-check scripts. It needs bats, but no VM, network or root.

The tests source the check, stub the config loaders, and cover a set and an unset environment tag.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```sh
./test --plain unit-health-check
```
