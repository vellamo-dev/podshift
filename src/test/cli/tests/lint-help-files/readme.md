# lint-help-files

Checks the help source in `src/server/opt/podshift` without running anything:

- `doc/help/podshift.txt`, the main `podshift --help` text, exists and has one `{{commands}}` line, where the command list goes.
- Every module and shortcut has a help file, `<name>.md` or `<name>.txt`.
- Every help file belongs to a command, except the files the help itself uses (`podshift.txt`, `version.md`, `note-env-var-conf.txt`).
- Every module has `@run-as: any`, `podshift` or `root`.
- Every module and shortcut has an `@description`, which is shown in the main help.

It needs no VM or container. To run the help code itself, use `dev-cli-help`.

## Examples

```sh
./test lint-help-files
```
