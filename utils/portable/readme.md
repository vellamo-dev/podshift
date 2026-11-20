# Portable precheck

`precheck.sh` answers one question before you install PodShift: can PodShift be installed on this machine, and will it work here?

It first gathers facts about the system and shows them. Then it checks them step by step. A blocker stops the run, because nothing after it matters. For example, if the system isn't Fedora 45 or newer, it doesn't go on to check packages. The sections run in this order: OS, PodShift, network, packages, then security and clashes. The network comes before the packages, because without a route `dnf` can't download anything.

## Run it

With one line, straight from GitHub:

```bash
curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | bash
```

With **sudo** it also does a `dnf` dry run of PodShift's packages, which needs root:

```bash
curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | sudo bash
```

Options go after `bash -s --`, for example:

```bash
curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | bash -s -- --json
```

If you'd rather read the script first, download it and run `bash precheck.sh`.

## Options

| Option    | What it does                                                                         |
| --------- | ------------------------------------------------------------------------------------ |
| `--plain` | No colours. This is automatic when the output isn't a terminal or `NO_COLOR` is set. |
| `--json`  | Prints only a JSON result, for scripts and CI.                                       |
| `--help`  | Shows the help.                                                                      |

## Exit codes

| Code | Result              | Meaning                                                    |
| ---- | ------------------- | ---------------------------------------------------------- |
| 0    | Ready               | PodShift can be installed here.                            |
| 1    | Ready with warnings | PodShift can be installed here. Read the warnings first.   |
| 2    | Not possible        | A blocker was found. Fix it and run the check again.       |
| 3    | Installed           | PodShift is already installed.                             |
| 4    | Wrong option        | An unknown option was given.                               |

## What it checks

**System facts** (shown first, no pass or fail): OS, edition, install type, kernel, architecture, Bash, CPUs, memory, free disk on `/`, `/var` and `/home`, virtualisation, hardware, cloud, cloud-init, hostname, IP addresses, the network (backend, active connection, IPv4 method, default route and global IPv4 on its device), SELinux, whether `/usr` is writable, who it runs as, the installed PodShift and Podman versions, and whether the PodShift Copr repo is enabled.

The edition comes from the installed `fedora-release-identity-*` package, for example `workstation` or `server`. Cloud images have the `basic` identity, shown as `none (basic identity)`. Without `rpm` or the package, it falls back to `VARIANT_ID` in `/etc/os-release`, and without that it shows `not set`.

The hardware is the vendor and product name from `/sys/class/dmi/id` (`sys_vendor` and `product_name`), for example `Intel(R) Client Systems NUC12WSHi5`. Firmware placeholders such as `To Be Filled By O.E.M.` or `Default string` are left out, and with nothing left it shows `unknown`.

The cloud name comes from `/run/cloud-init/cloud-id`, then from `v1.cloud_name` in `/run/cloud-init/instance-data.json`, then from `cloud-init query`. The zone comes from `v1.availability_zone`, shown in brackets when cloud-init provides one, for example `aws [eu-west-1a]`. `cloud-init` is only run when it is installed, with a time limit. Without an answer from any of these, it shows `none detected`. The check has no provider-specific rules and never asks a metadata service over the network.

Cloud-init shows its state from local files only: `not installed` (no `cloud-init` command, `/etc/cloud` or `/run/cloud-init`), `disabled` (`/etc/cloud/cloud-init.disabled` or `/run/cloud-init/disabled`), `ran` (`/var/lib/cloud/instance/boot-finished`), `enabled, not run yet` (`/run/cloud-init/enabled`) or `installed, not enabled`. When `/var/lib/cloud/instance/user-data.txt` is not empty, it adds `user data present`. The user data itself is never read.

**Checking OS**

- The OS is Fedora. Anything else is a blocker.
- Fedora is 45 or newer (`PODSHIFT_MIN_FEDORA`). Older is a blocker.
- Edition: a desktop edition such as Workstation, or a machine that boots to a graphical desktop, is a warning. A server install hardens the whole machine: it enables firewalld and fail2ban, sets SSH to key-only login, and opens ports 80, 81, 443, 1022 and 9090. If `/etc/podshift-desktop` exists, PodShift does a desktop install and leaves the firewall, fail2ban and SSH login rules as they are, so there's no warning.

**Checking PodShift**

- Is PodShift installed? If it is, the check compares it with the newest build in the `vellamo/podshift` Copr repo, if that repo is enabled, and stops with "Installed". If the repo isn't enabled, it says it can't check rather than guess.

**Checking network**

PodShift reads its addresses through NetworkManager, so this section looks at the network the same way PodShift's own `podshift network` commands do. It only runs `ip`, `nmcli` and `systemctl is-active`.

- There's a default route. No default route at all is a blocker, as in `podshift network check`. With only an IPv6 default route, this check passes and the IPv4 check below warns.
- NetworkManager is active. If only `systemd-networkd` is active, or neither is, it's a warning: the install enables and starts NetworkManager, and the two can clash when both manage the network.
- The IPv4 address is set manually (IPv4 method `manual` on the active connection). If it comes from DHCP (`auto`), that is a warning, because the address may change on reboot. After the install, `podshift network examine` shows how to pin it. When cloud-init has run, the warning adds that cloud-init set up this network, and to check your provider's docs before pinning the address. If the method can't be read, for example without `nmcli` or an active connection, it's a note.
- The device of the default route has a global IPv4 address. None (IPv6 only) is a warning, because `TSV_NW1` to `TSV_NW8` are IPv4 addresses.
- The connection name, as a note only. PodShift's default is `cloud-init-eth0` (`PODSHIFT_NW_INITIALIZER` and `PODSHIFT_NW_DEVICE`). It also matches when the active name is `cloud-init eth0` with a space, as cloud-init names it, or when `/etc/NetworkManager/system-connections/cloud-init-eth0.nmconnection` exists. PodShift finds its connection by that file name. With another name and no such file, PodShift falls back to the live addresses, and `podshift network set` can pin the right device after the install.

If `ip` is missing, the route check is a warning. If `nmcli` is missing, the method and connection checks are notes.

**Checking packages**

- `/usr` is writable. Fedora CoreOS, Atomic desktops and image-based (bootc) Fedora are blockers.
- Whether it runs as root. Without root, the dry run below is skipped.
- The Fedora mirrors and Copr can be reached.
- The PodShift Copr repo is enabled, or `dnf copr` is there to enable it.
- Podman 6.0 or newer is installed, or is what `dnf` would install. Older is a blocker. If `dnf` can't tell, it's a warning.
- The system Bash (`/bin/bash`) is 5.0 or newer. Older is a blocker.
- As root: `dnf install --assumeno` with PodShift's `Requires` resolves. A conflict or missing package is a blocker, and the problem lines are shown.

**Checking security and clashes** (warnings only)

- SELinux is enforcing.
- No Docker (`docker-ce`, `moby-engine` or a running `docker` service).
- Nothing already listens on ports 80, 81, 443 or 1022.
- Only one person logs in to the machine.
- UID 300 is free for the `podshift` user.
- For a server install: your user has an SSH key in `~/.ssh/authorized_keys`, because SSH becomes key-only.
- A note, not a warning, when cloud-init user data is present: it runs again when the server is rebuilt.

## Read-only

The check only reads. It never installs anything, never enables a repository and never writes a file. When it asks `dnf` which versions are available, `dnf` may refresh its own metadata cache.

## Single-file exception

The rest of PodShift follows one function per file. This script is the exception: it has to run on its own from a single download, so it has several functions in one file and sources nothing. It needs Bash 3.2 or newer and tools that Fedora ships, and checks every optional tool with `command -v`. All code is inside functions and the last line calls `main`, so a download that's cut off does nothing.

When PodShift changes, keep these in sync at the top of the script (`pc_init`): the minimum Fedora version, the minimum Podman and Bash versions, the `Requires` list from `podshift.spec`, the Copr repo name, the desktop flag file, PodShift's ports and its default network connection (`runtime.conf`).

## Testing

For tests only, the environment variable `PRECHECK_ROOT` points the script at a folder that stands in for `/` when it reads files such as `/etc/os-release`, `/etc/passwd`, `/proc/meminfo`, `/proc/mounts`, `/run/ostree-booted`, `/etc/podshift-desktop`, `/sys/class/dmi/id` and the cloud-init files in `/etc/cloud`, `/run/cloud-init` and `/var/lib/cloud/instance`. Together with stub commands on `PATH` (`rpm`, `dnf`, `id`, `getenforce`, `systemctl`, `ss`, `curl`, `ip`, `nmcli`, `cloud-init`), this lets the checks run for any system without a VM:

```bash
PATH="src/test/cli/tests/precheck-unit/scripts/stubs:/usr/bin:/bin" PRECHECK_ROOT=/tmp/fake-fedora-45 bash utils/portable/precheck.sh --plain
```

The test lab runs these checks for you, from the project root:

- `./test precheck-unit` runs the stubbed bats tests, which cover Workstation, Fedora 44, Debian, CoreOS, an old Podman, a `dnf` conflict, the network checks and more. They need bats, but no VM, network or root. `./test quick` runs them too.
- `./test precheck-vm-clean` copies this script into a fresh installer VM without PodShift, runs it with `--plain` and `--json`, and expects Ready or Ready with warnings. It is the first real check of the `dnf5` output and of the Podman that Fedora offers. `TST_PRECHECK_AS_ROOT=false` runs it without root, and `TST_PRECHECK_MODE` (`plain`, `json` or `both`) picks the output to check.

The tests live in `src/test/cli/tests/precheck-unit/` and `src/test/cli/tests/precheck-vm-clean/`. See their readmes.
