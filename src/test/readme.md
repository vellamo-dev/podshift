# PodShift tests

The tests build the PodShift RPM in a Fedora container, install it in a Fedora VM, and check the result.

There is one runner, `src/test/run.sh`, for every computer. It finds out which OS it runs on and uses the parts made for that OS.

## Quick start

Run from the project root. The first time, make `./test` executable:

```sh
chmod +x test
```

Then run tests:

```sh
bash test --plain quick                # first check after a download, no containers
./test host-check                      # is this computer ready for build/install?
./test bundle-build-install-validate   # build, install and validate (needs the dev host)
./test clean-all                       # remove everything the tests made
```

A pass of quick is not a full validation. See [What runs where](#what-runs-where).

- `./test --help` lists the tests that can run on this computer.
- `./test --help <test>` shows one test: its tags, its steps and its readme.
- `./test --plain <test>` runs without colors or spinner.
- `./test --fresh <test>` rebuilds the RPM builder image and the installer VM image instead of reusing them. Use it for a forced, clean run.

`./test` is a short script that runs `src/test/run.sh`, so both work the same. Always type the `./`: a bare `test` is a shell command that does nothing here.

A git clone already has `./test` executable. A synced copy may not, so run `chmod +x test` once, or `bash test <test>`, which also makes it executable.

### Build the package

```
./test build-rpm-export
```

The package is saved in `artifacts/rpm/`.

## What you need

On a Mac:

- Apple silicon;
- the [Apple container CLI](https://github.com/apple/container/releases), for the RPM builder container;
- [Lima](https://lima-vm.io), for the installer VM: `brew install lima`;
- `glow`, to read the help: `brew install glow`.

On Fedora, the packages that `host-check` asks for. Your computer must also be marked as a desktop with `sudo touch /etc/podshift-desktop`. Without that file, no `./test` command runs on Fedora. This way the tests can never install the server package on your own computer.

You don't have to check this by hand. `host-check` does it and prints a `Fix:` line for anything missing.

### Optional apps

The tests never need these. They are GUIs that make it easier to see what the tests made, which helps if you are new to containers and VMs.

- [Davit](https://davit.app/): a GUI for Apple `container`, to see the RPM builder image and container.
- [0ma](https://github.com/chenhunghan/0ma/releases): a GUI for Lima, to see the installer VM and open a terminal in it. Install it with `brew install chenhunghan/tap/0ma`.
- [Podman Desktop](https://podman-desktop.io/downloads): a GUI for Podman, useful for PodShift work in general. It does not show the test VM or containers.

## What runs where

- Anywhere: `lint-*`, `dev-cli-help` and `quick`. `dev-cli-help-show-all` needs `glow`; `dev-cli-help-show` does not. `quick` also runs unit, so bats is still required for a full pass.
- Need bats: `unit-pure-functions` (it checks bats itself and exits 3 if it is missing).
- Need the dev host: anything whose Needs include `host-check` (`build-*`, `install-*`, `postinstall-*`, `bundle-*`, `host-container-start`, `hello`). On a Mac that is Apple container and Lima; on Fedora the packages and desktop mark in [What you need](#what-you-need). Other Linux is unsupported and exits 3.

Before full tests, run `./test host-check`, then `./test host-container-start`. The `Fix:` lines cover this machine's host tools only: not bats, and not an installed test VM (`postinstall-*` need that). For one test, `./test --help <test>` prints its Platforms and Needs.

## Tests

Test names put the area first and the action last.

| Area | Tests | What they do |
|------|-------|--------------|
| `host-` | `host-check`, `host-container-start` | Check this computer and start its container system. |
| `build-` | `build-image` to `build-rpm-export` | Build the RPM in a Fedora container. |
| `install-` | `install-rpm-check` to `install-validate` | Install the RPM in a Fedora VM and check the install. |
| `postinstall-` | `postinstall-vm-check`, `postinstall-health-check`, `postinstall-health-output` | Check an already installed system: the VM, the health check and its output. |
| `lint-` | `lint-cli-modules`, `lint-help-files`, `lint-pure-functions`, `lint-bashdoc-description-length`, `lint-bashdoc-required-tags`, `lint-bashdoc-conditional-tags`, `lint-bashdoc-tag-values` | Read the PodShift source and check it, without running anything. |
| `unit-` | `unit-pure-functions` | Run bats unit tests on single pure functions (files tagged `@unit-test: yes`), with no build or install. Needs bats-core. |
| `unit-` | `unit-cockpit-api` | Checks the Cockpit JSON handler, ping module and contracts on this computer. The podshift session is mocked. Needs jq. |
| `dev-` | `dev-cli-help`, `dev-cli-help-show`, `dev-cli-help-show-all` | Run PodShift code on this computer, with no build or install. The `-show` tests print the help for a person to read. |
| `hello` | `hello` | Prints a greeting, to check that the test runner works. |
| `quick` | `quick` | Source-only checks after a download. A pass is not a full validation. |
| `bundle-` | `bundle-build-install-validate` | The whole chain, ending with `podshift health-check`. |
| `clean-` | `clean-containers`, `clean-rpm-output`, `clean-tmp`, `clean-work`, `clean-logs`, `clean-all` | Maintenance: remove what the tests or agents made. |

A test runs the tests it needs first, in order, and each test runs only once per run. So you can start any test on its own.

`clean-containers` removes the test VM, container and images. `clean-rpm-output` removes the built RPMs. `clean-tmp` removes `artifacts/tmp/`. `clean-work` removes `artifacts/work/`. `clean-logs` removes all logs. `clean-all` runs the container, RPM, tmp, work and logs cleanups and checks that nothing is left.

## Reading the output

Each test prints a block with its steps and a verdict:

```
▶ Installing RPM package

    Progress:
        ✔ Install RPM package [podshift-1.0.0-1.fc45.noarch.rpm, 52s]
        ✔ Verify install output [12 OK, 2 skipped, 0 not OK]

    Verdict:
        ✔ Passed
```

The run stops at the first test that does not pass. The Summary at the end shows every planned test, the first problem, and the tests that did not run:

```
◆ Summary

    ✔ Checking host          passed
    ✘ Checking RPM package   cannot run   Find RPM package: Expected one RPM in artifacts/rpm, found 0
    ○ Installing RPM package not run

    Result: cannot run (exit 3)
```

Output is plain by itself when there is no terminal, or when `PODSHIFT_PLAIN=true`, `NO_COLOR`, `CI` or `TERM=dumb` is set. The `Output:` line at the top says which mode is used and why.

## Exit codes

The run returns the code of the test that stopped it. Only `2` means a PodShift bug; `3` and `1` are the environment or the test setup.

| Code | Meaning |
|------|---------|
| 0 | passed |
| 1 | error in the test or its environment |
| 2 | PodShift problem |
| 3 | cannot run here, see the `Fix:` line |

The runner also refuses to start when Bash is older than `TST_BASH_MIN_VERSION` in `src/test/cli/shared/conf/tests.conf` (default 5.0). Both the running shell and the `bash` found on PATH must meet that minimum, because steps and child scripts use `#!/usr/bin/env bash` and bare `bash`.
| 130 | stopped with Ctrl+C |

## Logs

At start, the runner creates `artifacts/logs/`, `artifacts/rpm/` (or `TST_RPM_SHARE_DIR`), `artifacts/tmp/` and `artifacts/work/` and stops with exit 3 if any of them cannot be used as a real, writable directory.

Each run gets its own folder, `artifacts/logs/<YYYYMMDD-HHMM-NNN>/`, with:

- `start.log`: one line about the run;
- one log per test, for example `install-rpm.log`;
- larger outputs, such as `rpmbuild.log`, `install.log` and `health-check.log`;
- `summary.log`: the same Summary as on screen.

Logs have no colors.

## How OS differences are handled

Most of the suite is shared. Only what really differs per OS lives in an `os-specific/<os>/` folder, for example `mac` or `fedora`.

1. At start, the runner asks each `cli/os-specific/<os>/is-this-os.sh` whether this is its OS. The first one that says yes wins.
2. It loads that OS's settings, `conf/os.conf`, and its helpers, `fn/`. For example, the helper `container-cli` runs `container` on a Mac and `podman` on Fedora.
3. For each test, it adds the steps in `tests/<test>/os-specific/<os>/steps/` to the shared steps. An OS step with the same file name as a shared step replaces it.
4. A test runs only where its `@platforms` tag allows. Tests that don't depend on the OS use `all`.

To add a new OS, add a folder under `cli/os-specific/` with an `is-this-os.sh`, a `conf/os.conf` and the helpers in `fn/`.

## Folder layout

```
test                                    runs src/test/run.sh, from the project root
src/test/
    run.sh                              the runner
    readme.md                           this guide
    cli/
        shared/                         used on every OS
            conf/tests.conf             settings
            conf/help.txt               the fixed part of --help
            fn/                         helpers, one function per file
            containerfiles/             Containerfiles
        os-specific/<os>/               used on one OS only
            is-this-os.sh               says whether this is that OS
            conf/os.conf                settings
            fn/                         helpers
            containerfiles/             Containerfiles
        tests/<test>/                   one folder per test
            main.sh                     the tags
            readme.md                   a short description
            steps/                      shared steps
            os-specific/<os>/steps/     steps for one OS
            data/, scripts/             files for this test only
```

Put code in `cli/shared/` when you can, and in `cli/os-specific/<os>/` only when it differs. A test's own folder holds only what belongs to that test.

## Writing a test

1. Make a folder `cli/tests/<name>/` (usually `<area>-<action>`; short names such as `quick` or `hello` are fine).
2. Add `main.sh` with the tags:

   | Tag | Meaning |
   |-----|---------|
   | `@title` | The block title, for example `Installing RPM package`. |
   | `@description` | What the test does, in one sentence. |
   | `@platforms` | `all`, or the OS names it runs on, for example `mac`. |
   | `@needs` | The full chain of tests it needs, in run order. |
   | `@purpose` | Optional. `maintenance` for cleanup tests. The default is `test`. |

3. Add steps as `steps/<NNN>-<name>.sh`, each with one function called `<name>`. The step title is the first `@description` line of the file.
4. Add a short `readme.md`: a `# <test>` heading, one or two sentences, and an optional `## Examples` section.

Step rules:

- Steps 100 to 499 set things up. If one does not pass, the rest of the test is skipped.
- Steps 500 to 999 verify. They all run, so one run shows every problem.
- A step returns 0 for pass, 2 for a PodShift problem, 3 when it cannot run here (with a `Fix:` line), and anything else for an error.
- A step can print `NOTE: <text>`, shown in brackets after the step title, and `DETAIL: <text>` lines, shown under it.
- A test needs at least one step of its own.

## Writing a unit test

1. Tag the function file `# @unit-test: yes` only if it is pure: arguments in, text out, nothing read from the system. Do not tag wrappers that call `ss`, `firewall-cmd` and the like.
2. Add `src/test/unit/<function>.bats` (same base name as the `.sh`). Header: a bats shebang, a comment naming the function and its path, and `# Run with: ./test unit-pure-functions`.
3. In `setup()`, `source "${TST_PODSHIFT_DIR}/fn/.../<function>.sh"`. In each test, `run` it, then check `${status}` and `${output}`. Pass test data as arguments; do not fake system commands.
4. Run `./test lint-pure-functions` (the tag and the bats file must match both ways), then `./test unit-pure-functions` (needs bats-core).

Unit rules:

- Check `${status}` and `${output}` in every test. For an `is-x` function, also check that the output is empty.
- Put temp files under `${BATS_TEST_TMPDIR}`. Keep helper functions inside that bats file.
- The tests run in a clean environment with only `PATH`, `HOME` and `TST_PODSHIFT_DIR`. Set anything else in `setup()`.
- Do not set `LC_ALL` or `LANG` inside a function under unit test. Letter ranges such as `[A-Za-z]` follow the locale. For ASCII-only checks, write the characters out in full. See [Bash crashes on macOS when a function sets local LC_ALL=C](../../docs/known-issues.md#bash-crashes-on-macos-when-a-function-sets-local-lc_allc).
- Use the built-in bats checks only (`run`, `${status}`, `${output}`, `[ ... ]`). Do not use bats-assert.

## Mac installer VM notes

On a Mac, the installer VM runs with Lima, from the Fedora Cloud image named in `cli/os-specific/mac/lima/rpm-installer.yaml`. `install-image` builds a stopped base VM from it once a week, and `install-vm-start` clones the test VM from that base in seconds. It is close to a server, but not the same:

- `systemd-detect-virt` reports `apple`;
- it starts from the Fedora Cloud image, not Fedora Server, so the provision script in that file adds the server packages and settings;
- systemd needs a moment after boot, so the tests wait for `systemctl is-system-running`;
- the test VM is always cloned fresh and never started again after PodShift is installed;
- the base must stay stopped. Started by hand, it saves a machine-id that every later clone would share; `./test --fresh install-image` builds a clean one.

## Using the installer VM by hand

The full chain leaves the test VM running, so you can inspect the installed server. Two VMs exist, and only one is yours to touch:

- the base VM `ps-rpm-installer-base-fc45` is stopped and is only for cloning. Never start it by hand, because it would save a machine-id that every later clone would share. If you did, `./test --fresh install-image` rebuilds it;
- the test VM `ps-rpm-installer-fc45` is the clone and the one to use.

```sh
limactl list                           # every VM and its state
limactl shell ps-rpm-installer-fc45    # a shell as the VM user (current user), not root
limactl stop ps-rpm-installer-fc45     # stop it
limactl start ps-rpm-installer-fc45    # start it again
limactl delete ps-rpm-installer-fc45   # remove it
```

`limactl shell` runs as the VM user, not root. Switch to root inside that shell with `sudo -i`. Or SSH in with the test key (the provision writes it to root's authorized_keys), on port 22 on a fresh VM and 1022 after PodShift is installed:

```sh
ssh -i ~/.ssh/podshift-test-vm -p 22  root@<ip>    # fresh VM
ssh -i ~/.ssh/podshift-test-vm -p 1022 root@<ip>   # after PodShift
```

`limactl show-ssh ps-rpm-installer-fc45` prints the connection details when you lose the IP.

Deleting the test VM is safe and cheap: the base survives, and the next run clones it again in seconds. `./test clean-containers` removes the test VM, the RPM builder container and the images together.
