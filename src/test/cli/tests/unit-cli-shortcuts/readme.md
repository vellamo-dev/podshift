# unit-cli-shortcuts

Runs the stubbed bats tests for the shortcuts in `shortcuts/root` and `shortcuts/rootless`, such as `update`, `containers` and `status-user`. It needs bats, but no VM, network or root.

Each shortcut runs from a copy that points at the source tree. `podman`, `systemctl` and `sudo` are fakes, and the caller checks and the rootless config are stubbed. Every call is logged. The tests check that every shortcut refuses any argument, `--help` included, with `<name> takes no arguments. See 'podshift --help <name>'.` and exit 1 before any check or command runs, and that without arguments it runs its caller check and then `podman` or `systemctl`. `podshift <name> --help` is answered by the dispatcher and is tested in `unit-cli-secret`.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

Run the shortcut tests.

```bash
./test --plain unit-cli-shortcuts
```
