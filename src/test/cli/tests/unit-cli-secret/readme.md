# unit-cli-secret

Runs the stubbed bats tests for `podshift secret`, and for `podshift <command> --help` in the dispatcher. It needs bats, but no VM, network or root.

The tests run the module with the caller check and the rootless config stubbed, and a fake `podman` that saves its arguments and the secret it gets on stdin. They cover a value sent on stdin, a value given as an argument (refused, so it never reaches the shell history or `ps`), `--replace`, a missing name without a terminal, `--unset`, `--help`, and a name that starts with a dash (refused as an unknown option before a value is read, so `podshift secret --help` or a typo such as `--lst` never saves a secret), and that each change prints one line such as `Saved secret <name>.` instead of the Podman secret ID. The hidden prompt on a terminal is not tested here.

`dispatch-help.bats` runs a copy of `podshift.sh` that points at the source tree, with fake `sudo`, `podman`, `dnf` and `systemctl`. It checks that a shortcut, a module or an alias followed by `--help` or `-h` prints that command's help page and runs nothing, that an unknown command with `--help` is still an error, and that `podshift --help <command>` is unchanged.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```bash
./test --plain unit-cli-secret
```
