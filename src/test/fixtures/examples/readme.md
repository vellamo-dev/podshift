# Example resources

Development and test data only. These files are never packaged or installed by the RPM. They give the Cockpit UI real objects to show on a test VM.

- `./test postinstall-examples` puts them in the installer VM as the `podshift` user.
- `./test cleanup-examples` removes them again.

Both run only on demand. Neither is part of a bundle.

## Rules

- Every object name starts with `example-`.
- Every object that can carry a label has `podshift.example=1`.
- Cleanup removes only objects and files that match both rules, so it never touches real data.
- Images are the exception: a pulled image has a fixed name and no label of ours. Cleanup removes the image references used by the files in `images/` and listed in its `unmanaged.list`, without `--force`, so an image still used by any container is kept.

## Structure

One folder per resource type. `secrets/`, `networks/`, `images/`, `volumes/` and `containers/` exist, in the order `postinstall-examples` adds them; `cleanup-examples` removes them in the reverse order, so the containers go before the secrets they use.

### secrets/

| File | Shown in the UI | Where it goes in the VM |
| --- | --- | --- |
| `secrets.list` | `example-db-password`, `example-api-token`, `example-tls-key` (In use); `example-registry-auth`, `example-smtp-password` (Unused) | read by the test; each line is a secret name, created with `podman secret create --env` and the fake value `example-not-a-real-secret` when missing |

Lines that are empty or start with `#` are ignored. The secret values are fake and never shown by the UI.

### networks/

| File | Source in the UI | Where it goes in the VM |
| --- | --- | --- |
| `example-quadlet.network` | quadlet | `/home/podshift/.config/containers/systemd/`, started as `example-quadlet-network.service` |
| `example-unit-network.service` | unit | `/home/podshift/.config/systemd/user/`, enabled and started |
| `unmanaged.list` | unmanaged | read by the test; each line is `<name> <podman network create options>`, created with `podman network create` |

Lines in `unmanaged.list` that are empty or start with `#` are ignored.

### images/

| File | Source in the UI | Where it goes in the VM |
| --- | --- | --- |
| `example-quadlet.image` | quadlet (busybox) | `/home/podshift/.config/containers/systemd/`, started as `example-quadlet-image.service` |
| `example-container.container` | container (alpine) | `/home/podshift/.config/containers/systemd/`, started as `example-container.service`; runs `sleep infinity` |
| `unmanaged.list` | unmanaged (hello-world) | read by the test; each line is a full image reference, pulled with `podman pull` |

Lines in `unmanaged.list` that are empty or start with `#` are ignored.

### volumes/

| File | Source in the UI | Where it goes in the VM |
| --- | --- | --- |
| `example-quadlet.volume` | quadlet (`example-quadlet-vol`) | `/home/podshift/.config/containers/systemd/`, started as `example-quadlet-volume.service` |
| `example-volume.container` | container (`example-container-vol`) | `/home/podshift/.config/containers/systemd/`, started as `example-volume-container.service`; the step creates the labeled volume first |
| `unmanaged.list` | unmanaged (`example-unmanaged`) | read by the test; each line is `<name> <podman volume create options>`, same format as the networks list |

Lines in `unmanaged.list` that are empty or start with `#` are ignored.

### containers/

| File | Source in the UI | Where it goes in the VM |
| --- | --- | --- |
| `example-quadlet-container.container` | quadlet (`example-quadlet-container`, Running, `AutoUpdate=registry`) | `/home/podshift/.config/containers/systemd/`, started as `example-quadlet-container.service`; runs `sleep infinity` |
| `example-unit-container.service` | unit (`example-unit-container`, Exited) | `/home/podshift/.config/systemd/user/`, enabled and started; runs `echo` once with `PODMAN_SYSTEMD_UNIT=%n` |
| `example-secret-quadlet.container` | quadlet (`example-secret-quadlet`, Running): `example-db-password` as env `DB_PASSWORD`, `example-api-token` as file `/run/secrets/api-token` | `/home/podshift/.config/containers/systemd/`, started as `example-secret-quadlet.service`; runs `sleep infinity` |
| `unmanaged.list` | unmanaged (`example-unmanaged-running`, `-exited`, `-paused`; `example-secret-stopped`, Exited: `example-api-token` as file `/etc/example/token`, `example-tls-key` as file `/run/secrets/example-tls-key`) | read by the test; each line is `<name> <running, exited or paused> <podman run options>`, run with `podman run --replace` on alpine |

Lines in `unmanaged.list` that are empty or start with `#` are ignored.

The two secret containers use the secrets from `secrets/`, which are added first and removed last.
