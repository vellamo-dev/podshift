# Runtime Data

This directory holds the files PodShift deploys to the target system. Everything under `tpl/` is a template copied to its final location during installation: configuration files, a systemd timer override, and the podshift user's shell profile files. The end user edits the copy, never the template stored here.

## Templates

Templates: `./tpl/`

| Template | Runtime target (user-editable) |
| --- | --- |
| `runtime.conf` | `/var/lib/podshift/runtime.conf` |
| `00-global.local` | `/etc/fail2ban/jail.d/00-global.local` |
| `sshd.local` | `/etc/fail2ban/jail.d/sshd.local` |
| `20-podshift-access.conf` | `/etc/ssh/sshd_config.d/20-podshift-access.conf` |
| `50-podshift-auth.conf` | `/etc/ssh/sshd_config.d/50-podshift-auth.conf` |
| `podman-auto-update.timer.d/override.conf` | `/home/podshift/.config/systemd/user/podman-auto-update.timer.d/override.conf` |
| `tpl.bashrc` | `/home/podshift/.bashrc` |
| `tpl.bash_profile` | `/home/podshift/.bash_profile` |

## Deployment behaviour

Templates are copied only when their target does not yet exist, so an upgrade never overwrites user edits. New default settings added to a template in a later release are therefore not merged into an existing target.

Shell profiles follow the same rule: `.bashrc` is cloned from the system skeleton when missing and the PodShift config line is appended once; `.bash_profile` is created when missing, otherwise `source ~/.bashrc` is appended only if absent.

## runtime.conf

The PodShift runtime configuration is written to `/var/lib/podshift/runtime.conf`:

- `TSV_ENV` - the environment tag (e.g. `dev`, `staging`, `prd`).
- `PODSHIFT_NW_INITIALIZER` - how the target's network addresses are discovered.
- `PODSHIFT_NW_DEVICE` - the network device to read.
