# Security

## Security comes first

Security is a primary concern for PodShift, and it is built in from the start rather than added later. Access starts closed: every interaction begins in an untrusted state, and every access is an exception (zero trust).

## The podshift realm

Containers and their services run under the unprivileged `podshift` user, never as root. The user's own settings and secrets stay with that user, and root keeps the system settings. See [Dedicated podshift user](docs/scope.md#dedicated-podshift-user), [Altering runtime configuration](docs/scope.md#altering-runtime-configuration) and [Built-in Hardening](docs/design-choices.md#built-in-hardening).

## Fewer moving parts

Every extra part is something that can be attacked or break. PodShift adds no extra daemons, open ports or keys of its own. See [Principles](docs/scope.md#principles).

## Don't build what already exists

PodShift uses SELinux, firewalld, fail2ban, OpenSSH, systemd and rootless Podman, instead of writing its own security. See [The Stack](docs/scope.md#the-stack) and [The Foundation](docs/design-choices.md#the-foundation).

## In scope and out of scope

In scope: PodShift's own scripts, the `podshift` command, the RPM, and the Cockpit API handler.

Out of scope: bugs in Fedora, Podman, Cockpit and the other platform tools (please report those upstream), the containers people run, their own Quadlets and settings, forks, and older versions.

## Who is responsible

PodShift is provided as is, as the [licence](LICENSE) states. Whoever owns and runs the system is responsible for its security and for anything that happens on it. PodShift's developers are not responsible for security breaches on systems where it is used.

## Reporting a problem

Please report a security problem privately via [vellamo.fyi](https://vellamo.fyi), not in a public issue. Only the latest version gets fixes. For other support questions, see [support.md](docs/support.md).
