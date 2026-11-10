# /usr/bin

PodShift's dispatcher and user (rootless) shortcuts.

Each command here is an extensionless symlink generated at build time:

```
/usr/bin/podshift  -> /opt/podshift/cli/podshift.sh
/usr/bin/<name>    -> /opt/podshift/shortcuts/rootless/<name>.sh
```

The `.sh` source under `/opt/podshift/cli/` or `/opt/podshift/shortcuts/rootless/` is the single source of truth. The symlinks are build artefacts and are never edited by hand.

## Dispatcher

`podshift` routes a subcommand to a module first, then to a shortcut:

- A module: `cli/modules/<name>/main.sh`, resolved by long name or `aliases.conf`.
- A shortcut: rootless (`/usr/bin`) or root (`/usr/sbin`), run in its realm.

## Realm

The rootless shortcuts are for the podshift user:

- Each script guards itself with `require-podshift` (UID 300).
- Each script loads the rootless environment with `load-rootless-conf` (XDG_RUNTIME_DIR).
- Anyone else is rejected with `Unauthorised. Must be the podshift user.`

## Adding a shortcut

1. Add `shortcuts/rootless/<name>.sh` to the source tree.
2. Rebuild. The deployment step creates `/usr/bin/<name>` automatically.
