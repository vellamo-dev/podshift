# ssh
Turns the firewall's `ssh` service (port 22) on or off. The sshd ports never change: sshd always listens on port 22 and port 1022.

Port 1022 only brings less noise in the logs, because bots try port 22. It is not a protection. The protection is the key-only login and fail2ban.

A fresh install starts with port 22 open on purpose, so you cannot lock yourself out. The state is whether the `ssh` service is on in the firewall zone of the default-route interface. It is kept in the firewall's own zone file, so an upgrade never changes it.

If sshd listens on a custom port, PodShift leaves SSH alone and this command changes nothing.

## Usage:

```
podshift ssh port 1022 [--force]    turn the ssh service off: only port 1022 stays open
podshift ssh port 22                turn the ssh service on again
```

Before it turns port 22 off, the command checks with `ss -tln` that sshd listens on 1022, and opens port 1022 in the firewall if it is not open yet. `--force` skips the listening check. The check sees only this machine, not a firewall of your provider. Test `ssh -p 1022` from another terminal first. A session that is already open on port 22 stays open.

## Examples:

```shell
sudo podshift ssh port 1022
sudo podshift ssh port 22
```
