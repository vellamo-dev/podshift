# reset-failed

Clears failed status from user systemd services and timers.

When a systemd service fails, it locks into a '**failed**' state and often stops trying to restart. Running this command clears that red error flag, resets the failure counters, and allows you to cleanly start or try restarting the service again.

## Usage `(root)`

```shell
podshift reset-failed
```

## Usage `(podshift)`

```shell
reset-failed
```

