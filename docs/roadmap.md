# Roadmap

What PodShift does today and what is planned, in rough priority order within each table. Details may change.

| Icon | Status |
|:---:|---|
| ✅ | Ready |
| 🚧 | In progress |
| 📋 | Planned |
| ❌ | Rejected |

## Features

### Documentation

Documentation lives in the code and in the commands, so it doesn't fall out of date. Every script describes itself in its header, and every command and test has built-in help. Separate documents are kept few and short, and cover only what code and help can't: the why, the scope and the big picture.

| Status | Name | Description |
|:---:|---|---|
| ✅ | General README | What PodShift is and the problems it solves. |
| ✅ | Documentation index | The list of all documents, in [docs/readme.md](./readme.md). |
| ✅ | Scope | Goals, principles, main features and requirements. |
| ✅ | Coding guide | Coding style and principles. |
| ✅ | Testing README | How to run the tests, in [src/test/readme.md](../src/test/readme.md). |
| ✅ | RPM Stager README | How the RPM's contents are built. |
| ✅ | Agents guide | A guide for AI agents working in this repository. |
| ✅ | Forking | The rules for forks: rebrand, state the changes and give your own support. |
| ✅ | Support | Where and how to report bugs and ideas. |
| ✅ | Roadmap | This document. |
| ✅ | Cockpit API | The JSON handler, the ping module and capability discovery are in the source tree. The Cockpit screen is not built. |
| ✅ | Usage guide | How to install PodShift from COPR and use it day to day. |

### Rootless Podman server

One RPM install turns a Fedora server into a server that runs containers without root, under a dedicated user.

| Status | Name | Description |
|:---:|---|---|
| ✅ | One-command install | `dnf install` sets up the whole server, with each step shown and logged to the journal. |
| ✅ | Dedicated podshift user | An unprivileged user that owns and runs all containers. |
| ✅ | Always-on user services | Linger and user units, so containers start at boot without a login. |
| ✅ | Automatic container updates | Podman's auto-update timer is enabled and tuned for the podshift user. |
| ✅ | Helper tools | `tree`, `less`, `nano`, `glow`, `unzip` and `jq` for managing the server and the Cockpit API handler. |
| ✅ | Uninstall | Removing the RPM stops the auto-update timer and leaves the data and the podshift user in place, with a list of what is left, also in the journal. |

### Built-in Hardening

The server is hardened during install, without extra steps.

| Status | Name | Description |
|:---:|---|---|
| ✅ | Rootless containers | Containers never run as root. |
| ✅ | SELinux enforcing | SELinux stays on, with the labels and ports PodShift needs. |
| ✅ | Firewall | firewalld is enabled with a PodShift service. |
| ✅ | Brute-force protection | fail2ban is enabled. |
| ✅ | Unprivileged ports | Rootless containers can use ports below 1024. |
| ✅ | Registry login | A private auth file for the podshift user's registry logins. |
| ✅ | Secrets | `podshift secret` keeps credentials in Podman secrets. |

### Misc Tweaks

Small changes that make the server easier to run, without extra steps.

| Status | Name | Description |
|:---:|---|---|
| ✅ | SSH port 1022 | sshd listens on ports 22 and 1022, so you can move to 1022 and avoid the bots that try port 22. A fresh install keeps port 22 open until you run `podshift ssh port 1022`. |

### Monitoring

Built-in tools to see how the server is doing.

| Status | Name | Description |
|:---:|---|---|
| ✅ | Web console | Cockpit is enabled for managing the server in a browser. |
| ✅ | Metrics | PCP collects and records system metrics. |
| ✅ | Status shortcuts | Short commands for the state of Podman, the firewall, Cockpit and the podshift user. |

### Drop-In Quadlets

Drop container, network and volume files into a folder, and PodShift checks them and installs them as services that start at boot.

| Status | Name | Description |
|:---:|---|---|
| ✅ | Drop folder | A watched folder that accepts Quadlet files and `.zip` bundles, and moves anything else to trash. |
| ✅ | Validation | Checks each file and keeps rejected ones aside, so the mistake is visible. |
| ✅ | Variable filling | Fills `${TSV_*}` variables with this server's values before dry run. (Part of Automatic install) |
| ✅ | Dry run | Runs Podman's Quadlet generator on each validated file, without installing anything, to catch errors before the install.  (Part of Automatic install) |
| ✅ | Automatic install | After validation and a successful dry run, files are installed automatically as systemd user services that start at boot. |
| 📋 | Uninstall | Removing a source file removes its services. |
| 📋 | Quadlet logs | A shortcut to see the state and logs of the installed Quadlet services. |

### Server Health Check

`podshift health-check` checks the whole server and gives a `Fix:` line under each warning or failure.

| Status | Name | Description |
|:---:|---|---|
| ✅ | Server checks | Host, runtime, security, config and network checks, each in its own group. |
| ✅ | Script output | `--tsv` and `--json` output for scripts and monitoring. |
| 📋 | Sharper checks | More exact SSH and user namespace checks, and the config passed to every check. |
| 📋 | Quadlet checks | Checks for the drop folder, rejected and failed files, and installed services. |
| 📋 | Real server testing | Run the checks on real servers, not only test VMs. |

### PodShift CLI

The `podshift` command for everyday server management.

| Status | Name | Description |
|:---:|---|---|
| ✅ | Built-in help | `podshift --help` and help for every command, rendered in the terminal. |
| ✅ | Configuration | `podshift config` and `podshift env` read and change runtime settings. |
| ✅ | Network | `podshift network` examines, checks and fixes the server's external network. |
| ✅ | Listings | Short commands that list containers, images, pods, networks, volumes and services. |
| ✅ | Service fixes | Short commands to reload units and reset failed services. |
| ✅ | Updates | Update containers, and `podshift update-self` updates PodShift. |

### RPM Stager

Build-time scripts in `src/deployment` that turn the `src/server` tree into the RPM's contents. They run only when the package is built. See [src/deployment/readme.md](../src/deployment/readme.md).

| Status | Name | Description |
|:---:|---|---|
| ✅ | Folder layout | Recreates the server's folder layout in the RPM build root. |
| ✅ | File permissions | Scripts are installed executable, all other files read-only. |
| ✅ | File allowlist | Only file types on the allowlist go into the package. |
| ✅ | Command links | Short commands without `.sh` in `/usr/bin` and `/usr/sbin`. |
| ✅ | Package file list | Generates the file list the RPM spec installs. |
| ✅ | SELinux label list | Generates the folder list that gets SELinux labels restored at install. |
| ✅ | Fail-safe build | Any failure stops the build instead of making an incomplete RPM. |

### Packaging and delivery

PodShift is a single RPM for Fedora.

| Status | Name | Description |
|:---:|---|---|
| ✅ | RPM package | One `noarch` RPM built from this repository. |
| 🚧 | GitHub publishing | Publish the source on GitHub, which COPR builds the RPM from. |
| 🚧 | COPR repository | Publish the RPM through Fedora's COPR so users install it with `dnf`. |

### Test Lab

`./test` builds, installs and checks PodShift in a fresh VM, on a Mac or on Fedora. See [src/test/readme.md](../src/test/readme.md).

| Status | Name | Description |
|:---:|---|---|
| ✅ | Test runner | `./test <test>` runs a test and everything it needs, with built-in help. |
| ✅ | Mac support | The RPM is built in an Apple `container` and installed in a Lima VM. |
| ✅ | Fedora support | The RPM is built in Podman and installed in a KVM VM. |
| ✅ | Fast test VM | On a Mac, the VM is cloned from a stored base in seconds. |
| ✅ | Image reuse | Built images are reused for a set time; `--fresh` rebuilds them. |
| ✅ | Plain output | `--plain` gives output without colors or spinner, for scripts and agents. |
| ✅ | Install tests | Build, install, validate and health check in one run. |
| ✅ | Lint and unit tests | Checks for the CLI modules, help files and pure functions. |
| ✅ | Cleanup | Tests that remove containers, VMs, logs and build output. |
| 📋 | Upgrade and uninstall tests | Automated tests for upgrading and removing PodShift. |
| 📋 | Run summary file | One file per run with every result, for scripts and agents. |
| ❌ | Apple container test VM | Replaced by Lima, which runs a full Fedora with systemd. |

## Bugs

Known bugs are fixed as they are found. Report new ones as described in [support.md](./support.md).
