# selinux
Switches SELinux to enforcing when it is in permissive mode.

PodShift relies on SELinux to keep containers apart from the server and from each other. Fedora has it enforcing by default. Some cloud images start in permissive mode.

If SELinux is already enforcing, the command changes nothing, except that it also sets `SELINUX=enforcing` in `/etc/selinux/config` when that file still has another value.

If SELinux is disabled, the command changes nothing and prints the steps to turn it back on. That path needs a full file relabel and a reboot, which can take a while.

## Usage `(root)`

```
sudo podshift selinux enforce [--force]
```

It asks before it changes anything. `--force` skips the question.

## Examples `(root)`

```bash
sudo podshift selinux enforce
```
