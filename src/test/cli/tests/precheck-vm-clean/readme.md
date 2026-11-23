# precheck-vm-clean

Runs the portable precheck, `utils/portable/precheck.sh`, in a freshly created installer VM without PodShift. It passes when the result is Ready (exit 0) or Ready with warnings (exit 1). This is the first real check of the script against Fedora, `dnf5` and the Podman that Fedora offers; `precheck-unit` only uses fake output.

Steps:

1. Copies the script into `TST_PRECHECK_VM_DIR` (`/tmp/podshift-precheck`) in the VM.
2. Runs it with `--plain` and saves the output to `precheck-plain.log` in the run folder. Warnings and blockers are shown as details.
3. Runs it with `--json` and saves `precheck.json`. `result` and `exit_code` are read with `sed`, so no `jq` is needed. They must match the real exit code and the plain run.
4. Removes the copied folder from the VM.

Settings in `src/test/cli/shared/conf/tests.conf`:

| Setting | Default | What it does |
| ------- | ------- | ------------ |
| `TST_PRECHECK_AS_ROOT` | `true` | `true` runs the check as root, so the `dnf` dry run is included. `false` runs it as your user in the VM (or `nobody`), to see the path without root. |
| `TST_PRECHECK_MODE` | `both` | `plain`, `json` or `both`: which output to run and check. |
| `TST_PRECHECK_VM_DIR` | `/tmp/podshift-precheck` | Folder in the VM that the script is copied to and removed from. |

The test creates a new VM through its `@needs`, so it replaces the current installer VM.

## Examples

```bash
./test --plain precheck-vm-clean
TST_PRECHECK_AS_ROOT=false ./test --plain precheck-vm-clean
TST_PRECHECK_MODE=json ./test --plain precheck-vm-clean
```
