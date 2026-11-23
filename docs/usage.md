# Usage instructions

How to install and use PodShift.

## Installation

A server install is the default. It hardens the computer: it enables the firewall and fail2ban, and sets SSH to key-only login.

A desktop install is for trying PodShift on your own computer. It leaves the firewall, fail2ban and SSH login rules as they are, so your computer keeps working the way you set it up. Everything else, including the SSH ports, is the same as on a server.

For a desktop install, create `/etc/podshift-desktop` before you install the package.

### Check the machine first

The precheck tells you whether PodShift can be installed and run on this machine. It only reads, and changes nothing. See the [precheck readme](../utils/portable/readme.md) for what it checks.

```
curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | sudo bash
```

### Server install (default)

#### From COPR

```
sudo dnf copr enable -y vellamo/podshift && sudo dnf install -y podshift
```

#### From your own build

Build the package first (see [Testing](../src/test/readme.md#build-the-package)), then run this in the project folder:

```
sudo dnf install -y ./artifacts/rpm/podshift-*.noarch.rpm
```

### Desktop install

#### From COPR

```
sudo touch /etc/podshift-desktop && sudo dnf copr enable -y vellamo/podshift && sudo dnf install -y podshift
```

#### From your own build

Build the package first (see [Testing](../src/test/readme.md#build-the-package)), then run this in the project folder:

```
sudo touch /etc/podshift-desktop && sudo dnf install -y ./artifacts/rpm/podshift-*.noarch.rpm
```

### PodShift UI (optional)

PodShift UI is an optional Cockpit page that shows the server's containers, volumes, networks, images, secrets, services, Quadlets and health, for administrators and the podshift user. See the [PodShift UI docs](https://github.com/vellamo-dev/cockpit-podshift/blob/main/docs/readme.md).

PodShift adds PodShift UI to the Applications page in Cockpit. Open Applications and press Install next to PodShift UI. The package comes from the `vellamo/cockpit-podshift` COPR repository, which PodShift enables, so no other step is needed.

From a terminal:

```
sudo dnf install -y cockpit-podshift
```

### Check the install

```
sudo podshift health-check
```

## Running commands

PodShift has two identities: **root** (your admin account) and **podshift** (UID 300, the unprivileged user that owns all containers and user services).

### Who can run what

| | bare shortcuts | `podshift` CLI | raw `podman` |
|---|---|---|---|
| as `podshift`, or after entering it | ✅ yes | ✅ yes (non-admin) | ✅ yes |
| as `root` | ⛔️ no | ✅ yes (realm-aware) | ⛔️ no (of podshift's store) |

The containers belong to `podshift`, so you either are that user, or you enter it.

### Enter the podshift user

The everyday way:

```bash
sudo -u podshift -i
```

Two other ways exist and give the same result:

- `machinectl shell podshift@` - a systemd login session
- `systemd-run --machine=podshift@.host --user --wait --pipe --quiet bash` - the low-level form, which the Cockpit API handler uses. The `podshift` CLI itself switches with `sudo -u podshift -i`.

Once inside, everything works directly. A login shell of root, the podshift user or an admin (a member of `wheel`) gets the shell helpers `quit` and `hcl` and the `PODSHIFT_*` and `TSV_*` variables from `/etc/profile.d/podshift.sh`; the shells of other users get nothing from PodShift.

List the containers:

```bash
containers
```

Run the health check:

```bash
podshift health-check
```

Read the logs of a container:

```bash
podman logs <container>
```

Show the state of a user service:

```bash
systemctl --user status <name>
```

### Run from root

Root drives everything through the `podshift` CLI, which enters the right realm for each command.

List the containers, which live under podshift; the CLI tunnels in:

```bash
sudo podshift containers
```

Run the health check:

```bash
sudo podshift health-check
```

List the configuration, in the admin realm as root:

```bash
sudo podshift config
```

Root cannot run the bare shortcuts, and `sudo podman ps` shows root's own (empty) store. Use `sudo podshift …` instead.

### One-liners without switching

List the podshift user's containers with Podman:

```bash
sudo -u podshift -i podman ps
```

List them with the shortcut:

```bash
sudo -u podshift -i containers
```

Show the state of a user service:

```bash
sudo -u podshift -i systemctl --user status <name>
```

### SSH ports

sshd listens on port 22 and port 1022. Port 22 is open in the firewall until you close it:

```bash
sudo podshift ssh port 1022
```

To open port 22 again, run `sudo podshift ssh port 22`. See `podshift --help ssh` for details.

### SELinux

PodShift needs SELinux to be enforcing, so containers stay apart from the server and from each other. On a first server install, PodShift switches SELinux from permissive to enforcing. Desktop installs and upgrades leave the mode as it is.

To switch it yourself, for example on a desktop install or after an upgrade, run this command. It asks first, and `--force` skips the question. If SELinux is disabled, the command changes nothing and prints the steps instead.

```bash
sudo podshift selinux enforce
```

See `podshift --help selinux` for details.

## Day-to-day

The built-in help lists every command: `podshift --help`. `podshift --help <command>` or `podshift <command> --help` shows the page for one command without running it.

Run as the podshift user (after `sudo -u podshift -i`):

- `containers`, `images`, `pods`, `networks`, `volumes`, `quadlets` - the rootless resources
- `services`, `failed-services`, `reset-failed`, `daemon-reload` - user systemd service state
- `update` - update containers that have auto-update on
- `status-podman` - the rootless Podman API socket
- `quadlet rm` - remove an installed Quadlet file or app, see [Install and remove Quadlets](#install-and-remove-quadlets)
- `secret` - create, list, replace, and remove Podman secrets

`sudo podshift quadlet` and `sudo podshift secret` also work: `podshift` switches an admin to the podshift user with `sudo -u podshift -i`, as for the shortcuts.

Run as root with `sudo podshift`:

- `config` - read and set configuration
- `env` - show or set the environment tag
- `network` - examine, check, and fix the external network
- `ssh` - turn the firewall ssh service (port 22) on or off
- `selinux` - switch SELinux to enforcing
- `update-self` - update PodShift itself, and the Cockpit UI when it is installed from a repository
- `health-check` - check the server
- `status-cockpit`, `status-firewall`, `status-user` - system service status

### Install and remove Quadlets

A Quadlet file or `.zip` bundle dropped into `/home/podshift/drop` is checked and installed once. The folder is fixed: `podshift-drop.path` watches it, so changing `PODSHIFT_DROP_DIR` does not move the watch. PodShift never replaces an installed Quadlet:

- Only `.container`, `.volume`, `.network` and `.image` files are accepted, alone or in a bundle. Pods are not supported yet: a dropped `.pod` goes to `/home/podshift/trash`, and a bundle with a `.pod` in it is rejected. A file with a `Pod=` key is refused too.
- The same file again (same content after the `TSV_` values are filled in) is logged as `unchanged` and moved to `/home/podshift/trash`.
- A different file with an installed name, or an app that is already installed, is refused and moved to `/home/podshift/.quadlets/rejected` with the reason "already installed, remove it first".
- The name key (`ContainerName`, `NetworkName`, `VolumeName`) must be set and equal the file base name, so `web.container` sets `ContainerName=web`.
- A base name must not end with `-pod`, `-network`, `-volume`, `-image` or `-build`. Quadlet adds those endings to the service names, so `web.network` runs as `web-network.service`.
- The name must be free in Podman for that type.
- Every Quadlet file it refers to (`Network=front.network`, `Volume=data.volume:/data`) must be installed, waiting in the drop, or in the same bundle. Every `Secret=` must exist as a Podman secret.
- A plain name such as `Network=web`, `Volume=data:/data` or `Mount=type=volume,source=data,...` is not checked at install, but it counts as a use of an installed `web.network` or `data.volume`, so removing that file is refused. `Network=host`, `none` and similar, paths, `Pod=` without `.pod` and registry images are not counted.

To change an installed Quadlet, remove it, then drop the new version.

Every drop gets its own drop ID, a UUIDv7 that starts with the time. A dropped Quadlet file gets the line `# podshift-drop-id: <uuid>` as its first line, and every file of a bundle gets the same line. The Drop History in Cockpit shows one row per drop.

Show the drop ID of the installed web.container as the podshift user:

```bash
head -n 1 /home/podshift/.config/containers/systemd/web.container
```

Remove the single file web.container as the podshift user:

```bash
podshift quadlet rm web.container
```

Remove the app shop and its Podman volumes, without the question:

```bash
podshift quadlet rm shop --volumes --yes
```

A removal is refused while another installed Quadlet refers to it. Volumes are kept unless `--volumes` is given. See `podshift --help quadlet`.
