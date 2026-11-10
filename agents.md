# AGENTS.md

PodShift turns small servers into lightweight container orchestration hosts. It installs a complete rootless Podman server (security, networking, and monitoring included) and then manages it automatically: drop in Quadlet files and they are validated, installed, and run as systemd services, containers update themselves, and handy commands plus built-in help cover day-to-day operation.

Main documentation: [readme.md](./readme.md)

Why things work this way: [design-choices.md](./docs/design-choices.md)

What is done and what is planned: [roadmap.md](./docs/roadmap.md)

## Development

Writing and editing the code.

### Scope

Follow the project scope: [scope.md](./docs/scope.md)

### Hard rules (always)

These rules apply to all code. "Deployed" means `src/server` (ships in the RPM) and `src/deployment` (runs on the COPR build server); only `src/test/` is not deployed.

- All project code is Bash shell scripts: no Python, Perl, Ruby, or compiled binaries.
- Helpers are non-fatal and non-verbose: they never stop the install, they return instead of `exit`, and they print no debug output or chatter. Failures are logged with `logger -t podshift` (or a `podshift-<part>` tag for a service, `podshift-install` for RPM scriptlets), never to stdout. Progress is shown only as step output (see below). Only entry files end the run.
- Deployed helpers never run when loaded and never use `BASH_ARGV`: load a helper, then call it. Details in [coding.md](./docs/coding.md#behaviour).
- In deployed code, each helper is sourced inside the function that uses it, immediately before use, never at the top level. `src/test/` may load its shared helpers up front in its entry script (`src/test/run.sh`), and its steps and helpers may then call them without loading.
- One function per file, named the same as the file. Entry scripts (`podshift.sh`, module `main.sh`, `src/test/run.sh`) may keep several; in `src/test/` a file may also keep private helpers used only by its main function. Details in [coding.md](./docs/coding.md#functions).
- Function names say what the function does in plain words and are unique across the project.
- Each load first checks whether the function is already there: `declare -F <name> >/dev/null || source "${DIR_<hash>}/<name>.sh"`.
- A script caches its own folder in a guarded, read-only `DIR_<hash>` variable (12 uppercase hex characters, for example `DIR_3D57253A9314`). Details in [coding.md](./docs/coding.md#conventions).
- A script that needs PodShift settings loads `main.conf` with `load-podshift-conf-main`, with no hardcoded fallback values.
- `export` only for configuration that other processes must see. No symlinks in the repository.
- Logs are plain text, with no color. Color only on interactive output (a terminal), never when output goes to a log or a pipe.
- Every `.sh` file has the bashdoc tags defined in [coding.md](./docs/coding.md#documentation), unless it is listed there as an exception.
- No em-dashes anywhere.
- Step output: each RPM or deployment step (`@category: step` in the RPM and deployment) prints a header `[PS-<phase>-<id>] <message>`, then an indented short status `[OK]` / `[WARN]` / `[SKIP]`. `[WARN]` goes to stderr. The prefix comes from the file's `@step` tag, for example `@step: PS-DP-DRS`.
- Fixed identity is intentional: user `podshift`, UID `300`, home `/home/podshift`, `300@.host`, `/run/user/300`.

### Environment

- Target: Fedora 45 (GNU tools, `sed -i` works).
- Dev host may be macOS (BSD `sed -i` needs `-i ''`).

### Style guide

Everything not covered by the hard rules: [coding.md](./docs/coding.md)

### Temporary files

Anything temporary the agent creates, such as scratch scripts, notes, staging archives and other automation output, belongs under [artifacts/work/](./artifacts/readme.md). Use a subdirectory per task. Build and test output still goes in `artifacts/logs/` and `artifacts/rpm/` as the test runner defines. Do not leave temporary files anywhere else, and do not place them directly in `artifacts/`. Clear them with `./test clean-work`. The test engine creates `artifacts/work/` at startup if it is missing.

### How to work

- Change only what the task needs, one issue at a time. Do not add features nobody asked for.
- Test real behaviour; do not guess values, paths or command output.
- Ask before deleting any file.
- Docs state only verified facts. Status notes such as "Coming soon" belong only in [roadmap.md](./docs/roadmap.md).

### Built-in help

The two CLIs generate their help from Markdown: the PodShift CLI from `src/server/opt/podshift/doc/help/`, the Test Lab CLI from `src/test/cli/tests/*/readme.md` and `src/test/readme.md`.

## Testing

Just downloaded? Run `bash test --plain quick`. Expect exit 0. Exit 3 means a missing tool: read the `Fix:` line. A pass is not a full validation; see Which tests run where.

Run from the project folder:

- `./test` lists all tests and options.
- `./test --help <test>` shows one test: its Platforms and Needs. That wins over any doc.
- Quick check after a change: `./test --plain lint-cli-modules lint-pure-functions lint-help-files lint-bashdoc-description-length`
- Cockpit handler: `./test --plain unit-cockpit-api`
- Build the RPM only (needs the dev host): `./test --plain build-rpm`
- Full check (needs the dev host: build, install in a test VM, validate): `./test --plain bundle-build-install-validate`

Which tests run where:

- Anywhere: `lint-*`, `dev-cli-help`, `quick`. `dev-cli-help-show-all` also needs `glow`. `dev-cli-help-show` does not. `quick` pulls in unit, so bats is still required for a full pass.
- Need bats: `unit-pure-functions` (and `lint-pure-functions` first). Missing bats exits 3, not a PodShift bug.
- Need the dev host: anything whose Needs include `host-check` (`build-*`, `install-*`, `postinstall-*`, `bundle-*`, `host-container-start`, `hello`). The host is a Mac with Apple container and Lima, or a Fedora desktop as in [What you need](./src/test/readme.md#what-you-need). Other Linux is unsupported and exits 3.

Exit codes: `0` passed, `2` PodShift problem (only this means a product bug), `3` cannot run here (read the `Fix:` line), `1` error in the test or its setup. Never report `3` or `1` as a code bug.

If you cannot provision the dev host, run the lint tests (and unit if bats is installed), then list by name each test not run, with its exit code or `Fix:` line.

If `./test` says "permission denied": `chmod +x test`

Details: [testing guide](./src/test/readme.md)

## Installation

Installing PodShift on a server: [usage.md](./docs/usage.md#installation). It is always from an RPM: COPR (preferred) or a local RPM file (testing only).

## Using

Operating an installed server: [usage.md](./docs/usage.md#usage). Every command also has built-in help: `podshift --help` and `podshift --help <command>`.
