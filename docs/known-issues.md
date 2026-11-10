# Known Issues

Known limits that are understood and accepted for now. Each entry says what happens, when, and what to do about it.

## A broken installed quadlet blocks new installs

**What happens:** if one quadlet file that is already installed has an error, every new drop fails and goes to `failed`, even when the new file is fine.

**Why:** before installing, the installer runs a dry run of the Quadlet generator over the new file and the installed files together, so references like `Network=` resolve. The generator checks every file it gets and fails if any of them has an error. The installer only sees that the dry run failed, so it blames the new file.

**When it can happen:**

- Someone hand-edits an installed file in `~/.config/containers/systemd/` and makes a mistake.
- A Podman upgrade makes an older installed file invalid.

Normal use through the drop folder doesn't cause it.

**How to spot it:** the installer log (`journalctl -t podshift-qdl-install`) shows `dry run failed`, and the generator error names a file that is already installed, not the new one. For example: `vmtest-broken.container: no Image or Rootfs key specified`.

**What to do:** fix or remove the broken installed file, then drop the new item again.

**Possible fix later:** fail the dry run only when an error names a file from staging, and just log errors in installed files.

## Podman networks stay after an app is removed

**What happens:** when a bundle install fails, PodShift removes the partly installed app with `podman quadlet rm --force --recursive <app>`. The Podman networks that the app's `.network` files created are not removed. They stay in Podman's store. The same happens when an app is removed by hand with `podman quadlet rm`.

**Why:** the Quadlet generator turns each `.network` file into a oneshot unit that runs `podman network create`. `NetworkDeleteOnStop` defaults to false, so the generator adds no cleanup. `podman quadlet rm` removes the files and the units, but not the network object.

**When it can happen:**

- A bundle install fails and the bundle had a `.network` file (seen in the v0.0.15 tests on Fedora).
- Someone runs `podman quadlet rm` on an app that has a `.network` file.

A normal install, or a replace that works, doesn't cause it.

**How to spot it:** as the podshift user, `podman network ls` shows a network with no matching `.network` file in `~/.config/containers/systemd/`. The default name is `systemd-<file name without .network>`, unless the file sets `NetworkName=`. Not verified: this default name pattern was not checked on Fedora.

**What to do:** check that nothing uses the network, then remove it as the podshift user with `podman network rm <name>`.

**Possible fix later (option B):** in `remove-app`, read the app's `.network` files before `podman quadlet rm`. Take the name from `NetworkName=`, or use the default name. After `podman quadlet rm`, run `podman network rm <name>` without `--force`, log the result, and keep the return code 0 as it is now. Not verified: it needs a Fedora check of the default name, and of whether `podman network rm` refuses a network that is still in use. Without that refusal, a network shared between apps could be removed by mistake.

**Rejected option A:** add `NetworkDeleteOnStop=true` to the `.network` files at staging. It changes how the app behaves on every stop and restart, and it could break a network that several apps share.

## Bash crashes on macOS when a function sets local LC_ALL=C

**What happens:** on a Mac, a unit test (or any bats `run` of a function) sometimes fails with exit status 139. The test that stopped looks like a product failure (exit 2), for example during `bash test --plain quick`, but the real cause is that bash itself crashed.

**Why:** Homebrew bash 5.3.20 on macOS 27.2, when a function does `local LC_ALL=C` and is then called under bats `run`, can crash with SIGSEGV. The macOS crash report shows the fault in the system locale and preferences code, not in the PodShift checks. Letter ranges such as `[A-Za-z]` also follow the locale, so they are a separate reason not to rely on ranges for ASCII-only names.

**When it can happen:**

- Running `./test unit-pure-functions` or `bash test --plain quick` on a Mac with that bash, when a function under test sets `local LC_ALL=C` (seen on `is-valid-app-name`: 17 of 30 runs failed before the fix).
- Not tested on Fedora.

**How to spot it:** the unit log shows `[ "${status}" -eq ... ]' failed` with no clear product reason. Status 139 means a signal 11 crash. macOS may also write a `bash-....ips` crash report under `~/Library/Logs/DiagnosticReports/`.

**What to do:** do not set `LC_ALL` or `LANG` inside a function. For ASCII-only checks, write the allowed characters out in full (as in `src/server/opt/podshift/fn/quadlet/is-valid-app-name.sh`). `LC_ALL=C` as a prefix on one external command, for example `LC_ALL=C sort`, is fine and stays.

**Possible fix later:** none in PodShift. A lasting fix would be in bash or macOS. PodShift already works around it for `is-valid-app-name`.

## GUI apps on macOS run the tests with Bash 3.2

**What happens:** running the tests from a macOS GUI app (for example a WebStorm "Shell Script" run configuration) fails with `Bash 3.2 (/bin/bash) is too old to run the tests` and exit 3, even though the same `./test` command works in Terminal.

**Why:** macOS launches GUI apps from `launchd` with a fixed default PATH, not the shell's PATH from `~/.zprofile`. A "Shell Script" run configuration then runs `bash -l`; a login bash reads `/etc/profile`, which resets PATH through `path_helper`, and then `~/.bash_profile`, which does not exist on a machine set up for zsh. So `env bash` and `bash` resolve to `/bin/bash` (3.2) instead of Homebrew bash 5.x. A run configuration `PATH` entry does not help, because the IDE passes it literally and does not expand `$VAR`.

**When it can happen:**

- Running `./test` from WebStorm (or any GUI app) on macOS.
- The machine is set up for zsh, so the Homebrew PATH lives only in `~/.zprofile`.

**How to spot it:** the run fails with `Bash 3.2 (/bin/bash) is too old` and exit 3, while `./test` passes in Terminal.

**What to do:** create `~/.bash_profile` with the portable Homebrew setup, so the login bash also gets the Homebrew PATH:

```sh
if command -v brew >/dev/null 2>&1; then
    eval "$(brew shellenv)"
fi
```

No hardcoded path: `command -v brew` finds Homebrew on Apple Silicon and Intel, and on Linux it is a no-op.

**Possible fix later:** none in PodShift. This is a macOS `launchd` and GUI-app PATH quirk.
