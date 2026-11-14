# Runtime Data

This directory holds PodShift's mutable, user-editable runtime state. 

## runtime.conf

The PodShift runtime configuration is written to `/var/lib/podshift/runtime.conf`:

- `TSV_ENV` - the environment tag (e.g. `dev`, `staging`, `prd`). It is empty on a fresh install until set with `podshift env --set <tag>` as root.
- `PODSHIFT_NW_INITIALIZER` - how the target's network addresses are discovered.
- `PODSHIFT_NW_DEVICE` - the network device to read.
