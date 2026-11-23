# unit-cockpit-api

Checks the Cockpit JSON handler, the ping, capabilities, overview, list, inspect, service, Quadlet view, config (`config-set`, `config-unset`, `env-set`) and Drop Quadlet (`quadlet-drop`, `quadlet-drop-history`, `quadlet-install-log`, `quadlet-remove`) modules, the drop IDs that `drop-process` gives a dropped Quadlet file (line 1) and zip (in the queued name), and capability contracts on this computer. It needs `jq`.

It also checks the `reason=` and `detail=` fields of the `podshift-api` journal line for a failed request (module, output, contract, size, timeout, realm), and that the containers and secrets lists keep working when a batch `podman container inspect` fails.

The successful ping path uses a mock of `systemd-run`. Like the real command, the mock refuses a named FIFO or a regular file as stdout or stderr, so the handler must pass session output and errors through anonymous pipes. It does not enter a real `podshift@.host` session and it does not show that Fedora or Cockpit were tested. A non-root process is refused before stdin is read.

These are unit tests. They do not prove the root gate under a real EUID 0 process, a live session tunnel, Cockpit spawn or Fedora. Those checks belong to future Cockpit integration testing on a local VM.

## Layout

`scripts/run-cockpit-api-cases.sh` sets up the work folder, the mocks and the modules, then sources `scripts/cases/*.sh` in name order in one shell, so the cases share the counters and variables. The helpers such as `ok`, `bad`, `expect_eq`, `expect_status` and `load_module` are in `scripts/fn/`, one function per file, and the `systemd-run`, `logger` and `setsid` mocks are in `scripts/mocks/` and are copied into the work folder. A second argument runs only the case files whose name contains it; a case file may still need one before it, for example `410-drop-process.sh` needs `400-drop-upload.sh`. A failed case prints each extra line of its reason as its own `DETAIL:` line. A plain check is written as the check on its own line followed by `expect_status "<case>" $? "<reason>"`, or `expect_eq` for two texts; a check whose reason runs a command keeps its if/ok/else/bad block, so the command runs only on a failure.

## Examples

```bash
./test --plain unit-cockpit-api
```

Run only the drop cases, without ./test:

```bash
bash src/test/cli/tests/unit-cockpit-api/scripts/run-cockpit-api-cases.sh "" drop
```
