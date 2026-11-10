# config
Lists, reads and sets PodShift configuration keys.

There are two config files. Each is created from its template the first time a key is set in it:

- System keys are in `/var/lib/podshift/runtime.conf`. Only root may set them: `TSV_ENV`, `PODSHIFT_NW_INITIALIZER` and `PODSHIFT_NW_DEVICE`.
- Custom keys are in `/home/podshift/.config/podshift/tsv.conf`. Only the podshift user may set them. Their names start with `TSV_` and must not be one of the system keys.

When a key is in both files, the system value wins.

## Usage:

```
podshift config                  list all keys
podshift config <key>            show one key
podshift config <key> <value>    set a key
```

## Examples `(root)`

```shell
sudo podshift config PODSHIFT_NW_DEVICE eth0
```

## Examples `(podshift)`

```shell
podshift config TSV_APP_DOMAIN example.com
```
