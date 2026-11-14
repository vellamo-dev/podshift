# cleanup-examples

Removes the example resources that `postinstall-examples` put into the installer VM. It runs only on demand and is not part of `clean-all` or any bundle. It never creates or starts the VM.

Containers (runs first, so no example container holds the alpine image or an example secret):

- Disables and stops `example-unit-container.service`, stops `example-quadlet-container.service` and `example-secret-quadlet.service` (Quadlet removes the containers), deletes only the `example-*` files named in [src/test/fixtures/examples/containers](../../../fixtures/examples/readme.md), then runs `daemon-reload`.
- Removes the example containers by name (the Quadlet and service containers and the names in `unmanaged.list`, including `example-secret-stopped`) with `podman rm --force`, only when they exist.

Volumes (so the example volume container no longer holds the alpine image):

- Stops `example-volume-container.service` (Quadlet removes the container) and `example-quadlet-volume.service`, deletes only the `example-*` files named in [src/test/fixtures/examples/volumes](../../../fixtures/examples/readme.md), then runs `daemon-reload`.
- Removes volumes whose name starts with `example-` and that have the `podshift.example=1` label, without `--force`, so a volume still in use is reported and kept.

Images (after the volumes):

- Stops `example-container.service` (Quadlet removes the container) and `example-quadlet-image.service`, deletes only the `example-*` files named in [src/test/fixtures/examples/images](../../../fixtures/examples/readme.md) from `/home/podshift/.config/containers/systemd/`, then runs `daemon-reload`.
- Removes the images those files use and the ones in `unmanaged.list` (busybox, alpine, hello-world). Images cannot carry the example label, so this goes by reference. They are removed without `--force`, so an image still used by another container is reported and kept.

Networks:

- Stops and disables the example units, and deletes only the `example-*` files named in [src/test/fixtures/examples/networks](../../../fixtures/examples/readme.md) from `/home/podshift/.config/containers/systemd/` and `/home/podshift/.config/systemd/user/`, then runs `daemon-reload`.
- Removes networks whose name starts with `example-` and that have the `podshift.example=1` label, plus the names in `unmanaged.list`. Networks are removed without `--force`, so a network still used by a container is reported and kept.

Secrets (runs last, after every example container that uses them is gone):

- Removes the secrets named in `secrets.list` that have the `podshift.example=1` label; a secret without the label is reported and kept.

The last steps check, in the same order, that no example file, labeled network, labeled volume, labeled container, named example container or example secret is left.

## Examples

```sh
./test cleanup-examples
```
