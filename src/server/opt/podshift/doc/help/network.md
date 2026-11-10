# network
Examines and checks the server's external network, and sets which device and initializer PodShift uses for it. The short name is `nw`.

PodShift reads the external IPv4 addresses into `TSV_NW1` to `TSV_NW8`. The device and initializer overrides, `PODSHIFT_NW_DEVICE` and `PODSHIFT_NW_INITIALIZER`, are kept in `/var/lib/podshift/runtime.conf`.

## Usage:

```
podshift network [examine] [--json]      show the network facts and advice
podshift network print                   print TSV_NW1 to TSV_NW8
podshift network check                   check the route, IP, outgoing access and mode
podshift network set                     choose the device from a menu
podshift network set --device <name> [--force]
podshift network set --initializer <name> [--force]
podshift network fix                     repair PodShift's device and initializer settings
podshift network reload                  print export lines for TSV_NW1 to TSV_NW8
```

The initializer is `cloud-init`, `NetworkManager` or `systemd-networkd`. `--force` sets the value without asking. `fix` changes only PodShift's settings, never the system's network.

## Exit codes of `check`:

| Code | Meaning |
| --- | --- |
| `0` | OK. |
| `1` | A warning, for example DHCP mode. |
| `2` | A failure, for example no default route. |

## Examples `(root)`

```shell
sudo podshift network set --device eth0
```

## Examples `(any)`

```shell
podshift nw check
eval "$(podshift nw reload)"
```
