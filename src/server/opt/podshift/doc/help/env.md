# env
Shows or sets the environment tag of this server, `TSV_ENV`, for example `dev` or `prod`.

The tag is kept in `/var/lib/podshift/runtime.conf`. Only root may set it.

## Usage:

```
podshift env                  show the tag
podshift env --set            list the suggested tags
podshift env --set <tag>      set the tag
```

A tag may use `a-z`, `A-Z`, `0-9`, `_`, `.` and `-`, up to 128 characters.

## Examples `(root)`

```shell
sudo podshift env --set prod
```

## Examples `(any)`

```shell
podshift env
```
