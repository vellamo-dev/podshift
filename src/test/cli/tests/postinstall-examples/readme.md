# postinstall-examples

Puts the example resources from [src/test/fixtures/examples](../../../fixtures/examples/readme.md) into the installer VM, as the `podshift` user, so the Cockpit UI has real objects to show. Development and test data only. It runs only on demand and is not part of any bundle. The installer VM must already be running with PodShift installed (see `postinstall-vm-check`). It never creates or starts the VM.

Secrets (first, so the containers that use them find them):

- Each name in `secrets.list` is created with `podman secret create --env` when missing, with the obviously fake value `example-not-a-real-secret` and the `podshift.example=1` label: `example-db-password`, `example-api-token`, `example-tls-key`, `example-registry-auth` and `example-smtp-password`.
- `example-db-password`, `example-api-token` and `example-tls-key` are used by the secret containers of the Containers step (In use); `example-registry-auth` and `example-smtp-password` stay unused.

Networks:

- `example-quadlet.network` goes into `/home/podshift/.config/containers/systemd/` and `example-quadlet-network.service` is started (source `quadlet`).
- `example-unit-network.service` goes into `/home/podshift/.config/systemd/user/` and is enabled and started (source `unit`).
- Each line of `unmanaged.list` is created with `podman network create` when missing (source `unmanaged`).

Images:

- `example-quadlet.image` goes into `/home/podshift/.config/containers/systemd/` and `example-quadlet-image.service` is started, which pulls `docker.io/library/busybox:latest` (source `quadlet`).
- `example-container.container` goes into the same folder and `example-container.service` is started. It runs `docker.io/library/alpine:latest` with `sleep infinity`, so alpine is In use (source `container`).
- Each line of `unmanaged.list` is pulled with `podman pull` when missing (source `unmanaged`).

Volumes:

- `example-quadlet.volume` goes into `/home/podshift/.config/containers/systemd/` and `example-quadlet-volume.service` is started, which creates `example-quadlet-vol` (source `quadlet`).
- `example-volume.container` goes into the same folder. The step first creates `example-container-vol` with the `podshift.example=1` label, then starts `example-volume-container.service`, which mounts it and runs `sleep infinity` (source `container`, Running).
- Each line of `unmanaged.list` is created with `podman volume create` when missing (source `unmanaged`).
- A small file is written into each example volume, so the Size row is not zero.

Containers (last):

- `example-quadlet-container.container` goes into `/home/podshift/.config/containers/systemd/` and `example-quadlet-container.service` is started. It runs alpine with `sleep infinity` and `AutoUpdate=registry` (source `quadlet`, Running, auto-update active).
- `example-unit-container.service` goes into `/home/podshift/.config/systemd/user/` and is enabled and started. It sets `PODMAN_SYSTEMD_UNIT=%n` and runs an alpine container once, which then exits (source `unit`, Exited).
- Each line of `unmanaged.list` is run with `podman run --replace` on alpine with the `podshift.example=1` label: `example-unmanaged-running` (Running, with the `io.containers.autoupdate=registry` label, so the UI shows that auto-update has no effect), `example-unmanaged-exited` (Exited) and `example-unmanaged-paused` (Paused with `podman pause`). All are source `unmanaged`.
- Containers that use the example secrets: `example-secret-quadlet.container` goes into the same Quadlet folder and `example-secret-quadlet.service` is started. It runs alpine with `sleep infinity` and gets `example-db-password` as the env variable `DB_PASSWORD` and `example-api-token` as the file `/run/secrets/api-token` (source `quadlet`, Running). The `unmanaged.list` line `example-secret-stopped` gets `example-api-token` at `/etc/example/token` and `example-tls-key` at the default `/run/secrets/example-tls-key`, then exits (source `unmanaged`, Exited). So `example-api-token` is shared by two containers.

Running it again replaces the files and keeps existing networks, images, volumes and secrets; the unmanaged example containers are replaced. The last steps check, in the same order, that every example secret (with its label), network, image, volume and container exists, and that each example container is in its expected state. `./test cleanup-examples` removes everything it adds.

## Examples

```sh
./test postinstall-examples
```
