# Coding style and principles

The PodShift shell scripts follow a small set of consistent conventions. The code itself is the primary documentation.

## Documentation

Every `.sh` file is documented with bashdoc tags, so a person can read what a file and each function does without running it. Configuration files that PodShift reads itself, such as `main.conf` and `groups.conf`, use the same file header as scripts. The always-required tags, and that `@file` and `@source-dir` match the path, are enforced by `lint-bashdoc-required-tags` for every `.sh` file and every listed `.conf` file under `src/server` and `src/deployment`. Its lists live in `src/test/cli/tests/lint-bashdoc-tags/data/tags.conf`. Path- and category-dependent tags are enforced by `lint-bashdoc-conditional-tags`, which reads the same file. Tag names and allowed values are enforced by `lint-bashdoc-tag-values`, which reads the marked tables in this file.

Each tag is one of two kinds:

- **standard:** a tag bashdoc already knows. It keeps its bashdoc meaning; PodShift only fixes its value.
- **project:** a tag of PodShift's own, with a plain name that bashdoc does not use, so the two never overlap.

### Tags

The table lists the tags in the order they are written in a file.

<!-- lint:tags -->

| Tag | Kind | Used on | Required | Value or meaning in PodShift |
|---|---|---|---|---|
| **Identity and place** | | | | |
| `@file` | standard | file | must | File name only, for example `is-fedora.sh`. Never a path. |
| `@source-dir` | project | file | must | Folder in the repository, from the project root: `src/server/opt/podshift/fn/utils`. |
| `@dest-dir` | project | file | must for installed files only | Folder on the server where the file is installed: `/opt/podshift/fn/utils`. Files that are never installed leave it out. |
| `@host-edit` | project | file | must for installed files only | Whether an admin may edit the installed file on the server: `no` (managed by PodShift, an update overwrites it; change the source instead), `yes` (local changes survive updates) or `settings` (only the settings in it are meant to be changed). Editing during development is always fine. Use `@warning` to point to the safe way, for example a drop-in. |
| `@group` | project | file, setting | must | On a file: the bundle of related files it belongs to, for example all health checks. On a setting: the feature the setting belongs to, for example `drop`. See [Allowed values](#allowed-values). |
| `@category` | project | file | must | What kind of file it is. Files of one category can sit in many groups. See [Allowed values](#allowed-values). |
| **Health checks** | | | | |
| `@title` | project | file | must for category `check` and for test `main.sh` | Short name shown on screen, for example `OS`. On a test, what it does in plain words: `Cleaning logs`. |
| `@run-as` | project | file | must for category `check` and CLI module `main.sh` | The realm the check or module runs in: `any` (every caller), `podshift` (inside the podshift user's session) or `root` (root only). The health check enters that realm for this check only, or shows it as skipped when the caller cannot. The main `podshift --help` groups the modules by it. |
| `@install-type` | project | file | optional for category `check` | `server` when the check only applies to a server install. On a desktop install the health check shows it as skipped. |
| `@unit-test` | project | file | optional | `yes` when the file holds a pure function (arguments in, text out, nothing read from the system). The file then needs a unit test `src/test/unit/<function>.bats`, run by `./test unit-pure-functions`. Tag only functions whose output is fully set by their arguments. |
| **Steps** | | | | |
| `@step` | project | file | must for category `step` in the RPM and deployment | Step ID printed in the output, for example `PS-DP-DRS`. |
| **Tests** | | | | |
| `@platforms` | project | test `main.sh` | must | Where a test is promised to work: `mac>=26 fedora>=45`, or `all`. |
| `@needs` | project | test `main.sh` | optional | The tests that must have passed first, separated by spaces, as the full chain in run order: `host-check build-image build-rpm`. |
| `@purpose` | project | test `main.sh` | optional | `test` (the default) or `maintenance` for cleanup tests such as `clean-logs`. Maintenance tests are listed separately in the help. |
| **Description** | | | | |
| `@description` | standard | file, function, setting | must | What it does, in one sentence, present tense, no "because" and no implementation notes, at most 120 characters (enforced by `lint-bashdoc-description-length`). |
| `@details` | project | function, file | optional | The detailed how and why, edge cases and exit behavior, as continuation lines indented with exactly three spaces (`#   `). No length limit. Help output and the linter ignore the text; the linter rejects any other indent or an indented line outside `@details`. |
| `@rationale` | project | file | must for category `check` | Why the check matters, in one sentence: `Without a working rootless runtime, containers cannot start.` |
| `@fix` | project | file | optional for category `check` | A short hint or command that fixes a problem, shown under a warning or failure: `sudo systemctl enable --now firewalld`. |
| `@warning` | standard | file, function | optional | Something a reader must be careful about. |
| **License** | | | | |
| `@license` | standard | file | must | `AGPL-3.0-or-later` |
| `@license-url` | project | file | must | `https://github.com/vellamo-dev/podshift/blob/main/LICENSE` |
| `@author` | standard | file | must | `Vellamo.fyi` |
| **Functions** | | | | |
| `@arg` | standard | function | when it takes arguments | One argument: `$1 - name of the unit.` One line per argument. |
| `@stdout` | standard | function | when it prints | What it prints to standard output. |
| `@stderr` | standard | function | when it prints errors | What it prints to standard error. |
| `@exitcode` | standard | function | must | What each return code means: `0 if Fedora, 1 otherwise.` |
| **Settings** | | | | |
| `@type` | project | setting | when the value has a unit or a format | What kind of value the setting takes. See [Allowed values](#allowed-values). |

<!-- lint:end -->

The test tags are used only by the test suite in `src/test/`, see [Testing](../src/test/readme.md). A test `main.sh` takes `@group: test` and `@category: entry`. A setting also takes `@description` and `@group`.

### Allowed values

<!-- lint:allowed-values -->

- `@group`: `cli`, `cockpit`, `common`, `config`, `deployment`, `drop`, `env`, `health-check`, `ingest`, `network`, `platform`, `podman`, `post`, `posttrans`, `postun`, `preun`, `quadlet`, `rootless`, `runtime`, `service`, `session`, `shortcuts`, `test`, `utils`
- `@category`: `entry`, `helper`, `step`, `check`, `shortcut`, `config`
- `@type`: `list`, `seconds`, `kilobytes`

<!-- lint:end -->

`@group` is one name per bundle of related files, normally the name of the folder that holds them. A new group is added here before it is used. `cockpit` is only for files that implement the Cockpit API under `src/server/opt/podshift/cockpit/api/`.

`@category` is one of:

- `entry`: a script started directly, such as a command, a `main.sh` or an RPM scriptlet;
- `helper`: a reusable function sourced by other scripts;
- `step`: one step of an install, a deployment or a test;
- `check`: one health check;
- `shortcut`: a short admin command under `shortcuts/`;
- `config`: a configuration or data file that PodShift reads itself.

`@type` is one of:

- `list`: comma-separated values;
- `seconds`: a whole number of seconds;
- `kilobytes`: a whole number of kilobytes.

### Writing rules

- Tags are written as `# @tag: value`, with one space after the colon, no column alignment and no em-dashes.
- File tags form the top block, right after the shebang (or on the first line when there is none), in the order of the table.
- Function tags go directly above the function they describe, in the order of the table.
- Setting tags go directly above the setting they describe, in a configuration file.
- A configuration file's header starts with `@file` and follows the table order. Installed files include `@dest-dir` and `@host-edit`; build-time files under `src/deployment` leave them out. A `#` separator line follows the header before any setting tags, such as `@type` in `main.conf`.
- PodShift's own `.conf` files are listed in `tags.conf` under `[conf-files]`. Formats for other tools (sysusers.d, tmpfiles.d, sysctl.d, systemd drop-ins, `assets/tpl` templates) are left out.
- Only tags listed in the table are allowed. A new tag gets a table row first.

### Short header

A shell file installed into the system's own places, such as `/etc/profile.d`, runs inside something that is not PodShift, for example every login shell. It carries only what a reader on the server needs, in this order:

- `@file`
- `@dest-dir`
- `@description`
- `@warning`: what to be careful about, for example that it runs in every login shell and is managed by PodShift.

It has no other tags. Every file with a short header is listed below and in `src/test/cli/tests/lint-bashdoc-tags/data/tags.conf` under `[short-header-files]`, which `lint-bashdoc-required-tags` reads.

| File | Runs in |
|---|---|
| `src/server/etc/profile.d/podshift.sh` | Every login shell on the server. |

### Exceptions

A file is left without tags only when its nature on the host does not allow them:

- it is read by another program in that program's own format;
- it is generated;
- it comes from a third party.

An excepted file still starts with one plain comment line saying what it is. Every excepted file is listed here with its reason and in `src/test/cli/tests/lint-bashdoc-tags/data/tags.conf` under `[exception-files]`; there are none at the moment. A file that is not listed here or under [Short header](#short-header) follows the table. `lint-bashdoc-required-tags` checks both lists.

### Old tag names

Older names map as follows. None remain in the tree.

<!-- lint:old-tags -->

| Old | New |
|---|---|
| `@dir` | `@source-dir`, plus `@dest-dir` for installed files |
| `@param` | `@arg` |
| `@prefix` | `@step` |
| `@id` | `@step` |
| `@note` | `@warning` |
| `no category` | `@category` |
| `none` | `@host-edit` for installed files |

<!-- lint:end -->

`@prefix` and `@id` were one step ID together; `@step` holds that one value, for example `PS-DP-DRS`.

### Readme files

- A `readme.md` documents a directory only when the files' purpose or nature cannot be expressed in the files themselves, or to cover a directory's content and purpose.
- Only the root readme has a Finnish version, `readme.fi.md`. Update it whenever `readme.md` changes. No other files are translated.

## Functions

- One function per file, named the same as the file: `is-fedora.sh` holds `is-fedora`. Entry scripts (`podshift.sh`, module `main.sh`, `src/test/run.sh`) may keep several functions.
- In code that is not deployed, such as `src/test/`, a file may also keep small private helpers that only its main function uses. Their names start with the same words as the main function, such as `run-task-spinner` next to `run-task`, or `verify-tar-check` next to `verify-tar-package`, and are unique across the project like any other function. Everything that ships in the RPM keeps one function per file.
- Function names say what the function does in plain words, and are unique across the project.
- A function receives only the arguments it uses; positional arguments are destructured into named `local` variables, never used as bare `$1` / `$2` in the body.
- No dynamic scoping: helpers take their inputs as explicit arguments.
- Function body order: `local` declarations, then static value assignments, then the step header, then the work.
- Helpers are loaded inside the function, just before their first use, never in the file header or anywhere else outside a function. A load inside a loop is fine.
- Each load first checks whether the function is already there, so a helper is loaded only once per run:

  ```bash
  # shellcheck source=../utils/paint.sh
  declare -F paint >/dev/null || source "${DIR_3D57253A9314}/../utils/paint.sh"
  ```

- A function loads every helper it uses itself, even when a parent may already have loaded it.
- The check works because each helper file holds one function with the same name as the file, and function names are unique across the project. The only exception is the macOS and Fedora versions of one helper in `src/test/cli/os-specific/`, since only one of them is loaded per run.
- Code that is not deployed, such as the test suite in `src/test/`, may load its shared helpers up front in its entry script (`src/test/run.sh`). Its steps and helpers may then call those helpers without loading them. Everything that ships in the RPM follows the loading rules above without exception.
- Local variables use lowercase; global variables use uppercase.

## Behaviour

- Functions are non-fatal and non-verbose: they never stop the install, and they do not print clutter.
- Failures are logged with `logger -t podshift "..."`, or a `podshift-<part>` tag for a service such as `podshift-drop-process`, not printed to stdout. RPM scriptlets also send their output to the journal with the tag `podshift-install`.
- Logs are plain text, with no color. Color is used only on interactive output: through `paint` when `PODSHIFT_OUTPUT` is `interactive`, or, for a step `[WARN]` line, when stderr is a terminal.
- In `src/server`, helpers never run when loaded: load them, then call them, like the gates below. No file there takes a trigger (`--now`, `--set`, `--print`), and `BASH_ARGV` is not used.
- In `src/server`, only files that run as their own process run their function: files that systemd runs directly (`ExecStart`) and health checks, which `health-run-check` runs with `bash <file>`. They end with `[[ "${BASH_SOURCE[0]}" == "${0}" ]] && <function>`.
- Outside `src/server` (for example `src/test`), the `--now` trigger with `BASH_ARGV` is still allowed.
- Questions are named `is-x` (for example `is-podshift`). They return 0 or 1 and print nothing.
- Gates are named `require-x` (for example `require-podshift`). They call `is-x`, and on "no" print the reason and the fix on stderr, then return 1. Gates have no trigger: load them, then call them on their own line, always followed by `|| return 1`:

  ```bash
  # shellcheck source=../../fn/utils/require-podshift.sh
  declare -F require-podshift >/dev/null || source /opt/podshift/fn/utils/require-podshift.sh
  require-podshift || return 1
  ```

- Helpers never use `exit`; they return. Only entry files (`podshift.sh`, shortcuts, module `main.sh`) end the run, with the last return code.

## Output

- Step output uses a machine-readable prefix and a human-friendly status:
  - header: `[PS-<phase>-<id>] <message>`
  - status: indented `[OK]` / `[WARN]` / `[SKIP]` (short tags, not the full prefix).
  - `[WARN]` goes to stderr, the others to stdout.

## Files and system calls

- Deploy files with `install -m 0644` (or `install -D -m 0644`), with explicit permissions, not `cp` / `touch`.
- Check unit state with `systemctl ... --quiet` plus the exit status, never by capturing the output of `is-enabled` / `is-active`.

## Conventions

- `PODSHIFT_*` variables configure PodShift itself; `TSV_*` variables describe the target system and may appear in quadlet files.
- The dedicated podshift user identity is fixed (UID `300`, `/home/podshift`, `300@.host`, `/run/user/300`) and intentionally hardcoded for fleet consistency.
- A script caches its own directory in a guarded, read-only `DIR_<hash>` variable, where the hash is 12 uppercase hex characters, for example `DIR_3D57253A9314`.
- A script that needs PodShift settings loads `main.conf` itself with `load-podshift-conf-main`, with no hardcoded fallback values. When a needed setting is missing, it says so, for example a health check prints `WARN` with `<VAR> is not set`.
- `export` is used only for configuration that other processes must see, such as the settings in `main.conf`.
- No symlinks in the repository.

## Packaging

PodShift must not install `cockpit-podshift` in any way. That means no `Requires`, `Recommends`, `Suggests` or `Supplements` in `podshift.spec`, and no `dnf install` in `%post`, scripts or setup commands. Shipping the AppStream entry and enabling the Copr repository are allowed.

## Versioning

Versions are `x.y.z`. The `Version:` line in `podshift.spec` is the single source of truth and the only file that holds the version. At runtime, `get-podshift-version` reads it from the installed RPM (`0.0.0-local-dev` outside an RPM install), and the Cockpit API reports that value.

- **Patch (`z`)** goes up on any change that ships, such as a fix, a text change or a docs edit in the package.
- **Minor (`y`)** goes up when a feature is added or after a bigger refactor, and `z` goes back to 0.
- **Major (`x`)** stays at 0 until the first stable release. Only the maintainer changes it, never an agent.

Every bump adds a spec `%changelog` entry (`- x.y.z-1`) and sets `Release:` back to `1`. Bump once per task or delivery, not per saved file. An agent bumps the version as the last step of a change and says so in its report.
