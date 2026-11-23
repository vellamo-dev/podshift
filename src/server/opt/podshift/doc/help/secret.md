# secret
Creates, lists, replaces and removes Podman secrets of the podshift user.

When the name is left out on a terminal, it is asked for. The value is never an argument, so it stays out of the shell history and `ps`: on a terminal it is typed hidden, otherwise it is read from stdin, without its trailing newlines.

`--replace` overwrites an existing secret. A running container keeps the old value until it is restarted.

After a change it prints one line, such as `Saved secret db-password.`, `Replaced secret db-password.` or `Removed secret db-password.`, instead of the Podman secret ID.

An admin runs it as the podshift user: `podshift` switches with `sudo -u podshift -i`.

## Usage:

```
podshift secret <name>              create a secret
podshift secret --replace <name>    replace a secret
podshift secret --list              list the secrets
podshift secret --unset [<name>]    remove a secret
```

## Examples `(root)`

```bash
sudo podshift secret --list
```

## Examples `(podshift)`

Create a secret, typing the value hidden:

```bash
podshift secret db-password
```

Create it from a file:

```bash
podshift secret db-password < db-password.txt
```

Replace its value:

```bash
podshift secret --replace db-password
```

Remove it:

```bash
podshift secret --unset db-password
```
