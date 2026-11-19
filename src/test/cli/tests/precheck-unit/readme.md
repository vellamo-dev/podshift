# precheck-unit

Runs the stubbed bats tests for the portable precheck, `utils/portable/precheck.sh`. It needs bats, but no VM, network or root.

The tests point the script at a fake system with `PRECHECK_ROOT` (built by `scripts/precheck-make-root.sh`) and put fake `rpm`, `dnf`, `id`, `getenforce`, `systemctl`, `ss`, `curl`, `ip` and `systemd-detect-virt` commands from `scripts/stubs/` first on `PATH`. They cover Fedora 45 Server and Workstation, Fedora 44, Debian, CoreOS, a read-only root, an installed PodShift, Podman older than 6, an old system Bash, no network, a `dnf` conflict, the clash warnings, `--json`, Bash 3.2, plain output, a wrong option and a cut-off download.

These are not the real `dnf5` or Fedora output. `precheck-vm-clean` runs the script in a real VM.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```sh
./test --plain precheck-unit
```
