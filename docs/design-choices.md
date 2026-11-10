# Design Choices

PodShift is a lightweight container orchestration enabler for small servers. It installs on Fedora Server and turns any machine, from bare metal to a cloud VM, into a server that sets itself up, keeps itself secure, and updates your apps automatically, with the same configuration from a developer's computer all the way to production. For the full picture, see the [readme](../readme.md).

Every IT solution is opinionated, and PodShift is too. There's rarely one right or wrong answer. What matters a lot to one team hardly matters to another, and the right choice depends on many things: your people, your budget, your apps and your plans.

Many tech stacks have no real reasoning behind them. They grew out of habits, past projects and choices made along the way. This page does the opposite: it shares the thinking behind PodShift's design, in plain words. You don't have to agree with it. It's here so you can see why things are the way they are and decide for yourself.

What each part does is in the code and the built-in help. This page covers only the why.

What drives these choices:

- **Proven tools over hype.** New technology often promises more than it delivers. In real life, the latest trend can turn into a heavy weight that drags you down, and you end up patching around problems nobody mentioned at the start. PodShift picks tools that have already proven themselves in daily use.
- **Free software.** Every part is free and open source.
- **Easy to try anywhere.** Install and test it on a cheap desktop, then run it on any cloud host or your own server.
- **Works together out of the box.** All the parts are made to fit, with no complex patching.
- **Easy to maintain.** Fewer moving parts, less to look after.
- **Lower maintenance costs.** That includes the cost of expertise: you don't need a team of specialists to keep it running.
- **Low, predictable running costs.** A fixed-price cloud server, your own hardware or a rented rack. You know what you'll pay.
- **No vendor lock-in.** Changing cloud providers often means rebuilding your entire infrastructure, and parts of your apps too, because they were built around the old provider's services. With PodShift, you move from any cloud to your own servers in a data centre, or from one hosting provider to another, and your apps come with you unchanged.

## The Foundation

PodShift doesn't invent its own platform. It's a thin layer that sets up and connects tools Fedora already ships.

- **No hidden engine.** There's no extra background service and no black box. Podman runs your apps and systemd starts them, with a few small scripts on top.
- **Nothing to get stuck with.** Your apps run on standard tools and open formats. If you remove PodShift, your apps, data and settings stay where they are and keep running.
- **Decades of proven work.** Instead of writing its own security, startup or monitoring from scratch, PodShift relies on tools that have run countless servers for years, such as SELinux, firewalld and systemd.

In short, PodShift doesn't reinvent the wheel. It brings together what Linux already does well, so a single ordinary server gets a solid, well-tested setup.

### Bash instead of a compiled binary

**In plain words:** PodShift is plain Bash scripts, the same commands a server admin already types every day (`systemctl`, `podman`, `firewall-cmd`, `dnf`), just bundled so they can be repeated and shared. The server's parts are already command-line tools, and Bash is the glue that drives them. What you install is text you can read and fix yourself.

**What you gain:**

- You can read and audit every line, because a script is its own source.
- You can patch a bug on the server with an editor; no recompile, no vendor ticket.
- Nothing to install; Bash is already on every Linux box, no interpreter or packages.
- No lock-in; the scripts and the skill stay useful even without PodShift.
- Easiest to adapt: porting PodShift to another platform means swapping a few command calls, not recompiling.

**When it's not enough:** Heavy computation, complex data structures, or a large codebase would favour a real language.

**For the technical reader:** No types, no data structures, fiddly quoting, but the work is calling a CLI, checking its exit code, and editing a text file, which is Bash's strength. A compiled binary cannot be read or patched on the server; Python drags in an interpreter and package management. Porting means changing the distro-specific calls (dnf to apt, firewalld to ufw), not rebuilding.

**Read more:**

- [Shell Style Guide (Google, 2024)](https://google.github.io/styleguide/shellguide.html)
- [Bash pitfalls (Greycat's wiki)](https://mywiki.wooledge.org/BashPitfalls)

### Podman and Quadlet instead of Compose or Kubernetes

**In plain words:** Everything your apps need is described in small recipe files: the app itself, the private network its parts use to talk to each other, the storage where its data is kept, and more. The server's own built-in manager, the same one that already starts everything else on the server, reads these recipes and keeps it all running. There is no extra control system to install, learn or pay for.

**What you gain:**

- An app and everything it relies on, its network and its storage, are set up together and start in the right order.
- Your apps start by themselves when the server boots, and can be set to come back by themselves if they crash.
- Updates arrive on their own, and a bad update can be undone automatically.
- Each recipe is a short text file you can read, keep a history of, and copy to another server.
- Nothing extra runs in the background, so there is less to break, patch and pay for.
- Your apps run without full control of the server, so a broken or attacked app has a much harder time taking over the whole machine.
- The same app packages used everywhere else work here too, and the commands are the same ones many developers already know from Docker.
- Several parts of one app can be grouped and run together, sharing their network, like a small team in one room.
- It is free, open source and comes with Fedora, so you are not tied to one company.

**When it's not enough:** Each server looks after itself. You manage your apps from one place, your code and the place where you publish new app versions, but if a server goes down, its apps don't move to another server by themselves. If an app must keep running even when its server goes down, you need a setup that moves it to another server automatically, which PodShift does not do.

**For the technical reader:** Podman runs the containers without a background daemon and without root, uses standard OCI images, has a Docker-compatible command line, and groups containers into pods. Quadlet turns `.container`, `.network`, `.volume`, `.pod`, `.kube`, `.image` and `.build` files into systemd services, so systemd handles start order, restarts (with `Restart=` in the file) and logs in the journal. `podman auto-update` pulls new images and rolls back when the updated service is broken. Delivery is central (git plus registry, pull-based auto-update), but there is no cluster scheduler, so no automatic cross-node failover as in Kubernetes. This replaces Docker Compose, and at this size Kubernetes is not needed; `.kube` files can still run Kubernetes YAML.

Why Podman and Quadlet (Red Hat and Fedora):

- [Make systemd better for Podman with Quadlet (Red Hat, 2023)](https://www.redhat.com/en/blog/quadlet-podman)
- [How to use auto-updates and rollbacks in Podman (Red Hat, 2021)](https://www.redhat.com/en/blog/podman-auto-updates-rollbacks)
- [Podman at the edge: Keeping services alive with custom healthcheck actions (Red Hat, 2022)](https://www.redhat.com/en/blog/podman-edge-healthcheck)
- [Deploying a multi-container application using Podman and Quadlet (Red Hat, 2023)](https://www.redhat.com/en/blog/multi-container-application-podman-quadlet)
- [RHEL 9.2 edge image configuration (Red Hat, 2023)](https://www.redhat.com/en/blog/rhel-92-edge-image-configuration)
- [From Zero to Web Server: Building with Image mode for Fedora Linux & Caddy (Fedora Magazine, 2025)](https://fedoramagazine.org/from-zero-to-web-server-building-with-image-mode-for-fedora-linux-caddy/)

Used in practice:

- [It's arrived: Commoditization for industrial process control (Red Hat, 2023)](https://www.redhat.com/en/blog/its-arrived-commoditization-for-industrial-process-control)
- [Beyond Kubernetes: Podman + Quadlet for Lean, Reliable Containers (OSS Group, 2025)](https://www.oss-group.co.nz/blog/podman-quadlet)
- [Tag-Driven Deployments: How MastoSum Ships Itself with Forgejo Actions and Rootless Podman (Larvitz Blog, 2026)](https://blog.hofstede.it/tag-driven-deployments-how-mastosum-ships-itself-with-forgejo-actions-and-rootless-podman/)
- [Evaluate Podman + Quadlet as the container runtime for the immutable appliance (vs Docker Compose) (pithead, 2026)](https://github.com/p2pool-starter-stack/pithead/issues/78)

Independent view:

- [Docker and the OCI container ecosystem (LWN.net, 2022)](https://lwn.net/Articles/902049/)

### Fedora Server

**In plain words:** PodShift runs on Fedora Server, the small server edition of Fedora that has no desktop and is managed over the network. You can run Fedora on your work computer too, so what works on your desk works on the server. Fedora is also the home of the tools PodShift is built on. Podman, Quadlet and Cockpit (the server's web control panel) come from Red Hat, and their new versions are tested and shipped in Fedora first. So PodShift always sits on the newest versions of its own building blocks, made to work together.

**What you gain:**
- The tools' home. New Podman versions are tested by the Podman and Fedora teams together, and each new major version arrives in Fedora first.
- Quadlet with all its features. Quadlet needs a recent Podman, and some popular server systems ship an older one that lacks Quadlet or its newer features.
- The safety layer Podman is designed for. Fedora has SELinux switched on by default, which keeps every container apart from the server and from other containers. Many other systems use AppArmor instead, which can't keep containers apart from each other in the same way.
- A server that's ready on first boot. Fedora Server is lean, and its web control panel, Cockpit, is installed and working from the start.
- The same system on your desk and on the server, so fewer surprises between testing and production.
- Little upkeep. One upgrade a year is enough, because you can skip every other release.
- Free, backed by Red Hat, and the base for Red Hat's own business system, RHEL.

**When it's not enough:**
- If you need one version supported for many years, or a paid support contract, you need RHEL. PodShift doesn't target it.
- If you want a server whose whole system is a fixed image that updates in one piece, look at Fedora CoreOS or image-based (bootc) Fedora. PodShift doesn't target these.

**For the technical reader:** Quadlet arrived in Podman 4.4 (February 2023), and `Notify=healthy` (start in order of health) in Podman 5.0. As of October 2026, Fedora 43 and 44 ship Podman 5.8, Debian 12 ships 4.3 (no Quadlet), Ubuntu 24.04 LTS ships 4.9 (Quadlet without Podman 5 features), Debian 13 ships 5.4 and Ubuntu 26.04 ships 5.7. Podman 6 is planned for Fedora 45. Container confinement is SELinux-based (`container-selinux`, the `container_t` type, MCS labels separating containers, `:Z` relabelling). AppArmor, the default on Debian and Ubuntu, has no MCS. Fedora releases about every 6 months, each supported for about 13 months, so upgrading once a year from N to N+2 is a supported path.

**Read more:**

Fedora is where Podman is built and tested:

- [Changes/Podman6 (Fedora Project)](https://fedoraproject.org/wiki/Changes/Podman6)
- [Podman 5.0 Unveiled (Red Hat, 2024)](https://www.redhat.com/en/blog/podman-50-unveiled)
- [Podman Test Days: Try the New Backend & Parallel Pulls (Fedora Magazine, 2026)](https://fedoramagazine.org/podman-test-days-try-the-new-backend-parallel-pulls/)
- [Podman Test Week: Help test the Rust-based conmon v3 (Fedora Magazine, 2026)](https://fedoramagazine.org/podman-test-week-help-test-the-rust-based-conmon-v3/)

SELinux keeps containers apart:

- [AppArmor vs SELinux for isolation (Red Hat, 2020)](https://www.redhat.com/en/blog/apparmor-selinux-isolation)
- [Why you should be using Multi-Category Security for your Linux containers (Red Hat, 2020)](https://www.redhat.com/en/blog/why-you-should-be-using-multi-category-security-your-linux-containers)

Fedora Server and Cockpit:

- [Fedora Server (Fedora Project)](https://fedoraproject.org/server/)
- [Fedora Linux editions part 1: Official Editions (Fedora Magazine, 2022)](https://fedoramagazine.org/fedora-linux-editions-part-1-official-editions/)

Used in practice:

- [Low-effort self-hosting using Podman (Jasmin's blog, 2025)](https://jasminchen.dev/notes/2025/low-effort-self-hosting-using-podman/)
- [Installing Navidrome on Fedora Linux using Podman (Fedora Magazine, 2026)](https://fedoramagazine.org/installing-navidrome-on-fedora-linux-using-podman/)

The fixed-image alternative:

- [Fedora CoreOS (Fedora Project)](https://fedoraproject.org/coreos/)
- [Making containers bootable for fun and profit (LWN.net, 2024)](https://lwn.net/Articles/979182/)

## Rootless Podman Server

One install turns a Fedora server into a home for your apps. They run under their own ordinary account, start by themselves, stay up to date by themselves, and your data stays safe even if you remove PodShift. These are defaults for an easy start, and you can change any of them.

### A dedicated podshift user

**In plain words:** All apps live under one ordinary account called `podshift`. It's kept apart from the people who log in to look after the server.

**What you gain:**
- Everything that runs has one clear owner, so it's easy to see, back up and clean up.
- Your own login stays out of the apps, and the apps stay out of your login.
- It's the account behind "Containers never run as root" in Built-in Hardening.

**When it's not enough:** If different teams need their apps kept strictly apart from each other, you'd want more than one app account.

**For the technical reader:** Created by `sysusers.d` (`podshift`, UID and GID 300, home `/home/podshift`), with its own subuid and subgid range for rootless Podman.

**Read more:**

- [Rootless Podman containers under system accounts, managed and enabled at boot with systemd (Christopher Smart, 2021)](https://blog.christophersmart.com/2021/02/20/rootless-podman-containers-under-system-accounts-managed-and-enabled-at-boot-with-systemd/)
- [Best practice: run rootless containers under a separate user? (Podman discussion)](https://github.com/containers/podman/discussions/28320)
- [NIST SP 800-123, Guide to General Server Security](https://csrc.nist.gov/pubs/sp/800/123/final)

### Services that start at boot without a login

**In plain words:** Apps start when the server starts and keep running when nobody is logged in.

**What you gain:**
- After a reboot or a power cut, everything comes back by itself.
- Nobody has to log in or leave a session open to keep apps up.

**When it's not enough:** If an app should run only while someone is logged in, you can turn this off for the `podshift` user.

**For the technical reader:** systemd user lingering for `podshift` (`/var/lib/systemd/linger/podshift`), with user units such as `podman.socket` and `podman-auto-update.timer` enabled by a user preset.

**Read more:**

- [Configure a container to start automatically as a systemd service (Red Hat, 2023)](https://www.redhat.com/en/blog/container-systemd-persist-reboot)
- [Why can't I use sudo with rootless Podman? (Dan Walsh, Red Hat)](https://www.redhat.com/en/blog/sudo-rootless-podman)

### Automatic container updates

**In plain words:** The server regularly checks for a newer version of each app that's set to update itself. If there is one, it updates the app, and if the new version turns out broken, it can go back to the old one.

**What you gain:**
- Publish a new version of your app once, and every server picks it up by itself.
- If an update goes wrong, the old version can come back on its own, so the app keeps running.
- No manual deploys, and no central system that needs access to your servers.

**When it's not enough:** If updates must go out at a set time or in a set order across servers, you can check less often, switch automatic updates off, or start updates yourself, for example from your own build system.

**For the technical reader:** `podman-auto-update.timer` for the `podshift` user, with an override set to `OnCalendar=*:0/15`, `RandomizedDelaySec=2min` and `Persistent=true` (Podman's own default is once a day). Apps opt in with `AutoUpdate=registry` in their Quadlet.

**Read more:**

- [How to use auto-updates and rollbacks in Podman (Red Hat, 2021)](https://www.redhat.com/en/blog/podman-auto-updates-rollbacks)
- [Auto-updating Podman containers with systemd (Fedora Magazine)](https://fedoramagazine.org/auto-updating-podman-containers-with-systemd/)
- [Podman on the Edge (Valentin Rothberg, Red Hat, DevConf.CZ 2022)](https://static.sched.com/hosted_files/devconfcz2022/34/Podman%20on%20the%20Edge.pdf)
- [OpenGitOps Principles (CNCF)](https://opengitops.dev/)

### Uninstall keeps your data

**In plain words:** Removing PodShift stops the automatic updates but leaves your apps, their data and the `podshift` user in place. It also lists everything that's left, on screen and in the system log.

**What you gain:**
- Removing or reinstalling PodShift can never wipe your data by accident.
- You know exactly what's still on the server.

**When it's not enough:** To wipe the server completely, you delete what's left yourself, using that list.

**For the technical reader:** On final removal, `preun` removes the auto-update setup and `postun` logs what's left to the journal under the tag `podshift-install`: the user and home, `/var/lib/podshift/runtime.conf`, container storage, quadlets, subuid and subgid entries, enabled user services and lingering. Upgrades leave everything as is.

**Read more:**

- [Fedora Packaging Guidelines (Fedora Project)](https://docs.fedoraproject.org/en-US/packaging-guidelines/)
- [Debian Policy Manual, configuration files (Debian)](https://www.debian.org/doc/debian-policy/ch-files.html)

## Built-in Hardening

A fresh server is safe from the first boot, with no long checklist. Each protection below is a separate lock, so if one fails, the others still hold. They're sensible defaults, and you can change any of them.

### Containers never run as root

**In plain words:** Root is the server's master key. PodShift gives every app an ordinary, limited account instead, so an app that breaks or gets attacked never holds the master key. This is the first lock.

**What you gain:**
- An app that gets broken into has a hard time touching anything else.
- An app can't change the system by accident.
- Nothing to set up. This is simply how every app runs from day one.

**When it's not enough:** A few tools really do need deep access to the machine itself. Those don't belong in a normal app container.

**For the technical reader:** Rootless Podman under the dedicated `podshift` user. A container's root (UID 0) maps to the unprivileged `podshift` UID through user namespaces, and its other UIDs map into the subuid range.

**Read more:**

- [CVE-2026-31431: Copy Fail vs. rootless containers (GNOME infrastructure, 2026)](https://www.dragonsreach.it/2026/05/04/cve-2026-31431-copy-fail-rootless-containers/)
- [Podman rootless containers and the Copy Fail exploit (2026)](https://garrido.io/notes/podman-rootless-containers-copy-fail/)
- [Rootless Podman makes sense (Red Hat, 2019)](https://www.redhat.com/en/blog/rootless-podman-makes-sense)
- [How does rootless Podman work? (Dan Walsh, Opensource.com, 2019)](https://opensource.com/article/19/2/how-does-rootless-podman-work)
- [NIST SP 800-190, Application Container Security Guide](https://csrc.nist.gov/pubs/sp/800/190/final)

### SELinux stays on

**In plain words:** SELinux is the second lock, behind the first. Even if an app gets out of its container, the server still decides what it may touch, and the answer is: only its own files.

**What you gain:**
- It has stopped real attacks where an app broke out of its container.
- Podman labels app files for you, so it stays out of your way.
- It's part of Fedora and switched on by default.

**When it's not enough:** If an app needs to share files with the server, those files must be labelled for it. Podman does that when you connect the folder to the app.

**For the technical reader:** SELinux in enforcing mode, checked by the health check. Containers run with the `container_t` type, and mounted volumes are relabelled with `:Z` or `:z`.

**Read more:**

- [RHSB-2024-001 Leaky Vessels, runc (Red Hat Product Security, 2024)](https://access.redhat.com/security/vulnerabilities/RHSB-2024-001)
- [AppArmor vs SELinux for isolation (Red Hat, 2020)](https://www.redhat.com/en/blog/apparmor-selinux-isolation)
- [Latest container exploit (runc) can be blocked by SELinux (Dan Walsh, Red Hat, 2019)](https://www.redhat.com/en/blog/latest-container-exploit-runc-can-be-blocked-selinux)
- [The SELinux Coloring Book (Dan Walsh, Opensource.com, 2013)](https://opensource.com/business/13/11/selinux-policy-guide)
- [Stop Disabling SELinux (Major Hayden)](https://stopdisablingselinux.com/)

### A firewall and brute-force protection

**In plain words:** Only the doors the server needs are open: the web, a proxy, SSH and Cockpit (the web control panel). Anyone who keeps failing to log in is locked out for a while. SSH accepts only a key, never a password.

**What you gain:**
- Everything you didn't open stays out of reach from outside.
- Password guessing slows down, because repeat offenders get blocked. The key-only login is what really stops it.

**When it's not enough:** If an app needs another public port, open it in the firewall.

**For the technical reader:** firewalld with a `podshift` service opening TCP 80 (HTTP), 81 (proxy), 443 (HTTPS), 1022 (SSH) and 9090 (Cockpit). fail2ban runs an `sshd` jail. `PasswordAuthentication no` in `/etc/ssh/sshd_config.d/50-podshift-auth.conf`.

**Read more:**

- [NIST SP 800-41 Rev. 1, Guidelines on Firewalls and Firewall Policy](https://csrc.nist.gov/pubs/sp/800/41/r1/final)
- [Securing IoT Devices using Geographic and Continuous Login Blocking: A Honeypot Study (KTH, 2020)](https://www.scitepress.org/PublishedPapers/2020/89547/89547.pdf)

### Web ports for apps without root

**In plain words:** In a typical app, only the front door, the web server, faces the internet, on the familiar ports 80 and 443. The database and everything else stay on a private network that only the app's own containers can reach. PodShift lets that front door use the normal ports without admin rights.

**What you gain:**
- Clean web addresses, with no `:8080` at the end.
- Nothing runs as root, not even the public front door.
- The internal parts are never open to the internet.

**When it's not enough:** If an app needs a port below 80, change the setting. On a server shared by many user accounts, this setting would let any of them take the web ports. A PodShift server is meant for your own apps, not for shared logins, so that risk is small.

**For the technical reader:** `net.ipv4.ip_unprivileged_port_start=80` in `/etc/sysctl.d/99-unprivileged-ports.conf`, so rootless containers can bind port 80 and up.

**Read more:**

- [Containers and Low Ports (Rory McCune, 2021)](https://raesene.github.io/blog/2021/07/03/containers-and-low-ports/)
- [Dear Linux, Privileged Ports Must Die (Aral Balkan, 2022)](https://ar.al/2022/08/30/dear-linux-privileged-ports-must-die/)

### Credentials in Podman secrets

**In plain words:** Passwords and keys left in plain text across config files are still one of the most common ways servers get broken into. Podman keeps them in one protected place and gives each secret only to the app that needs it. No separate, complicated password manager needed.

**What you gain:**
- No passwords in config files, git or backups.
- Each app only sees its own secrets.
- Nothing extra to install or look after.

**When it's not enough:** When secrets must change across many servers, your own automation can write and update them in Podman, or you can connect a credentials manager. PodShift blocks neither. Most teams don't run one anyway, and a single store that holds every secret is a big target in itself.

**For the technical reader:** `podshift secret` creates, lists, replaces and removes Podman secrets for the `podshift` user, and Quadlet files use them with `Secret=`. The default `file` driver keeps each secret in a read-protected file, not encrypted. The `pass` driver keeps them GPG-encrypted, and the `shell` driver hands storage to your own scripts.

**Read more:**

- [The State of Secrets Sprawl 2026 (GitGuardian)](https://blog.gitguardian.com/the-state-of-secrets-sprawl-2026/)
- [OWASP Secrets Management Cheat Sheet](https://cheatsheetseries.owasp.org/cheatsheets/Secrets_Management_Cheat_Sheet.html)
- [Using sensitive data in containers (Red Hat, 2021)](https://www.redhat.com/en/blog/sensitive-data-containers)

## Misc Tweaks

Small changes that make the server easier to run. They aren't protections, and you can change any of them.

### SSH on port 22 and 1022

**In plain words:** Most attacks on servers aren't people. They're bots that try the standard login door, port 22, on every server they can find. PodShift opens a second door, 1022, next to the standard one. Once you have tested the new door, one command closes the old one and the lazy bots never knock.

**What you gain:**
- Far fewer login attempts and much quieter logs, once port 22 is closed.
- No lockout risk. A fresh install starts with port 22 open on purpose, and you close it only after you have tested port 1022.

**When it's not enough:** This is less noise in the logs, not security. Someone who scans every port will still find 1022. The key-only login and the lockout in Built-in Hardening are what stop a determined attacker.

**For the technical reader:** sshd always listens on 22 and 1022, from the drop-in `/etc/ssh/sshd_config.d/10-podshift-ssh-ports.conf`. `/etc/ssh/sshd_config` is not edited. The firewalld `ssh` service (port 22) is the switch: `sudo podshift ssh port 1022` removes it from the zone of the default-route interface, `sudo podshift ssh port 22` adds it back. The state lives in the firewall's own zone file, so an upgrade never changes it. If sshd already uses a custom port, PodShift leaves SSH alone. If port 1022 is not open in the firewall yet (no `podshift` service, for example on a desktop install), the command opens only `1022/tcp` first. The command checks with `ss -tln` that 1022 is listening, but it sees only this machine, not a firewall of your provider. Test `ssh -p 1022` from another terminal first.

**Read more:**

- [Where The Wild Things Are: Brute-Force SSH Attacks In The Wild And How To Stop Them (USENIX NSDI, 2024)](https://www.usenix.org/conference/nsdi24/presentation/singh-sachin)
- [SSH on Port 22 vs some random port (2025)](https://defilippomattia.com/posts/ssh-port-22-vs-some-random-port/)
- [Rise in XorDdos (Microsoft Security, 2022)](https://www.microsoft.com/en-us/security/blog/2022/05/19/rise-in-xorddos-a-deeper-look-at-the-stealthy-ddos-malware-targeting-linux-devices/)
- [Who's Knocking on Your Door? (Censys)](https://censys.com/blog/whos-knocking-on-your-door-exposed-services-risks)

## Drop-In Quadlets

Installing an app should be as easy as copying a file. PodShift adds a drop folder on top of Podman: you put an app's configuration files there, and PodShift takes care of the rest. It's an extra option, not a replacement, so `podman quadlet install` works as usual.

### A drop folder for easy installs

**In plain words:** Drop an app's configuration files into one folder on the server, in whatever way you like: copy them by hand, sync them from git, or let your build or automation tools do it. PodShift picks them up and installs the app. If you prefer to do it by hand, Podman works as usual.

**What you gain:**
- Installing an app is as easy as copying a file.
- Nothing new to learn. Any tool that can copy a file can deploy.
- No extra deploy service, program or access key to set up and keep secure. Fewer moving parts means less to break.

**When it's not enough:** If you want full control over each step, install with Podman directly. The folder is only a shortcut.

**For the technical reader:** A systemd path unit watches `/home/podshift/drop`. Processing starts after a short quiet period, and files changed in the last 2 seconds are left to settle, so half-copied files aren't picked up. A timer also sweeps the folder every 5 minutes. Quadlet files (`.container`, `.volume`, `.network`, `.image`, `.kube`, `.pod`, `.build`) and `.zip` bundles up to 50 KB are accepted. Anything else goes to `/home/podshift/trash`, and every step is logged. These are defaults in `/opt/podshift/conf/main.conf`.

**Read more:**

- [Choose Boring Technology (Dan McKinley, 2015)](https://mcfunley.com/choose-boring-technology)
- [FetchIt: Life-cycling and configuration of containers using GitOps and Podman (Red Hat Emerging Technologies, 2022)](https://next.redhat.com/2022/08/09/fetchit-life-cycling-and-configuration-of-containers-using-gitops-and-podman/)
- [quadit, GitOps for Quadlets with a pure pull model](https://github.com/ubiquitous-factory/quadit)
- [Attack Surface Analysis Cheat Sheet (OWASP)](https://cheatsheetseries.owasp.org/cheatsheets/Attack_Surface_Analysis_Cheat_Sheet.html)

### Every file is checked before install

**In plain words:** Getting an app's configuration right is up to the person who writes it and the admin who checks it. PodShift adds a quick check on top: before a file reaches the installer, it looks for likely mistakes and sets a broken file aside, so you can see what's wrong.

**What you gain:**
- Broken files never reach the installer, so there are no failed installs, half-started apps or noisy logs.
- You can spot the mistake right away.

**When it's not enough:** The check catches common errors, not every bad setting. A file can pass and still be wrong for your app, so testing and review stay with you.

**For the technical reader:** Accepted files wait in `/home/podshift/.quadlets/validation-queue`, and rejected ones are kept in `/home/podshift/.quadlets/rejected`.

**Read more:**

- [Early Detection of Configuration Errors to Reduce Failure Damage (USENIX OSDI, 2016)](https://www.usenix.org/conference/osdi16/technical-sessions/presentation/xu)
- [Configuration Specifics (Google SRE Workbook)](https://sre.google/workbook/configuration-specifics/)
- [Fail Fast (Jim Shore, IEEE Software, 2004)](https://martinfowler.com/ieeeSoftware/failFast.pdf)
- [Quadlet for adhoc units (Podman issue 18778, 2023)](https://github.com/podman-container-tools/podman/issues/18778)

### One configuration, different values per server

**In plain words:** This is the most beautiful part. You write an app's configuration files once and use the same files on every server. The files hold no passwords, IP addresses or other details tied to one server. Each server fills those in from its own local settings when the app is installed.

**What you gain:**
- The same configuration everywhere, so servers never drift apart.
- Files you can share or keep in git without leaking secrets. Credentials stay on the server in Podman secrets (see Built-in Hardening).
- A new server needs only its own settings and the same files.

**When it's not enough:** If two servers need a different setup, not just different values, they need their own files.

**For the technical reader:** Quadlet files use `${TSV_*}` variables, filled with the server's values before install. Built-in values include `TSV_ENV` (the environment tag, such as `dev` or `prd`) and `TSV_NW1` to `TSV_NW8` (the server's external addresses). The `podshift` user can add its own `TSV_*` keys with `podshift config`, stored in `/home/podshift/.config/podshift/tsv.conf`.

**Read more:**

- [The Twelve-Factor App: Config](https://12factor.net/config)
- [SnowflakeServer (Martin Fowler, 2012)](https://martinfowler.com/bliki/SnowflakeServer.html)
- [ConfigurationSynchronization (Martin Fowler, 2012)](https://martinfowler.com/bliki/ConfigurationSynchronization.html)
- [Exploring the new Podman secret command (Red Hat, 2021)](https://www.redhat.com/en/blog/new-podman-secrets-command)
