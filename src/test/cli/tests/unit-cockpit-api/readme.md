# unit-cockpit-api

Checks the Cockpit JSON handler, the ping, capabilities, overview, list, inspect, service and Quadlet view modules, and capability contracts on this computer. It needs `jq`.

The successful ping path uses a mock of `systemd-run`. Like the real command, the mock refuses a named FIFO or a regular file as stdout or stderr, so the handler must pass session output and errors through anonymous pipes. It does not enter a real `podshift@.host` session and it does not show that Fedora or Cockpit were tested. A non-root process is refused before stdin is read.

These are unit tests. They do not prove the root gate under a real EUID 0 process, a live session tunnel, Cockpit spawn or Fedora. Those checks belong to future Cockpit integration testing on a local VM.

## Examples

```sh
./test --plain unit-cockpit-api
```
