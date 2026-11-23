# quadlet
Removes an installed Quadlet file or app of the podshift user.

A name with a Quadlet extension, such as `web.container`, is a single file. Any other name is an app: the name of the dropped `.zip` without `.zip`.

The removal is refused while another installed Quadlet refers to it, or a container that is not its own uses one of its networks or volumes. The message says what uses it.

The units are stopped first, containers before pods, images, volumes and networks. Each unit gets `PODSHIFT_QUADLET_STOP_TIMEOUT` seconds to stop. Then the files are removed with `podman quadlet rm`, the failed state of the units is reset, and leftover containers of the units, pods and networks are removed. Podman volumes are kept unless `--volumes` is given. Images are kept.

PodShift never replaces an installed Quadlet. To change one, remove it, then drop the new version.

An admin runs it as the podshift user: `podshift` switches with `sudo -u podshift -i`.

## Usage:

```
podshift quadlet rm <file|app> [--volumes] [--yes]
```

`--yes` skips the question. Each step is logged with the journal tag `podshift-qdl-remove`. A removal is not a drop, so it is not in the drop history.

## Examples `(root)`

Remove the single file web.container:

```bash
sudo podshift quadlet rm web.container
```

## Examples `(podshift)`

Remove the single file web.container:

```bash
podshift quadlet rm web.container
```

Remove the app shop and its volumes, without the question:

```bash
podshift quadlet rm shop --volumes --yes
```
