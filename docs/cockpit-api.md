# Cockpit API for PodShift UI

The handler is a root-checked JSON program at `/opt/podshift/cockpit/api/main.sh`. The Cockpit UI, the separate optional add-on [cockpit-podshift](https://github.com/vellamo-dev/cockpit-podshift), starts it with `superuser: "require"`, so the process is already root. The handler never elevates itself, never adds a sudo or polkit rule, and never trusts a user name from the request. It accepts only a process that is already root.

The PodShift CLI stays the human interface. Modules call system tools or shared helpers and return data. They do not call `podshift` commands. General system administration stays in Cockpit's existing tools.

Request and response details are in the shipped [Cockpit API readme](../src/server/opt/podshift/cockpit/api/readme.md).

## Architecture

```text
Cockpit administrator
    │
    │ Authorizes the administrative action
    ▼
Cockpit starts /opt/podshift/cockpit/api/main.sh as root
    │
    ├── Refuse the process unless it is root
    ├── Read one JSON request and check the envelope
    ├── Dispatch one fixed action
    ├── When the realm is podshift, enter podshift@.host
    │     and run fn/cockpit-run-in-session.sh
    ├── Write one JSON response
    └── Log safe metadata to the journal
```

An action runs in one of two realms, taken only from the dispatch map:

- `root`: the module runs in the same root process.
- `podshift`: the root process starts a `systemd-run` tunnel into `podshift@.host`, then runs `fn/cockpit-run-in-session.sh` as its own process. The checked `args` object is passed to it as one argument, and `--expand-environment=no` keeps systemd from expanding `$` in it. That script requires effective UID 300, looks up the same dispatch map, and prints only the module data. The unit name is `podshift-api-<pid>-<random>`. A failed tunnel, with no session marker, is `REALM_UNAVAILABLE`.

```text
systemd-run --unit=podshift-api-<pid>-<random> --machine=podshift@.host --user --wait --pipe --quiet --collect --expand-environment=no
```

`main.sh` is the only public entry. Do not source `fn/cockpit-run-in-session.sh` from the root process.

## Layout

- `main.sh`: the entry.
- `modules/<action>/`: one folder per action, with `capability.json` and `module.sh`.
- `fn/`: the general helpers for requests, responses, validation, dispatch, sessions and the health report.
- `fn/overview/`, `fn/services/`, `fn/resources/` (containers, images, networks, volumes and secrets), `fn/quadlets/` and `fn/inspect/`: the helpers for one feature each.

A new helper goes into the folder of its feature, or into `fn/` when it is general.

## Adding an action

The dispatch map in `fn/cockpit-dispatch-action.sh` is the only whitelist. It is also the only source of the action name, function, module directory and realm. A new action needs all of these:

1. A literal map entry. Today `ping` is realm `podshift` and function `cockpit-module-ping`. `capabilities` is realm `root` and function `cockpit-module-capabilities`. `overview-status`, `health-check` and `service-logs` (the journal is only readable as root) are realm `root`. `overview-usage`, `overview-info`, `overview-config`, `networks-list`, `images-list`, `volumes-list`, `containers-list`, `inspect`, `secrets-list`, `services-list`, `service-view`, `quadlets-list` and `quadlet-view` are realm `podshift`.
2. `modules/<action>/capability.json`, whose `action` field matches the map name.
3. `modules/<action>/module.sh`, which defines that function and prints one JSON value. The function gets the checked `args` object as its first argument, as one JSON string (`{}` for an action without arguments).
4. Cases in `unit-cockpit-api`.

A file in `modules/` does not become callable until it is listed in the map.

## capability.json

Each module has one metadata file. The fields are required, and unknown fields are rejected.

| Field | Meaning |
|---|---|
| `action` | Must match the dispatch map name. |
| `name` | Short display name. |
| `description` | One-line description. |
| `status` | `active`, `deprecated` or `retired`. |
| `input` | Contract for `args`. |
| `output` | Contract for the module's `data`. |

Supported contract keywords, checked recursively through nested `properties` and `items`:

- `type`: `object`, `array`, `string`, `integer`, `number`, `boolean` or `null`.
- `properties`, `required` and `additionalProperties: false` for objects.
- `items` for arrays.
- `enum` and `const` when a value must be fixed.
- `minLength`, `maxLength` (non-negative integers) and `pattern` (a jq regular expression that must compile) for strings. They apply only to string values. Anchor a pattern with `\A` and `\z`, because `^` and `$` can match at a line break.

Any other keyword, or a supported keyword in an unsupported shape, makes the metadata invalid. `additionalProperties` is accepted only as `false`. Contracts do not fill in defaults.

When `args` fail the input contract, the handler returns `INVALID_ARGS` with the message `Given arguments are not supported: <names>.` `fn/cockpit-contract-failing-args.sh` finds the names: unknown arguments when `additionalProperties` is `false`, missing required ones, and those whose value fails its own contract. Only names of 1 to 64 letters, digits, `_`, `-` and `.` are listed, and values never are. When no name can be listed, the message is `Given arguments are not supported.`

Rules:

- Metadata never adds an action.
- Missing, unreadable or invalid metadata fails closed: the action returns `INTERNAL` and does not run. Discovery also fails closed, with no partial list.
- A deprecated action still runs.
- A retired action stays in the map and is listed by `capabilities`. Calling it returns `ACTION_RETIRED` with `data` set to null.

## Compatibility

`apiVersion` must be the number `1`. Action names stay recognised even after the implementation is retired. A change to argument or response meaning still needs a compatibility decision.

## UI guidance

A Cockpit UI, such as cockpit-podshift, should:

- Call `capabilities` when the plugin starts or a session begins, and again after reconnecting.
- Keep the result in memory only.
- Disable actions that are missing, retired, or have contracts it does not support. A deprecated action may still be used with a warning.
- Show a clear error when discovery fails, and not guess which actions exist.
- Still handle failures from each later call. Discovery is not authorization and does not guarantee that an action will succeed.

`capabilities` returns `data.actions`, an array of the same fields as each `capability.json`.

## Journal logging

The tag is `podshift-api`. Each line has a matched action or a fixed marker (`not-root`, `invalid-request`, `unknown-action`), a result code, and `duration_ms`.

The raw body, arguments, module output, secrets and any caller text are not logged. If logging fails, the JSON response is unchanged.

## Testing

```sh
./test --plain unit-cockpit-api
./test --plain unit-pure-functions
```

The `networks-list` parsing is in pure helpers with bats tests on sample `podman network inspect` JSON in `src/test/unit/fixtures/cockpit-networks/`: `cockpit-networks-items` (cards), `cockpit-networks-quadlet-name` (the network name a `.network` file creates) and `cockpit-networks-unit-networks` (names from `podman network create` in a service file). `unit-cockpit-api` runs the module with podman and systemctl stubbed and real Quadlet and unit files in a temporary home.

The `images-list` parsing works the same way, with fixtures in `src/test/unit/fixtures/cockpit-images/`: `cockpit-images-items` (cards from `podman image inspect` and `podman ps -a` JSON) and `cockpit-images-quadlet-ref` (the image reference a `.image` file pulls). `unit-cockpit-api` runs the module with podman and systemctl stubbed and real Quadlet `.image` files in a temporary home.

`volumes-list` follows the same pattern with fixtures in `src/test/unit/fixtures/cockpit-volumes/`: `cockpit-volumes-items` (cards from `podman volume inspect`, containers with their volume names, and du sizes) and `cockpit-volumes-quadlet-name` (the volume name a `.volume` file creates). `unit-cockpit-api` also stubs `du`, including a failing and a timed-out du.

`containers-list` has its card builder in `cockpit-containers-items`, with fixtures in `src/test/unit/fixtures/cockpit-containers/` (`podman ps -a`, `podman container inspect` and `podman stats` JSON, plus the Quadlet and unit maps). `unit-cockpit-api` runs the module with podman, systemctl and the stats sample stubbed and real Quadlet `.container` files in a temporary home, including a failed stats sample and a check that only running containers are sampled.

`secrets-list` builds its cards in `cockpit-secrets-items`, with fixtures in `src/test/unit/fixtures/cockpit-secrets/` (`podman secret inspect` and `podman container inspect` JSON, with a `SecretData` field and env values that the tests check never reach the output). `unit-cockpit-api` runs the module with podman stubbed, including no secrets (containers are then not read), no containers, a failing container or secret inspect, a failing podman, a check that `--showsecret` is never passed and a check that the output contract refuses an extra field such as `SecretData`.

`inspect` checks its arguments in `cockpit-inspect-args`, removes `SecretData` from secret objects in `cockpit-inspect-redact`, resolves image ID prefixes from `podman image ls` JSON in `cockpit-inspect-image-ref` and builds its data in `cockpit-inspect-result`, including the 131072-byte boundary and the too-large result, with sample `podman <kind> inspect` JSON for each kind in `src/test/unit/fixtures/cockpit-inspect/`. `unit-cockpit-api` runs the module with podman stubbed for each kind, a missing resource, a podman failure, an image short ID resolved through the stubbed image list (normal and file mode, by full ID or by tag), a full image ID found directly, an image with no match, a secret whose stubbed podman prints `SecretData` anyway (removed in normal and file mode), a too-large object and file mode (a 0600 file in a temporary runtime folder, with stale files removed), sends bad kinds, refs and modes through the handler to check that they are `INVALID_ARGS` with the failing argument named and never reach the session, and checks that the arguments reach the mocked `systemd-run`.

`services-list`, `service-view` and `service-logs` share `cockpit-services-loaded` (loaded `.service` units from `list-units`, also used by the Overview service counts) and `cockpit-services-args` (unit and mode checks). `cockpit-services-items` builds the cards from `systemctl show` text, `cockpit-services-view-result` the unit or status result with the 131072-byte boundary, and `cockpit-services-log-entries` the entries from `journalctl -o json`, with fixtures in `src/test/unit/fixtures/cockpit-services/`. `unit-cockpit-api` runs the modules with systemctl and journalctl stubbed: no units, a failing `list-units` or `show`, an unknown unit, an inactive unit whose status exits 3, exit 4, failing `cat` or `status`, too-large text, an empty journal (no output, `-- No entries --` with exit 1, `No journal files were found`, a hint with exit 1), a permission error with its reason (`insufficient permissions`, `Permission denied`), a permission error next to entries that are still returned, and the log size fallback. `cockpit-services-journal-error` tells a permission error from other journalctl stderr, and `cockpit-services-journal-matches` builds the root journalctl matches for the podshift UID. For `service-logs` the stubs check that systemctl targets `<uid>@.host` with the UID from a stubbed `id -u podshift`, that journalctl gets exactly the match arguments and no `--user-unit` or session, that an unknown unit or a failing `id` never runs journalctl, and a handler run checks that the root realm runs the module without entering the podshift session. It also sends bad unit names and modes through the handler to check that they are `INVALID_ARGS` and never reach the session.

`quadlets-list` runs `podman quadlet ls --format json` as the podshift user and `cockpit-quadlets-items` maps each entry to a card item `{id, title, type, unitName, path, status, app, pod}` (`type` only when the suffix is a known Quadlet kind). An empty list or a `null` listing is `{"items": []}`. A failing `podman` (including a version that has no `quadlet ls`) fails the action. `unit-cockpit-api` stubs `podman`: a list, an empty list, `null`, a failing and an unsupported `quadlet ls`, and a handler run checks the podshift session and the output contract.

`quadlet-view` reuses `cockpit-services-args` and `cockpit-services-loaded`. `cockpit-quadlet-view-path` checks the `SourcePath` text (Quadlet kind, inside `PODSHIFT_PODMAN_QUADLETS_DIR`, no empty, `.` or `..` segment) and `cockpit-quadlet-view-result` builds the result with the 131072-byte boundary, both with bats tests. `unit-cockpit-api` runs the module with systemctl and the Quadlet folder stubbed on real files in a temporary folder: a file at the top and in a bundle subfolder, an unknown unit, a plain unit (`NOT_QUADLET`), a missing file, a file outside the folder, a `..` path, a symlinked file and a file under a symlinked folder (`OUTSIDE_QUADLET_DIR`), an unreadable file, a failing `show`, a bad name and too-large text. A handler run checks the podshift session and the output contract.

To see real data on a test VM, `./test postinstall-examples` creates example secrets, networks, images, volumes and containers (in that order) from `src/test/fixtures/examples/`, and `./test cleanup-examples` removes them. Both run only on demand.

The successful ping path uses a mock of `systemd-run`. Like the real command, the mock refuses a named FIFO or a regular file as stdout or stderr, so the handler must pass session output and errors through anonymous pipes. A non-root process is refused before stdin is read.

These unit tests do not log in to a real `podshift@.host` session, do not prove the root gate under a real EUID 0 process, and do not exercise Cockpit spawn. Those checks belong to future Cockpit integration testing on a local Fedora VM.

## Boundaries

This program does not add a socket, daemon or HTTP endpoint, API-key management, a CLI symlink, or a Cockpit UI, package or manifest.

## Next steps

- Add further modules one at a time, each with a dispatch entry, `capability.json`, `module.sh` and tests.
- If a remote API is ever added, put it in front of the modules with its own authentication, permissions and rate limits.
