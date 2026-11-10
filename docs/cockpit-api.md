# Cockpit API for PodShift UI

The handler is a root-checked JSON program at `/opt/podshift/cockpit/api/main.sh`. A future Cockpit plugin starts it with `superuser: "require"`, so the process is already root. The handler never elevates itself, never adds a sudo or polkit rule, and never trusts a user name from the request. It accepts only a process that is already root.

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
- `podshift`: the root process starts a `systemd-run` tunnel into `podshift@.host`, then runs `fn/cockpit-run-in-session.sh` as its own process. That script requires effective UID 300, looks up the same dispatch map, and prints only the module data. The unit name is `podshift-api-<pid>-<random>`. A failed tunnel, with no session marker, is `REALM_UNAVAILABLE`.

```text
systemd-run --unit=podshift-api-<pid>-<random> --machine=podshift@.host --user --wait --pipe --quiet --collect
```

`main.sh` is the only public entry. Do not source `fn/cockpit-run-in-session.sh` from the root process.

## Adding an action

The dispatch map in `fn/cockpit-dispatch-action.sh` is the only whitelist. It is also the only source of the action name, function, module directory and realm. A new action needs all of these:

1. A literal map entry. Today `ping` is realm `podshift` and function `cockpit-module-ping`. `capabilities` is realm `root` and function `cockpit-module-capabilities`.
2. `modules/<action>/capability.json`, whose `action` field matches the map name.
3. `modules/<action>/module.sh`, which defines that function and prints one JSON value.
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

Any other keyword, or a supported keyword in an unsupported shape, makes the metadata invalid. `additionalProperties` is accepted only as `false`. Contracts do not fill in defaults.

Rules:

- Metadata never adds an action.
- Missing, unreadable or invalid metadata fails closed: the action returns `INTERNAL` and does not run. Discovery also fails closed, with no partial list.
- A deprecated action still runs.
- A retired action stays in the map and is listed by `capabilities`. Calling it returns `ACTION_RETIRED` with `data` set to null.

## Compatibility

`apiVersion` must be the number `1`. Action names stay recognised even after the implementation is retired. A change to argument or response meaning still needs a compatibility decision.

## UI guidance

When a Cockpit plugin is added, it should:

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
```

The successful ping path uses a mock of `systemd-run`. Like the real command, the mock refuses a named FIFO or a regular file as stdout or stderr, so the handler must pass session output and errors through anonymous pipes. A non-root process is refused before stdin is read.

These unit tests do not log in to a real `podshift@.host` session, do not prove the root gate under a real EUID 0 process, and do not exercise Cockpit spawn. Those checks belong to future Cockpit integration testing on a local Fedora VM.

## Boundaries

This program does not add a socket, daemon or HTTP endpoint, API-key management, a CLI symlink, or a Cockpit UI, package or manifest.

## Next steps

- Add further modules one at a time, each with a dispatch entry, `capability.json`, `module.sh` and tests.
- Add the Cockpit plugin, which starts `/opt/podshift/cockpit/api/main.sh` only after administrative authorization.
- If a remote API is ever added, put it in front of the modules with its own authentication, permissions and rate limits.
