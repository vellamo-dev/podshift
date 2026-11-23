# unit-cli-config

Runs the stubbed bats tests in `scripts/` for `podshift config <key> <value>` and `podshift config --unset <key>`, and for reading and writing `tsv.conf`. It needs bats, but no VM, network or root.

The tests source the module, stub the caller checks (`is-admin`, `is-podshift`, `require-podshift`) and `load-podshift-conf-main`, and point `PODSHIFT_TSV_CONF` at a temporary file. The real `tsv-rules.conf` from the source tree is used. They cover saving and replacing a key, refused names (invalid, reserved `TSV_NW` and `TSV_ENV` prefixes, secret words), refused values (empty, quotes, a trailing backslash, a known token), missing rules, removing a key, a key that is not set, a reserved or invalid key, removing a key with a secret name saved before the rules, and callers who are not the podshift user. Getting a key prints its line, and a key with pattern characters is refused. Root saves a system key in the runtime config, with sudo stubbed. `TSV_ENV` is refused for set and `--unset` for every caller, root included, and nothing is written. A hand-added line that is not `TSV_NAME=value` is dropped on the next save or remove, with a note, and is never run.

`tsv-conf.bats` tests `read-tsv-conf-lines`, `write-tsv-conf-lines` and `load-podshift-conf-runtime` on temporary files: values are set and exported as data, command substitutions, backticks and command lines are never run (marker files prove it), a last line without a newline is read, `runtime.conf` still wins, written lines are canonical `KEY='value'`, other lines are dropped with a note, and values round trip.

`remove-tsv-conf.bats` tests `remove-tsv-conf` on its own: every line of the key goes, the rest stays, the file is written `0644`, a key or file that is not there returns 2, and a reserved name, another user or a wrong argument count changes nothing.

`profile-d.bats` sources a copy of `/etc/profile.d/podshift.sh` that points at the source tree, with `is-podshift`, `load-podshift-conf-nw` and `id` stubbed. An ordinary user gets nothing, a member of `wheel` and the podshift user get `hcl`, `quit` and the `PODSHIFT_*` and `TSV_*` variables, and a shell that is not Bash skips the file. The root branch is not tested, because the tests do not run as root.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```bash
./test --plain unit-cli-config
```
