# PodShift Cockpit API

Root-checked JSON handler for one local request. Cockpit will call the installed program at `/opt/podshift/cockpit/api/main.sh` with `superuser: "require"`. This directory does not include a Cockpit screen.

The program does not become root, does not change sudo or polkit, and does not read a user name from the request. It accepts a process that is already root. `main.sh` is the only public entry. `fn/cockpit-run-in-session.sh` is an internal entry launched inside the `podshift` session. Do not source that file from the root process.

## How to run

Run it as root and send one JSON object on stdin:

```sh
echo '{"apiVersion":1,"action":"ping","args":{}}' | /opt/podshift/cockpit/api/main.sh
```

```sh
echo '{"apiVersion":1,"action":"capabilities","args":{}}' | /opt/podshift/cockpit/api/main.sh
```

## Request

One JSON object on stdin:

```json
{"apiVersion":1,"action":"ping","args":{}}
```

`apiVersion` must be the number `1`. `action` must be a known name. `args` must be an object. Unknown fields are rejected. The registered actions are `ping`, `capabilities`, `overview-status`, `overview-usage`, `overview-info`, `overview-config`, `health-check`, `networks-list`, `images-list`, `volumes-list`, `containers-list`, `inspect`, `secrets-list`, `services-list`, `service-view`, `service-logs`, `quadlets-list` and `quadlet-view`. All take `args` as `{}` except `inspect`, which takes `{"kind": ..., "ref": ...}`, `service-view`, which takes `{"unit": ..., "mode": ...}`, and `service-logs` and `quadlet-view`, which take `{"unit": ...}`.

## Response

Stdout is one JSON object. A handled request exits 0, including a refusal or a bad request. Exit 1 means stdout is not the envelope, for example because `jq` is missing.

```json
{
  "podshift": {"version": "0.0.0-local-dev", "apiVersion": 1},
  "request": {"action": "ping", "args": {}},
  "status": {"ok": true, "code": "OK", "message": "Ping completed"},
  "data": {"pong": true, "uid": 300}
}
```

`podshift.version` comes from `get-podshift-version`: the installed RPM version, or `0.0.0-local-dev` in a source tree. `request` is null when the body or the action was not accepted. On `INVALID_ARGS`, `ACTION_RETIRED` and metadata failure, `request.args` is null so the rejected arguments are not echoed. `data` is null unless it matched the output contract.

| Code | When |
|---|---|
| `OK` | The module returned data that matched its output contract. |
| `INVALID_REQUEST` | Empty, too large, too slow, malformed, repeated, or not the envelope. |
| `UNSUPPORTED_VERSION` | `apiVersion` is a number other than 1. |
| `UNKNOWN_ACTION` | The action is not in the dispatch map. |
| `INVALID_ARGS` | The arguments failed the input contract. The message names them, for example `Given arguments are not supported: ref.` Only names of letters, digits, `_`, `-` and `.` are listed, never values. |
| `NOT_ROOT` | `main.sh` is not root. Stdin is not read. |
| `REALM_UNAVAILABLE` | The `podshift` session could not be entered. |
| `INTERNAL` | Metadata, module, output, time or size failure. |
| `ACTION_RETIRED` | The action is still named and no longer runs. |

## Bounds

| Bound | Value |
|---|---|
| Request size | 65536 bytes |
| Request wait | 5 seconds |
| Capability file | 65536 bytes |
| Module output | 131072 bytes, stopped while reading |
| Module run | 10 seconds, or 120 seconds for `health-check`, including the session tunnel and descendant processes |

## Actions

### Ping

Ping runs in the `podshift` realm. Its data is `pong: true` and `uid` set to that process's effective UID. The output contract accepts only UID 300.

A failed tunnel is `REALM_UNAVAILABLE`. A module that starts and then fails, times out, writes too much, or prints something other than one JSON value is `INTERNAL`.

### Capabilities

Capabilities runs in the `root` realm. It lists every action in the dispatch map, including itself, in `data.actions`. Each entry uses the fields from that action's `capability.json`. A retired action is listed and is not run. If any metadata is missing or invalid, the result is `INTERNAL` with `data` set to null.

```json
{
  "actions": [
    {
      "action": "ping",
      "name": "Ping",
      "description": "Confirms that the handler can run a module in the podshift session.",
      "status": "active",
      "input": {"type": "object", "properties": {}, "additionalProperties": false},
      "output": {"type": "object", "properties": {"pong": {"type": "boolean"}, "uid": {"type": "integer", "enum": [300]}}, "required": ["pong", "uid"], "additionalProperties": false}
    },
    {
      "action": "capabilities",
      "name": "Capabilities",
      "description": "Lists every recognised action with its metadata and contracts.",
      "status": "active",
      "input": {"type": "object", "properties": {}, "additionalProperties": false},
      "output": {"type": "object", "properties": {"actions": {"type": "array"}}, "required": ["actions"], "additionalProperties": false}
    }
  ]
}
```

The `capabilities` output contract also describes each array item. The installed `modules/capabilities/capability.json` is the complete contract.

### Overview status

Overview status runs in the `root` realm. It lists the podshift user units (queried with `systemctl --machine=300@.host --user`, never the caller's session), plus the firewalld and Fail2Ban system services and the SSH port from `sshd -T`. `data.rows` is an ordered list of `{id, label, value, unit, scope}` objects. `unit` is the systemd unit the row already checks, and `scope` is `user` or `system`. User-scope rows link to the PodShift Services tab with that unit as the search filter. System-scope rows (`firewalld.service`, `fail2ban.service` and `sshd.service`) link to Cockpit's Services page. `value` is the text shown in the UI (`Running`, `Waiting`, `Exited`, `Stopped`, `Failed`, `Starting`, `Stopping` or `Reloading`), or the port number as a string, or `null` when the check could not run or a value is not set. The exact ids and their order are fixed by the module and checked in the unit tests, not by the output contract.

State mapping from systemd `ActiveState` / `SubState`:

- `failed` → `Failed`
- `activating` → `Starting`
- `deactivating` → `Stopping`
- `reloading` → `Reloading`
- `inactive` → `Stopped`
- `active` + `waiting` → `Waiting`
- `active` + `exited` → `Exited`
- `active` + any other SubState (including `running` and `listening`) → `Running`
- missing unit or unknown state → `null`

### Overview usage

Overview usage runs in the `podshift` realm. A `value` is `"<in-use> / <all>"` for services, containers, volumes and images, or just `"0"` when that total is 0; a total such as `"0"` for networks, Quadlets and secrets; or `null` when a count could not be read. The counts are:

- `services`: loaded systemd user service units of the podshift user (`systemctl --user list-units --type=service --all`), as active over total. Units whose load state is not `loaded` (not-found, masked or error) are omitted.
- `networks`: the number of networks from `podman network ls`.
- `containers`: running containers over all containers (`podman ps` / `podman ps -a`).
- `volumes`: unique volume names mounted by any container, over `podman volume ls`.
- `images`: unique image IDs used by any container, over `podman images`.
- `quadlets`: the number of installed Quadlet files (`.container`, `.kube`, `.pod`, `.volume`, `.network`, `.image`, `.build`) in `PODSHIFT_PODMAN_QUADLETS_DIR`.
- `secrets`: the number of secrets from `podman secret ls`.

### Overview info

Overview info runs in the `podshift` realm. It lists the OS (`PRETTY_NAME` from `/etc/os-release`), the Podman version, the PodShift version (`get-podshift-version`) and the Fail2Ban version. A missing package or file is `null`.

### Overview config

Overview config runs in the `podshift` realm. It lists `TSV_ENV` from the runtime configuration (always present; `null` when unset or empty), then any of `TSV_NW1` to `TSV_NW8` that are set, as derived by `load-podshift-conf-nw`, then any user-defined `TSV_*` keys from `/home/podshift/.config/podshift/tsv.conf` (the file written by `podshift config`) that have a value. User rows use the exact key as the label, a lowercase id, and are sorted by key. Built-in names repeated in that file are not listed twice. Unset or empty `TSV_NW*` and user keys are omitted. A missing or unreadable file leaves only the built-in rows that are present. TSV keys have no secret mark in PodShift, so every accepted user key with a value is included.

The output contract for all four Overview actions is an object with a `rows` array. Each item has `id`, `label` and `value`. `value` may be a string or `null`. Overview status rows may also include an optional `unit` string. The contract checker accepts only a single `type` name, so `value` is left untyped in `capability.json`; the tests check that each value is a string or `null`.

### Health check

Health check runs in the `root` realm. It runs the same checks as `podshift health-check` and returns structured data, not the printed report. `data.groups` is an ordered list of `{id, label, rows}` objects. Each row is `{id, label, state, value, fix}`. `state` is `ok`, `note`, `warn` or `fail`. `value` is the display text. `fix` is the check's fix text, or `null`. `data.summary` is `{state, label, passed, notes, warnings, failed}`. `summary.state` uses the same four values. `summary.label` matches the CLI Result line, for example `Healthy (27 passed, 1 note)`. `failed` is the number of failed checks; checks that could not run, and skipped checks, appear only in the label. The action is allowed 120 seconds because some checks, such as registry reachability, can take longer than the default 10 second bound.

### Networks list

Networks list runs in the `podshift` realm. It reads `podman network ls --format json` and `podman network inspect` for the podshift user, and returns `data.items`, one resource card per network, sorted by name. Each item is `{id, title, subtitle, status, source, rows, groups}`. `id` and `title` are the network name; `subtitle` is the first 12 characters of the network ID. `status` is `In use` when any container is attached, else `Unused`.

`rows` are `{id, label, value}` items for Driver, Subnet, Gateway, Interface, IPv6, Internal and DNS. Several subnets or gateways are joined with `, `. Rows with no value are left out.

`source` is one of:

- `builtin`: the networks named `podman` and `pasta`.
- `quadlet`: a `.network` file in `PODSHIFT_PODMAN_QUADLETS_DIR`, or in one bundle folder below it, creates this network (`NetworkName=`, or `systemd-<file name>`), or the network has the `PODMAN_SYSTEMD_UNIT` label.
- `unit`: a `.service` file in `~/.config/systemd/user` runs `podman network create <name>`.
- `unmanaged`: none of the above.

`groups` are `{id, label, rows}` items, and empty groups are left out:

- `systemd` (quadlet and unit only): `unit` (the unit name; `<base>-network.service` for a Quadlet file), `unit_state` (`ActiveState` from `systemctl --user show`), `file` (shown as `~/...`) and `app` (the application name, for a file in a bundle folder).
- `containers`: one row per attached container, with the container name as label and its IP address, without the prefix length, as value. A container without an address shows `No IP`.
- `labels`: the network labels, sorted by key.

If `podman network ls` or `podman network inspect` fails, the action fails.

### Images list

Images list runs in the `podshift` realm. It reads `podman image ls --format json`, `podman image inspect` and `podman ps -a --format json` for the podshift user, and returns `data.items`, one resource card per image ID, sorted by title. Each item is `{id, fullId, title, subtitle, status, running, source, rows, groups}`. `id` and `subtitle` are the first 12 characters of the image ID, which the UI shows and copies. `fullId` is the full image ID without `sha256:`; the UI passes it as the inspect ref. `title` is the short name of the first tag, the last path part without the tag (for example `alpine`); a dangling image without a tag is titled `<none>` and has no URL, Tags or Registry row. An image with several tags is one item. `status` is `In use` when any container, running or not, uses the image, else `Unused`. `running` is `true` when at least one of those containers is running.

`rows` are `{id, label, value}` items: `url` (the first full tag, for example `docker.io/library/alpine:latest`), `tags` (every tag, joined with `, `), `registry`, `size` (decimal units like podman, for example `8.95 MB`), `created` (UTC ISO 8601, for example `2026-11-05T10:12:00Z`; the UI formats it) and `used-by` (container names sorted and joined with `, `, each with its state from `podman ps -a` capitalized, for example `db (Running), db-backup (Exited)`, or `Unused`). Rows with no value are left out.

`source` is one of:

- `quadlet`: a `.image` file in `PODSHIFT_PODMAN_QUADLETS_DIR`, or in one bundle folder below it, pulls this image (`ImageTag=`, else `Image=`, with `:latest` added when there is no tag). This wins over `container`.
- `container`: a container that uses the image has the `PODMAN_SYSTEMD_UNIT` label, so a Quadlet `.container` file or a user service runs it.
- `unmanaged`: none of the above.

`groups` are `{id, label, rows}` items, and empty groups are left out:

- `details`: `command` (entrypoint and command), `architecture`, `os`, `digest` (shortened to 12 hex digits) and `labels` (`key=value`, sorted, joined with `, `).
- `systemd` (quadlet and container only): `unit` (`<base>-image.service` for a Quadlet file, or the container unit), `unit_state` (`ActiveState`), `file` (the `.image` file, or the unit `SourcePath` or `FragmentPath`, shown as `~/...`) and `app` (the application name, for a file in a bundle folder). For `container`, the unit of the first such container by name is shown.

If `podman image ls`, `podman image inspect` or `podman ps -a` fails, the action fails.

### Volumes list

Volumes list runs in the `podshift` realm. It reads `podman volume ls --format json`, `podman volume inspect`, `podman ps -a --format json` and `podman container inspect` (for the volume names a container mounts; `podman ps` lists only mount paths), and returns `data.items`, one resource card per volume, sorted by title. Each item is `{id, title, status, running, source, rows, groups}`, with no subtitle. `id` is the full volume name. `title` is the name, or its first 12 characters for an anonymous volume (the `Anonymous` flag, or a name of 64 hex digits). `status` is `In use` when any container, running or not, mounts the volume, else `Unused`. `running` is `true` when at least one of those containers is running.

`rows` are `{id, label, value}` items: `mountpoint` (shown as `~/...` under the podshift home), `driver`, `size`, `created` (UTC ISO 8601; the UI formats it) and `used-by` (container names sorted, each with its state capitalized, for example `db (Running), db-backup (Exited)`, or `Unused`). Rows with no value are left out.

`size` comes from `du -sb` on the mountpoint, limited to 5 seconds per volume, in decimal units like podman. The podshift user owns its volumes, but files that a container wrote with another subuid can be unreadable; du skips them and exits non-zero, and its partial number is still used, so the size can be too small. When du prints no number or times out, the row is left out.

`source` is one of:

- `quadlet`: a `.volume` file in `PODSHIFT_PODMAN_QUADLETS_DIR`, or in one bundle folder below it, creates this volume (`VolumeName=`, or `systemd-<file name>`). This wins over `container`.
- `container`: a container that mounts the volume has the `PODMAN_SYSTEMD_UNIT` label.
- `unmanaged`: none of the above.

`groups` are `{id, label, rows}` items, and empty groups are left out:

- `details`: `anonymous` (`Yes` or `No`), `options` and `labels` (`key=value`, sorted, joined with `, `).
- `systemd` (quadlet and container only): `unit` (`<base>-volume.service` for a Quadlet file, or the container unit of the first such container by name), `unit_state`, `file` (shown as `~/...`) and `app`.

If `podman volume ls`, `podman volume inspect`, `podman ps -a` or `podman container inspect` fails, the action fails. A failed `du` only leaves the size out.

### Containers list

Containers list runs in the `podshift` realm. It reads `podman ps -a --format json`, one `podman container inspect` for all containers, and one `podman stats --no-stream --format json` sample of the running containers for the podshift user, and returns `data.items`, one resource card per container, sorted by title. Each item is `{id, title, subtitle, status, running, source, rows, groups}`, plus `autoUpdate` and `autoUpdateActive` when auto-update is on. `id` is the full container ID, `title` the container name and `subtitle` the first 12 characters of the ID. `status` is the podman state capitalized, for example `Running`, `Paused`, `Exited` or `Created`. `running` is `true` for a running container.

`rows` are `{id, label, value}` items: `image`, `command` (the container command, arguments with spaces quoted), `state` (the podman status text, for example `Up 3 days` or `Exited (0) 5 hours ago`), `health` (`Healthy`, `Unhealthy` or `Starting`, only with a health check), `ports` (for example `127.0.0.1:5432 → 5432/tcp`, joined with `, `) and `created` (UTC ISO 8601; the UI formats it). Rows with no value are left out.

`source` is one of:

- `quadlet`: the `PODMAN_SYSTEMD_UNIT` label names the unit that Quadlet generates from a `.container` file in `PODSHIFT_PODMAN_QUADLETS_DIR`, or in one bundle folder below it, or the unit's `SourcePath` is a `.container` file.
- `unit`: the label names another systemd user unit, for example a hand-written service that runs `podman run` with `Environment=PODMAN_SYSTEMD_UNIT=%n`.
- `unmanaged`: there is no such label, or systemd does not know the unit (`LoadState=not-found`).

`autoUpdate` is `registry` or `local`, from the `io.containers.autoupdate` label (`image` counts as `registry`); it is missing when the label is not set. `autoUpdateActive` is `true` only when the container has a `PODMAN_SYSTEMD_UNIT` label and that unit is `active`, because `podman auto-update` only updates containers that systemd runs. It does not check `podman-auto-update.timer`.

`groups` are `{id, label, rows}` items, and empty groups are left out:

- `details`: `networks` (the attached networks sorted, else the network mode, for example `pasta`), `volumes` (named volumes as `name → destination` and bind mounts as `path → destination`, shown as `~/...` under the podshift home), `auto-update` (`Registry`, `Local` or `Off`), `restart` (the restart policy, `no` when none), `cpu` and `memory` (running containers only).
- `systemd` (quadlet and unit only): `unit`, `unit_state` (`ActiveState`), `file` (the `.container` file, or the unit `SourcePath` or `FragmentPath`, shown as `~/...`) and `app` (the application name, for a file in a bundle folder).

`cpu` is the `cpu_percent` of the stats sample and `memory` the used part of `mem_usage`, in decimal units like podman. The sample is limited to 5 seconds. When it fails, times out or is not a JSON array, both rows are left out for every container; stopped and paused containers never have them.

If `podman ps -a` or `podman container inspect` fails, the action fails. A failed stats sample only leaves CPU and Memory out.

### Secrets list

Secrets list runs in the `podshift` realm. It reads the secret IDs from `podman secret ls --quiet` (podman has no JSON format for `secret ls`; `--format json` prints the word `json`), one `podman secret inspect` for them and, when there is a secret, `podman ps -a --format json` and one `podman container inspect` for all containers, and returns `data.items`, one resource card per secret, sorted by title. `--showsecret` is never used, and only the ID, name, driver name and times of a secret are read, so no secret value, `SecretData` or driver option is ever returned; the output contract refuses any other field. Each item is `{id, title, subtitle, name, driver, created, updated, status, inUse, running, usedBy, rows}`. `id` is the full secret ID, the Inspect ref. `title` and `name` are the secret name, `subtitle` the first 12 characters of the ID. `created` and `updated` are UTC ISO 8601, or empty when unknown. Secrets have no source.

`usedBy` lists every container that references the secret, as `{container, containerId, state, type, target}`, from the container's `Config.CreateCommand` (`--secret name[,type=…][,target=…]`) and `Config.Secrets`. `type` is `file` with `target` the path in the container (`/run/secrets/<target or name>`, or an absolute target), or `env` with `target` the variable name (the target option, else the secret name). A `Config.Secrets` entry that no `--secret` option covers is listed as `file` at `/run/secrets/<name>`. Only `Id`, `Name`, `State` and those two `Config` fields are kept from the inspect output, so `Config.Env`, which older podman versions print with env secret values, is dropped right away. `inUse` is `true` when any container, running or stopped, uses the secret, and `status` is then `In use`, else `Unused`. `running` is `true` when one of those containers is running.

`rows` are `{id, label, value}` items: `driver`, `created`, `updated` and `used-by` (for example `db (env DB_PASSWORD), web (file at /run/secrets/api-token)`, or `Unused`). Rows with no value are left out.

If `podman secret ls`, `podman secret inspect`, `podman ps -a` or `podman container inspect` fails, the action fails.

### Inspect

Inspect runs in the `podshift` realm and only reads from podman. It takes `args` `{"kind": "<kind>", "ref": "<name or id>"}`, plus an optional `"mode": "file"`:

- `kind`: `container`, `image`, `volume`, `network` or `secret`.
- `ref`: a name or ID, 1 to 256 characters of letters, digits and `. : / @ _ -`, not starting with `-`. Containers and images take a name or ID (an image also a reference such as `docker.io/library/alpine:latest`), volumes a name, networks a name or ID, and secrets a name or ID (the Secrets tab passes the ID).
- `mode`: only `file`.

Any other kind, ref or mode fails the input contract with `INVALID_ARGS` (for example `Given arguments are not supported: ref.`), and podman is not run. The module checks them again before it runs `podman <kind> inspect -- <ref>` for the podshift user.

```sh
echo '{"apiVersion":1,"action":"inspect","args":{"kind":"volume","ref":"pgdata"}}' | /opt/podshift/cockpit/api/main.sh
```

`data` is `{kind, ref, found, object}`. `object` is the first element of the JSON array that podman prints, unchanged, so its fields depend on the kind and the podman version. `podman image inspect` does not always find an image by a short ID, so an image that is not found is retried once: `podman image ls --format json` is searched for the one image whose ID starts with the ref (4 to 64 hex digits, `sha256:` allowed; a prefix shared by two images is not resolved), which is then inspected by its full ID or, failing that, by its first tag. `ref` in `data` stays as requested. The Images tab passes the full ID (`fullId` from `images-list`). When the resource still does not exist (`podman <kind> exists` exits 1), `found` is `false` and `object` is left out. Any other podman failure fails the action.

When the result would be over the 131072-byte module output bound, `object` is left out and `data` is `{kind, ref, found: true, tooLarge: true, size}`. `size` is the byte size of the object as pretty JSON with a 4-space indent.

With `mode` `file`, the object is written as pretty JSON (4-space indent) to a new file `$XDG_RUNTIME_DIR/podshift/inspect-<random>.json` (`/run/user/300/podshift/` on a server) with mode 0600, owned by the podshift user, and `data` is `{kind, ref, found: true, file: {path, size}}`. The caller reads the file once as root and removes it; the Cockpit UI serves it as a download through a cockpit-ws external channel (`fsread1`, `superuser: "require"`), so the file never has to be readable by the logged-in user. Each file-mode call first removes inspect files in that folder that are older than 10 minutes. A missing resource gives `found: false` and writes no file.

Container objects include `Config.Env` with the values in plain text, as `podman inspect` shows them. The values are not logged.

A secret is inspected with `podman secret inspect` without `--showsecret`, so podman prints no value. As a second guard, `SecretData` is removed from the object at any depth before it is returned or written to a file (`cockpit-inspect-redact`).

### Services list

Services list runs in the `podshift` realm and only reads from systemd. It runs `systemctl --user list-units --type=service --all --plain --no-legend --no-pager`, keeps loaded `.service` units with the same filter as the service counts of Overview status (`cockpit-services-loaded`, so `not-found` units are dropped and both always agree), and then one `systemctl --user show --timestamp=unix --property=… -- <units>` for all of them. `data.items` is sorted by unit name. With no units, `data` is `{"items": []}` and `show` is not run.

Each item is `{id, title, subtitle, source, activeState, subState, since, unitFileState, path}`, plus `preset`, `quadletFile`, `quadletKind`, `mainPid`, `memory`, `result` and `triggeredBy` when systemd reports them. Optional fields are left out, never `null`.

- `id` and `title` are the unit name, `subtitle` the unit description, or the unit name when it has none.
- `source` is `quadlet` when `SourcePath` is a Quadlet file (`.container`, `.pod`, `.network`, `.volume`, `.image`, `.build` or `.kube`), else `unit`. `quadletFile` is then the Quadlet path and `quadletKind` its type without the dot.
- `since` is `StateChangeTimestamp` as UTC ISO 8601 (from `@<epoch>` or `Day YYYY-MM-DD HH:MM:SS UTC`); any other value is kept as is, and an empty value is an empty string.
- `path` is `FragmentPath`, `mainPid` the main PID when it is not 0, `memory` `MemoryCurrent` in bytes when known, `result` the `Result` when it is not `success`, and `triggeredBy` the triggering units joined with `, `.

If `list-units` or `show` fails, the action fails.

### Service view

Service view runs in the `podshift` realm. It takes `args` `{"unit": "<name>.service", "mode": "unit" | "status"}`. `unit` is 1 to 256 characters of letters, digits and `: _ . @ -` or `\xNN` escapes, ending in `.service` and not starting with `.` or `-`. Any other unit or mode fails the input contract with `INVALID_ARGS`, and the session is not started. The module checks them again (`cockpit-services-args`).

When the unit is not loaded for the podshift user, `data` is `{unit, mode, found: false}`. Otherwise mode `unit` runs `systemctl --user cat -- <unit>` and mode `status` runs `systemctl --user status --no-pager --full --lines=10 -- <unit>`, and `data` is `{unit, mode, found: true, text}`. `status` exits 3 for an inactive or failed unit, which is not an error; exit 4 (no such unit) gives `found: false`. Any other failure fails the action.

When `text` would be over 131072 bytes, it is left out and `data` is `{unit, mode, found: true, tooLarge: true, size}`, with `size` in bytes.

### Service logs

Service logs runs in the `root` realm, because the podshift user cannot read the journal on Fedora (`No journal files were opened due to insufficient permissions`). It takes `args` `{"unit": "<name>.service"}`, checked as in Service view. The podshift UID comes from `id -u podshift`. The unit must be one that Services list returns: a loaded `.service` unit of `systemctl --machine=<uid>@.host --user list-units --type=service --all` (the podshift user manager, never the caller), filtered by `cockpit-services-loaded`; any other unit gives `{unit, found: false}` and journalctl is not run. Otherwise it runs, as root, `journalctl -n 100 -o json --no-pager _SYSTEMD_USER_UNIT=<unit> _UID=<uid> + USER_UNIT=<unit> _UID=<uid> + OBJECT_SYSTEMD_USER_UNIT=<unit> _UID=<uid>` once (no follow) and returns `{unit, found: true, readable: true, entries}`, oldest first. Each entry is `{time, hostname, identifier, priority, message}` plus `pid` when known. `time` is UTC ISO 8601 with microseconds cut to seconds, `priority` 0 to 7 (6 when missing or out of range), and `message` is cut to 1024 characters followed by `…`. A message journald stores as bytes is decoded when it is text, else shown as `[binary data]`. Lines that are not JSON are skipped. A unit with no entries gives an empty list.

The matches (`cockpit-services-journal-matches`) are the filter `journalctl --user-unit` builds for its own UID, but for the podshift UID, since `--user-unit` run as root would use UID 0: messages from the service (`_SYSTEMD_USER_UNIT`), from the podshift systemd about it (`USER_UNIT`) and about it from the podshift user (`OBJECT_SYSTEMD_USER_UNIT`), each with `_UID=<uid>`. `--user-unit` also accepts `OBJECT_SYSTEMD_USER_UNIT` from UID 0; that is left out, so root messages about a same-named unit of another user never show. This is what Cockpit's Logs page shows for `user-service=<unit>&_UID=300`. No output, `-- No entries --`, `No journal files were found` or an exit code other than 0 mean that the unit has no entries, so `entries` is empty. Only when stderr shows a permission error (`insufficient permissions`, `No journal files were opened`, `Permission denied`, `Access denied` or `Operation not permitted`) and there is no entry, `data` is `{unit, found: true, readable: false, error: "JOURNAL_UNREADABLE", reason, entries: []}`. `reason` is the first non-empty stderr line, printable ASCII only, at most 200 characters (`cockpit-services-journal-error`); it is left out when empty. If 100 entries would be over 131072 bytes, 50, 25, 10 and then 1 newest entries are tried.

### Quadlets list

Quadlets list runs in the `podshift` realm. It runs `podman quadlet ls --format json` as the podshift user and returns `data.items`, one resource card per Quadlet file, sorted by title then id. With no Quadlets, or when podman prints `null`, `data` is `{"items": []}`. For each item it also reads the Quadlet file at `path` to take its Description.

Each item is `{id, title, unitName, path, status, app, pod, description}`, plus `type` when the file name has a known Quadlet suffix (`.container`, `.pod`, `.kube`, `.network`, `.volume`, `.image` or `.build`). Optional `type` is left out, never `null`. Empty `UnitName`, `App` or `Pod` values, and a missing `Pod` field on an older Podman, become empty strings.

- `id` is the Quadlet file name (`Name`), `title` that name without the type suffix (for example `shop-api` from `shop-api.container`).
- `type` is the suffix without the dot, when it is a known kind.
- `unitName` is the systemd unit (`UnitName`); it may be empty when systemd has not been reloaded since the Quadlet was installed.
- `path` is the file path (`Path`), `status` the Podman status (for example `active/running`, `inactive/dead`, `failed/failed`, `Not loaded` or `loaded template`).
- `app` is the application subdirectory (`App`) and `pod` the `Pod=` Quadlet (`Pod`).
- `description` is the first `Description=` from the `[Unit]` section of the file at `path`, trimmed. It is an empty string when the file is missing, unreadable, or has no Description.

The mapping is in `cockpit-quadlets-items`, with bats tests. If `podman quadlet ls` fails, including a Podman that has no `quadlet ls` subcommand, the action fails.

### Quadlet view

Quadlet view runs in the `podshift` realm, so the files are read as the podshift user. It takes `args` `{"unit": "<name>.service"}`, checked as in Service view (`cockpit-services-args`); a `mode` is refused. The unit must be loaded for the podshift user (`cockpit-services-loaded`); otherwise `data` is `{unit, found: false}`. The file is the unit's `SourcePath` from `systemctl --user show --property=SourcePath --value -- <unit>`, the file Quadlet generated the unit from.

- `{unit, found: true, quadlet: false, error: "NOT_QUADLET"}` when `SourcePath` is empty or not a Quadlet file (`.container`, `.pod`, `.kube`, `.network`, `.volume`, `.image` or `.build`).
- `{unit, found: true, quadlet: true, error, name, path, kind}` when the file cannot be shown: `OUTSIDE_QUADLET_DIR` when it is not under `PODSHIFT_PODMAN_QUADLETS_DIR` (usually `/home/podshift/.config/containers/systemd`, bundle subfolders included), has an empty, `.` or `..` segment, is a symlink, or its real folder is not inside the real Quadlet folder; `FILE_NOT_FOUND` when it is missing or not a regular file; `FILE_UNREADABLE` when it cannot be read.
- `{unit, found: true, quadlet: true, name, path, kind, text}` otherwise. `name` is the file name, `path` the full path, `kind` the type without the dot and `text` the file as is.

When `text` would be over 131072 bytes, it is left out and `data` has `tooLarge: true` and `size` instead. Quadlet files name secrets (`Secret=`) but never hold their values. The path check is in `cockpit-quadlet-view-path` and the result in `cockpit-quadlet-view-result`, both pure helpers with bats tests. If `list-units` or `show` fails, the action fails.

## Journal

```sh
journalctl -t podshift-api --no-pager
```

The tag is `podshift-api`. Each line has a matched action or a fixed marker (`not-root`, `invalid-request`, `unknown-action`), a result code, and `duration_ms`. The raw body, arguments, module output and caller text are not logged. If logging fails, the JSON response is unchanged.

## Further reading

Developer documentation, including how to add an action, is in [docs/cockpit-api.md](https://github.com/vellamo-dev/podshift/blob/main/docs/cockpit-api.md). That file is not installed with the RPM.
