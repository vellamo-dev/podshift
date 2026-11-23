# unit-cli-update-self

Runs the stubbed bats tests for `podshift update-self`. It needs bats, but no VM, network or root, and no package is changed.

The tests source the module and stub `require-admin`, `rpm`, `dnf` and `sudo` as functions. `sudo` records its arguments, so the tests check the exact `dnf update` line. They cover:

- `cockpit-podshift` not installed: only `podshift` is updated, and the UI is never installed.
- `cockpit-podshift` installed and in an enabled repository: one `dnf update --refresh podshift cockpit-podshift -y` transaction, then the reload hint.
- `cockpit-podshift` installed but in no enabled repository: only `podshift` is updated, with a note on stderr.
- `podshift` in no enabled repository: exit 1 and nothing is updated.
- A failed update (exit 1, no reload hint) and a caller who is not an administrator.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

Run the update-self tests.

```bash
./test --plain unit-cli-update-self
```
