# config
Lists, reads, sets and removes PodShift configuration keys.

There are two config files. Each is created from its template the first time a key is set in it:

- System keys are in `/var/lib/podshift/runtime.conf`. Only root may set them: `PODSHIFT_NW_INITIALIZER` and `PODSHIFT_NW_DEVICE`.
- The environment tag `TSV_ENV` is also in `runtime.conf`, but `podshift config` does not set or remove it. Set it with `sudo podshift env --set <tag>`, which checks the tag.
- Custom keys are in `/home/podshift/.config/podshift/tsv.conf`. Only the podshift user may set or remove them.

When a key is in both files, the system value wins.

Do not use these variables for passwords, tokens and other sensitive data. Use Podman secrets for that purpose. Values are stored in plain text in tsv.conf.

## Custom keys

- A name is `TSV_`, then a capital letter, then capital letters, digits or `_`, for example `TSV_APP_DOMAIN`.
- Names starting with `TSV_NW` or `TSV_ENV` are reserved for PodShift, for example `TSV_NW9` or `TSV_ENV2`. Set the environment tag with `podshift env --set`.
- A name with a secret word, such as `PASSWORD`, `TOKEN`, `SECRET` or `API_KEY`, is refused. Only whole words between `_` count, so `TSV_PASSAGE` is fine.
- A value must not be empty, and must not contain `"`, `'`, control characters or a trailing `\`.
- A value in a known secret format, such as a private key or a GitHub, GitLab, Slack, AWS or JWT token, is refused.

The secret words and formats are listed in `/opt/podshift/conf/tsv-rules.conf`.

tsv.conf is read as data and never run. Only `TSV_NAME=value` lines are used. Comments and blank lines are kept, and any other line is ignored and dropped the next time a key is set or removed.

Removing a key does not change running Quadlets. Their values were filled in when they were installed. The next install of a Quadlet that still uses a removed key fails, and the missing names are logged.

## Usage:

```
podshift config                  list all keys
podshift config <key>            show one key
podshift config <key> <value>    set a key
podshift config --unset <key>    remove a custom key
```

## Examples `(root)`

```shell
sudo podshift config PODSHIFT_NW_DEVICE eth0
```

## Examples `(podshift)`

```shell
podshift config TSV_APP_DOMAIN example.com
podshift config --unset TSV_APP_DOMAIN
```
