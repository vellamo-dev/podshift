# unit-quadlet-lifecycle

Runs the stubbed bats tests in `scripts/` for the install-once rules and for removing quadlets. It needs bats and jq, but no VM, Podman, network or root.

`stubs.bash` puts fake `podman`, `systemctl`, `timeout` and `logger` commands first on `PATH`. They write their calls to a log, answer `podman <type> exists` and `podman ps` from small files, and the fake `podman quadlet rm` deletes the file or app folder from a temporary quadlets folder. The tests only show that PodShift calls Podman and systemd the way it means to; how Podman itself behaves is not tested here.

- `drop-process.bats`: `podshift-drop-process` skips a file that vanishes between `find` and `stat` and still handles the others, and stops without a fallback when the settle time or the bundle size setting is missing.
- `install-start.bats`: `install-quadlet` never passes `--replace`, a bundle is installed with `--application`, a failed install returns 1 and logs the Podman output, and `start-quadlet` only queues a start (`start --no-block`), the pod before its containers.
- `install-checks.bats`: `check-quadlet-names-free` refuses a name already used in Podman for that type, a pod whose infra container name `<pod>-infra` is taken (in Podman, installed, or in the same bundle) and a container named like the infra container of a pod; `check-quadlet-deps` refuses a missing quadlet reference or Podman secret, and accepts a reference that is installed, waiting in the source folder or in the same bundle, and a plain name such as `Network=web` whether or not a matching quadlet is installed. A file with `Pod=` is refused, as pods are not supported yet.
- `remove-item.bats`: a name that is not installed, a file used by another installed file, a network used by a plain `Network=web`, a network used by a container outside the item, the stop order (users first), `podman quadlet rm --force` with `--recursive` for an app, leftover containers by the `PODMAN_SYSTEMD_UNIT` label, pods and networks removed, volumes kept unless asked, and that a removal logs only to the `podshift-qdl-remove` tag, never to the drop history.
- `drop-id.bats`: `set-drop-id` writes `# podshift-drop-id: <uuid>` as line 1 with mode 0644 and removes older ID lines, `get-drop-id` reads the ID from a file, from a queued zip name `shop.zip.<uuid>` and from a bundle folder, `process-bundle` gives every file of a bundle the same ID and logs it, refuses a bundle over `PODSHIFT_DROP_MAX_BUNDLE_UNPACKED` or `PODSHIFT_DROP_MAX_BUNDLE_FILES` and refuses one when a limit is not set, `podshift-qdl-install` logs the ID of each item and gives a file placed in the source by hand a new one, and `install-item` keeps the ID line in the copy it passes to `podman quadlet install`. Whether Podman copies that line into the installed file is not tested here.
- `quadlet-rm-cli.bats`: `podshift quadlet rm` with `--yes`, `--volumes`, the prompt, a refused removal, bad arguments and a caller who is not the podshift user (caller check, config loaders and `remove-item` stubbed), and `podshift-qdl-remove` handling the remove queue oldest first, deleting each request first, keeping a `.removing.<name>` marker while it removes and skipping hidden files.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

Run the tests:

```bash
./test --plain unit-quadlet-lifecycle
```
