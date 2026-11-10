# secret
Creates, lists, replaces and removes Podman secrets of the podshift user.

When the name or value is left out, it is asked for. The value is typed hidden.

`--replace` overwrites an existing secret. A running container keeps the old value until it is restarted.

## Usage:

```
podshift secret <name> [<value>]           create a secret
podshift secret --replace <name> [<value>] replace a secret
podshift secret --list                     list the secrets
podshift secret --unset [<name>]           remove a secret
```

## Examples `(root)`

```shell
sudo -u podshift -i podshift secret --list
```

## Examples `(podshift)`

```shell
podshift secret db-password
podshift secret --replace db-password
podshift secret --unset db-password
```
