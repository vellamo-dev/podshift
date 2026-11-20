# precheck-unit

Runs the stubbed bats tests for the portable precheck, `utils/portable/precheck.sh`. It needs bats, but no VM, network or root.

The tests point the script at a fake system with `PRECHECK_ROOT` (built by `scripts/precheck-make-root.sh`) and put fake `rpm`, `dnf`, `id`, `getenforce`, `systemctl`, `ss`, `curl`, `ip`, `nmcli`, `cloud-init` and `systemd-detect-virt` commands from `scripts/stubs/` first on `PATH`. They cover Fedora 45 Server and Workstation, the edition from the `fedora-release-identity-*` package or `VARIANT_ID` (basic, workstation, neither), the cloud from `cloud-id`, `instance-data.json` or `cloud-init` (with and without a zone, a failing or missing `cloud-init`, which source wins, `hc-utils` ignored), the hardware from DMI (including firmware placeholders), the cloud-init state (a cloud server where it ran with user data, a workstation without it, disabled, enabled but not run yet) and the user data note, the login user and skipped check counts, Fedora 44, Debian, CoreOS, a read-only root, an installed PodShift, Podman older than 6, an old system Bash, no network, a `dnf` conflict, the clash warnings, the network checks (DHCP, with and without the cloud-init line, `systemd-networkd` only, no backend, no default route, IPv6 only, another connection name, the cloud-init name with a space, the default `nmconnection` file, missing `nmcli` or `ip`), `--json`, Bash 3.2, plain output, a wrong option and a cut-off download.

These are not the real `dnf5` or Fedora output. `precheck-vm-clean` runs the script in a real VM.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```bash
./test --plain precheck-unit
```
