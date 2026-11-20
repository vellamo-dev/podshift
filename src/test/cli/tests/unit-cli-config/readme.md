# unit-cli-config

Runs the stubbed bats tests in `scripts/` for `podshift config <key> <value>` and `podshift config --unset <key>`, and for reading and writing `tsv.conf`. It needs bats, but no VM, network or root.

The tests source the module, stub the caller checks (`is-admin`, `is-podshift`, `require-podshift`) and `load-podshift-conf-main`, and point `PODSHIFT_TSV_CONF` at a temporary file. The real `tsv-rules.conf` from the source tree is used. They cover saving and replacing a key, refused names (invalid, reserved `TSV_NW` and `TSV_ENV` prefixes, secret words), refused values (empty, quotes, a trailing backslash, a known token), missing rules, removing a key, a key that is not set, a reserved or invalid key, removing a key with a secret name saved before the rules, and callers who are not the podshift user. `TSV_ENV` is refused for set and `--unset` for every caller, root included, and nothing is written. A hand-added line that is not `TSV_NAME=value` is dropped on the next save or remove, with a note, and is never run.

`tsv-conf.bats` tests `read-tsv-conf-lines`, `write-tsv-conf-lines` and `load-podshift-conf-runtime` on temporary files: values are set and exported as data, command substitutions, backticks and command lines are never run (marker files prove it), a last line without a newline is read, `runtime.conf` still wins, written lines are canonical `KEY='value'`, other lines are dropped with a note, and values round trip.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```sh
./test --plain unit-cli-config
```
