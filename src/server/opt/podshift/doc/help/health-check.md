# health-check
Checks the health of the PodShift server and shows the result per group.

Every check runs in its own realm:

- **any**: runs for every caller.
- **podshift**: runs inside the podshift user's session. Root enters that session for each of these checks; other users see them as skipped.
- **root**: runs only as root; other callers see it as skipped.

A skipped check is not a problem and does not change the result.

Each check shows one icon:

- `✔` passed.
- `ℹ` note: worth knowing, but the system is fine as it is. It does not change the result.
- `⚠` warning: someone with root access should act. The result becomes "Needs attention".
- `✘` issue: something is broken. The result becomes "Issues found".

A note, warning or issue gets a `Fix:` line with a hint or command. At a terminal, a spinner shows the check that is running, and the icons are colored. In a pipe or a log the output is plain.

## Usage:

```
podshift health-check [--tsv | --json | --plain] [--fail-if-unhealthy]
```

## Options:

| Option | Meaning |
| --- | --- |
| `--tsv` | Print one tab-separated line per check, plus a verdict line. |
| `--json` | Print the result as JSON. |
| `--plain` | Plain output, without colors or spinner. `podshift --plain health-check` does the same. |
| `--fail-if-unhealthy` | Let the exit code show the health result, see below. |

## Exit codes:

| Code | Without `--fail-if-unhealthy` | With `--fail-if-unhealthy` |
| --- | --- | --- |
| `0` | The health check ran. | Healthy. |
| `1` | | Check incomplete: a check could not run. |
| `2` | | Needs attention or issues found. |
| `3` | Cannot run: unknown option or no checks found. | Same. |
