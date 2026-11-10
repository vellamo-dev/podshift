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

`apiVersion` must be the number `1`. `action` must be a known name. `args` must be an object. Unknown fields are rejected. The registered actions are `ping` and `capabilities`, and both take `args` as `{}`.

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
| `INVALID_ARGS` | The arguments failed the input contract. |
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
| Module output | 65536 bytes, stopped while reading |
| Module run | 10 seconds, including the session tunnel and descendant processes |

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

## Journal

```sh
journalctl -t podshift-api --no-pager
```

The tag is `podshift-api`. Each line has a matched action or a fixed marker (`not-root`, `invalid-request`, `unknown-action`), a result code, and `duration_ms`. The raw body, arguments, module output and caller text are not logged. If logging fails, the JSON response is unchanged.

## Further reading

Developer documentation, including how to add an action, is in [docs/cockpit-api.md](https://github.com/vellamo-dev/podshift/blob/main/docs/cockpit-api.md). That file is not installed with the RPM.
