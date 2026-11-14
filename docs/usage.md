# Usage instructions

How to install and use PodShift.

## Installation

A server install is the default. It hardens the computer: it enables the firewall and fail2ban, and sets SSH to key-only login.

A desktop install is for trying PodShift on your own computer. It leaves the firewall, fail2ban and SSH login rules as they are, so your computer keeps working the way you set it up. Everything else, including the SSH ports, is the same as on a server.

For a desktop install, create `/etc/podshift-desktop` before you install the package.

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

```sh
sudo -u podshift -i
```

Two other ways exist and give the same result:

- `machinectl shell podshift@` - a systemd login session
- `systemd-run --machine=podshift@.host --user --wait --pipe --quiet bash` - the low-level form `podshift` itself uses

Once inside, everything works directly:

```sh
containers                  # list containers
podshift health-check       # the health check
podman logs <container>     # read logs
systemctl --user status …   # user service state
```

### Run from root

Root drives everything through the `podshift` CLI, which enters the right realm for each command:

```sh
sudo podshift containers      # containers live under podshift; the CLI tunnels in
sudo podshift health-check
sudo podshift config …        # admin realm, runs as root
```

Root cannot run the bare shortcuts, and `sudo podman ps` shows root's own (empty) store. Use `sudo podshift …` instead.

### One-liners without switching

```sh
sudo -u podshift -i podman ps
sudo -u podshift -i containers
sudo -u podshift -i systemctl --user status <name>
```

### SSH ports

sshd listens on port 22 and port 1022. Port 22 is open in the firewall until you close it:

```sh
sudo podshift ssh port 1022
```

To open port 22 again, run `sudo podshift ssh port 22`. See `podshift --help ssh` for details.

## Day-to-day

The built-in help lists every command: `podshift --help` and `podshift --help <command>`.

Run as the podshift user (after `sudo -u podshift -i`):

- `containers`, `images`, `pods`, `networks`, `volumes`, `quadlets` - the rootless resources
- `services`, `failed-services`, `reset-failed`, `daemon-reload` - user systemd service state
- `update` - update containers that have auto-update on
- `status-podman` - the rootless Podman API socket

Run as root with `sudo podshift`:

- `config` - read and set configuration
- `env` - show or set the environment tag
- `network` - examine, check, and fix the external network
- `secret` - create, list, replace, and remove Podman secrets
- `ssh` - turn the firewall ssh service (port 22) on or off
- `update-self` - update PodShift itself
- `health-check` - check the server
- `status-cockpit`, `status-firewall`, `status-user` - system service status
