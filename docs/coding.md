# Coding style and principles

The PodShift shell scripts follow a small set of consistent conventions. The code itself is the primary documentation.

## Documentation

- Every script starts with a structured `@tag` header:
  - `@file`, `@dir`, `@group`, `@description`
  - `@license`, `@license-url`, `@author`
  - step scripts additionally carry `@prefix` and `@id`
- Every function has a bashdoc block: `@description` always, plus `@param` / `@exitcode` / `@stdout` / `@stderr` only when they add information.
- `@tag:` values use a single space after the colon (no column alignment), and no em-dashes are used.
- A `readme.md` documents a directory only when the files' purpose or nature cannot be expressed in the files themselves, or to cover a directory's content and purpose.

## Functions

- A function receives only the arguments it uses; positional arguments are destructured into named `local` variables, never used as bare `$1` / `$2` in the body.
- No dynamic scoping: helpers take their inputs as explicit arguments.
- Function body order: `local` declarations, then static value assignments, then `source` of only what is needed, then the step header, then the work.
- Helpers are sourced inside the function, immediately before use, never at the top level.
- Local variables use lowercase; global variables use uppercase.

## Behaviour

- Functions are non-fatal and non-verbose: they never stop the install, and they do not print clutter.
- Failures are logged with `logger -t podshift "..."`, not printed to stdout.
- Scripts execute only when called directly or sourced with a trigger: `--now` (or `--set` / `--print`).

## Output

- Step output uses a machine-readable prefix and a human-friendly status:
  - header: `[PS-<phase>-<id>] <message>`
  - status: indented `[OK]` / `[WARN]` / `[SKIP]` (short tags, not the full prefix).

## Files and system calls

- Deploy files with `install -m 0644` (or `install -D -m 0644`), with explicit permissions, not `cp` / `touch`.
- Check unit state with `systemctl ... --quiet` plus the exit status, never by capturing the output of `is-enabled` / `is-active`.

## Conventions

- `PODSHIFT_*` variables configure PodShift itself; `TSV_*` variables describe the target system and may appear in quadlet files.
- The dedicated podshift user identity is fixed (UID `300`, `/home/podshift`, `300@.host`, `/run/user/300`) and intentionally hardcoded for fleet consistency.
- A script caches its own directory in a guarded, read-only `DIR_<hash>` variable.
