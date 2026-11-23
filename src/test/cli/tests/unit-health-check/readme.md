# unit-health-check

Runs the stubbed bats tests for health-check scripts. It needs bats, but no VM, network or root.

The tests source the code under test with stubs. They cover a set and an unset environment tag, and that a check in the podshift session runs in its own named unit, which is stopped on a timeout.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```bash
./test --plain unit-health-check
```
