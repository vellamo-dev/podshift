# Scope of Project

Determines what the project is about and what it aims to achieve and what it does not aim to achieve.

## Main Goal

PodShift turns a fresh Fedora server into a self-managing rootless Podman host: you drop in Quadlet files and they run automatically, and you operate it all through convenient built-in commands. Nothing more.

> **Scope test**: does this help a user drop in Quadlets and get running containers on a rootless Podman server, or manage that server more easily through the built-in commands? If not, it's out of scope.

## What PodShift is

PodShift is an installer and manager for a single rootless Podman server. It sets up a dedicated, unprivileged user, configures the system (firewall, SELinux, SSH, networking), and then watches a drop directory: Quadlet files placed there are validated, installed as systemd services, and run automatically. Alongside that, it ships a set of shortcuts and convenience commands (list containers, check service status, view logs, update, configure) so operating the server stays easy without memorising raw `podman` or `systemctl` invocations.

## Who it is for

- **People first**: server admins who run PodShift by hand. Their experience comes before everything else.
- **Automation second**: scripts and agents that use PodShift through the same commands, where that is reasonable and practical.

## What PodShift is not

- **A multi-node or cluster orchestrator**: no Kubernetes/Nomad/Swarm-style scheduling; each server is independent.
- **Cross-platform or cross-distro**: Fedora Linux only, 64-bit.
- **A GUI or web interface**: PodShift is fully managed from the terminal. The Cockpit UI is the separate, optional add-on [cockpit-podshift](https://github.com/vellamo-dev/cockpit-podshift), not core scope.
- **An installer for the UI**: PodShift never installs PodShift UI (`cockpit-podshift`). It only lists the UI on Cockpit's Applications page, and the admin decides whether to install it there.
- **A general system configuration tool**: it is Podman-specific.
- **A re-implementation of Podman, systemd, or firewalld**: it wraps them, never replaces them.
- **A CI system**: PodShift runs and updates containers; it ships no build, test, or push tooling. The server is still a normal Podman host, so you can build and push on it yourself; that's your setup, not PodShift's.
- **Fork maintenance and fork-specific support**: a fork and its users are the fork's responsibility, never this project's.

## The Stack

PodShift adds no runtime of its own. It installs and wires together proven components that the operating system already provides.

| Layer         | Components                            | Role                                                         |
| ------------- | ------------------------------------- | ------------------------------------------------------------ |
| Orchestration | systemd, Quadlet                      | runs containers as services: start, restart, dependencies, timers |
| Containers    | rootless Podman, podman-auto-update   | runs and updates containers without root                     |
| Security      | firewalld, SELinux, fail2ban, OpenSSH | firewall, access control, brute-force protection, remote access |
| Networking    | NetworkManager                        | detects the server's addresses (`TSV_NW*`)                   |
| Monitoring    | Cockpit, PCP                          | web console and performance metrics                          |
| Helper tools  | glow, jq, tree, less, nano, unzip     | built-in help, JSON for the Cockpit API handler, and everyday file work |
| PodShift      | Bash scripts, `podshift` command      | installation, wiring, and day-to-day commands                |
| Delivery      | RPM via COPR                          | installation and updates of PodShift itself                  |

## Principles

Guidelines every contribution must follow. They are in priority order: when two of them conflict, the one higher in the list wins.

1. **Single purpose**: every feature must serve the Main Goal; otherwise it is out of scope.
2. **Human experience first**: people are the main users, so every part they touch must be clear, friendly and pleasant to use, not just working:
   - output is easy to read at a glance, with color and live progress at a terminal;
   - every problem says what is wrong and how to fix it;
   - help is built in, and docs use plain, simple words;
   - a feature is not done until it is pleasant to use.
3. **Non-fatal by default**: never brick a server; log and report, never abort the install.
4. **Strict and logged access on the server**: automated or agent access to the final host (the server PodShift runs on) is off until an admin turns it on, and is never traded for convenience:
   - only listed commands can run, with only the rights they need;
   - one key per client, each with a role;
   - nothing the caller sends ever runs as code;
   - every call is logged: who made it, what ran, and the result.

   The design is in the Automation API (see the roadmap).
5. **Keep it simple**: small Bash scripts and data-driven configuration, no frameworks.
6. **Wrap, don't replace**: use systemd, Podman and firewalld as they are.
7. **Automation where it helps**: scripts and agents can use PodShift when it is reasonable and practical, through the same commands people use:
   - stable exit codes;
   - machine output beside the human one, such as `--tsv` and `--json`;
   - plain output and no prompts when not at a terminal.

   The human output always stays first.
8. **Fixed identity**: UID `300`, `/home/podshift` are hardcoded and not configurable.
9. **Bash only**: see [Development language](#development-language).
10. **When in doubt, it's out of scope**: a "nice to have" that does not serve the goal is a no.
11. **Fork at your own cost**: forks are independent projects; they rebrand and support themselves. See [Forking](./forking.md).
12. **Reports are not work orders**: bug reports and feature requests are welcome, but they create no obligation to fix and no deadline. See [Support](./support.md).

## Main features

PodShift provides the following main features:

- **Rootless Podman server installer**: one command that installs and configures the server:
  - installs helper tools for easier management of the server and its containers:
    - `tree`, `less`, and `nano`: inspect and edit files and directories;
    - `glow`: render the built-in help;
    - `jq`: read and write JSON for the Cockpit API handler;
    - `unzip`: extract archives.
- **Rootless Podman server**: a dedicated, unprivileged server that runs containers without root.
  - updates containers automatically, with rollback to the previous version.
- **Quadlet monitor and installer**:
  - monitors a dedicated directory in the rootless Podman user's home directory;
  - pre-fills variables in quadlet files with values from the local environment;
  - installs quadlets as systemd services.
- **Quadlet uninstaller**: removes installed quadlets.
- **Monitors**: background services and timers that watch the system and install new apps.
- **Health check**: `podshift health-check` checks the server and shows a result, with a `Fix:` line under each warning or failure. It can also print `--tsv` or `--json` for scripts.
- **Utilities**: convenience commands for managing and maintaining the environment:
  - adjust configuration (config, environment, and secrets);
  - list containers, services, and volumes;
  - check the status of core services;
  - view initialization and quadlet logs;
  - update containers and the application;
  - inspect network configuration.

## Delivery

PodShift is delivered as an RPM through [COPR](https://copr.fedorainfracloud.org/), Fedora's community build service. Users enable the PodShift COPR repository and install with `dnf`.

COPR is the only supported delivery channel: PodShift is not shipped as a container image, a standalone binary, or through other package repositories.

## Runtime system requirements

- **Operating system**: Fedora 45. No older versions are supported.
- **Architecture**: 64-bit (x86_64 or aarch64).
- **Kernel**: user namespaces enabled, required for rootless containers.
- **Filesystem**: overlay-capable, with `fuse-overlayfs` as fallback.
- **Network**: outbound access to the container registry so images can be pulled.
- **Storage**: enough free disk space for container images and volumes.
- **Access**: root access to install the package.

## Development system requirements

This project is maintained with very limited resources. It is not backed by a company or a paid team, and every additional platform means real build and test work that those resources do not cover.

The building and testing tooling is supported on **macOS** and **Fedora** only. Windows and other Linux distributions are not supported. This is not a preference; it is simply where the tooling is built and tested.

| Area                   | macOS                                                        | Fedora                                                       |
| ---------------------- | ------------------------------------------------------------ | ------------------------------------------------------------ |
| Language               | Bash                                                         | Bash                                                         |
| Containers and test VM | [Apple container tool](https://github.com/apple/container/releases) (`container`) | [Podman](https://podman.io) containers, KVM and libvirt test VM |
| Package build          | inside a Fedora build container                              | inside a Fedora build container (Podman)                     |
| Tests                  | one suite in `src/test/`, run with `./test <name>`, see [Testing](../src/test/readme.md) | the same test suite as on macOS                              |
| Editor integration     | `.run/` IDE run configurations                               | `.run/` IDE run configurations                               |

Anyone is free to adapt the building and testing tooling to another platform, at their own cost, time, and effort. Such adaptations are welcome as contributions, but the project itself maintains only the macOS and Fedora paths.

## Development language

PodShift is written in Bash. This is a deliberate choice, and contributors must keep it that way.

**Why Bash**

- PodShift is orchestration glue, not computation: it directs the tools a server already has (`systemctl`, `podman`, `firewall-cmd`, `semanage`) so Bash is the natural, lowest-friction language for chaining those tools.
- Zero runtime and build overhead: Bash is already present on every supported Fedora system. The source is the deliverable: no compiler, no cross-compilation, no runtime to pin or ship.
- Native fit: RPM `%post`/`%posttrans`/`%preun`/`%postun` scriptlets are shell by design, and the `[PS-*]` step output and `logger` integration are shell idioms.
- Transparency: PodShift runs as root and configures security, so every script must be readable and auditable: an admin can read and patch it on the server, not trust a compiled black box.
- The audience (server administrators) works in Bash daily, so they can read, trust and fix the code themselves.

**Rules that keep Bash reliable**

Bash is powerful but permissive. To keep it safe, every script must follow these rules:

- Run with `set -euo pipefail`: an unhandled failure aborts loudly, never continues silently.
- Be non-fatal by default: each function handles its own failures - logs via `logger -t podshift`, reports `[WARN]`/`[SKIP]`, and returns, so the install never stops.

`set -euo pipefail` aborts on anything a function fails to handle; the non-fatal rule means each function is written to handle its own failures, so the install never aborts.
- Emit machine-parseable steps: `[PS-<phase>-<id>]` header + `[OK]`/`[WARN]`/`[SKIP]` status. What people see on screen follows [Output](#output).
- Keep complex logic in external, self-contained scripts rather than inline RPM scriptlets.
- Document every `.sh` file with bashdoc tags, so an admin can read what each file and function does. Only files that cannot carry tags due to their nature on the host are excepted. The tags, their meaning and the exceptions are defined in [Coding style](./coding.md#documentation).

**When to introduce another language**

Do not add another language without a workload-driven reason. A compiled language (Go/Rust) is justified only for a long-running daemon or performance-critical work; Python is justified only for heavy structured-data (JSON/YAML) processing. Neither matches PodShift's glue-oriented workload, so Bash remains the default until a real need appears.

## Behaviour

Application behaviour

### Output

Output is written for people first, and stays clean for logs and scripts:

- **Interactive** at a terminal: colors, icons and live progress, such as a spinner while a check runs.
- **Plain** everywhere else (a pipe, a log, `CI`, `TERM=dumb` or `NO_COLOR`): the same text with no color codes. `podshift --plain <command>` forces it.
- The mode is chosen once per run, so the output never mixes the two.
- Times are local and look like `2026-10-25 18:21:16`.
- A problem always comes with a hint or command that fixes it.

### Built-in Help

PodShift provides built-in help for the end user, so no external documentation is needed at runtime for common tasks.

```shell
podshift --help                # usage guide: the full list of commands
podshift --help <command>      # detailed help for a single command
```

`podshift --help` shows the usage guide with every available command grouped by area. Passing a command name shows help for that command only, for example `podshift --help containers`.

Help content is stored as Markdown files under `/opt/podshift/doc/help/`. The same file serves two purposes:

- at **development and review time** it is plain Markdown, easy to read, edit, and review in git or an editor;
- at **runtime** it is rendered in the terminal by `glow`.

Markdown files (`.md`) are rendered with `glow`, while plain-text notes (`.txt`) are printed with `cat`. An unknown command name produces an error message.

### Configuration

PodShift ships two kinds of configuration, distinguished by ownership:

- **App-managed** (do not edit): files under `/etc/`, `/usr/lib/` and `/opt/podshift/conf/`, e.g. `main.conf`, `rootless.conf`, systemd units, firewalld, SELinux, sysusers and tmpfiles definitions. These are owned by the application and are overwritten on upgrade.

- **User-editable**: these are not shipped directly. The application ships *templates* under `/opt/podshift/assets/tpl/` and copies each template to its final location during installation. The end user edits the final file. See [runtime templates](../src/server/opt/podshift/assets/tpl/readme.md) for the full list and their targets.

### Configuration variables

Configuration uses two variable prefixes with distinct purposes:

- **`PODSHIFT_*`**: PodShift's own configuration, covering paths, timeouts, and how to detect the network. Used internally by PodShift and never referenced in quadlet files.

- **`TSV_*`** (Target System Variables): properties of the deployment target, resolved at runtime. These are the variables that may be referenced in quadlet files and are substituted during installation:
  - `TSV_ENV`: the environment tag (e.g. `dev`, `staging`, `prd`);
  - `TSV_NW1` … `TSV_NW8`: the target's IPv4 addresses.

This distinction makes a variable's purpose obvious: `PODSHIFT_*` configures PodShift itself, while `TSV_*` describes the target system your containers run on.

### Dedicated podshift user

PodShift runs every container under one fixed, dedicated, unprivileged user:

- name `podshift`, UID `300`, home `/home/podshift`, shell `/bin/bash`;
- groups `podshift` (GID `300`) and `ssh_users` (GID `301`).

The identity (UID `300`, `/home/podshift`, `300@.host`, `/run/user/300`) is intentionally hardcoded in the scripts, systemd units, sysusers and tmpfiles definitions, and is not configurable.

A fixed UID keeps the fleet consistent: external monitors, agents and tooling can assume `300@.host`, `/home/podshift` and `/run/user/300` on every machine, so nothing needs per-host configuration and nothing fails because a tool guessed the wrong path or UID. Per-machine or random user IDs might look more "individual" per server, but a fleet (for example, six servers) would then be six different configurations, which makes management much harder. One predictable identity keeps management simple and reliable.

### Altering runtime configuration

Runtime configuration is meant to be changed through the built-in commands. PodShift does not prevent editing the configuration files by hand, but the commands validate each change and keep every server consistent, so manual edits are unsupported and may be lost or rejected.

Responsibility is split by ownership:

- **root** owns the system settings: the environment tag and how the network is detected.
- **the podshift user** owns the values its containers need: custom `TSV_*` variables and secrets.

Neither side can change the other's settings. Reserved keys stay reserved, and secrets are never stored in configuration files.

The files and commands are described in [Usage](./usage.md).

## Limitations

- `podshift.spec` - Keep it as simple as possible. If possible use external bash scripts for complex tasks. Only crucial tasks should be included.
