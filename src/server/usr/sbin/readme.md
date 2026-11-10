# /usr/sbin

PodShift's administrator (root-realm) shortcuts.

Each command here is an extensionless symlink generated at build time:

```
/usr/sbin/<name> -> /opt/podshift/shortcuts/root/<name>.sh
```

The `.sh` source under `/opt/podshift/shortcuts/root/` is the single source of truth. The symlinks are build artifacts and are never edited by hand.

## Realm

Root-realm commands require administrator privileges:

- Each script guards itself with `require-admin` (root or passwordless sudo).
- The dispatcher runs them directly as root via `podshift <name>`.
- A non-administrator is rejected with `Unauthorised. Root privileges required.`

## Adding a shortcut

1. Add `shortcuts/root/<name>.sh` to the source tree.
2. Rebuild. The deployment step creates `/usr/sbin/<name>` automatically.
