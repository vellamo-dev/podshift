# Templates

Static templates shipped with PodShift. Each is copied to its final location at install time, only when the target does not yet exist, so user edits are never overwritten.

## Template → target

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
