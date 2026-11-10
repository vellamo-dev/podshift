# dev-cli-help

Runs the PodShift help code straight from `src/server/opt/podshift` on this computer, with no build, VM or install:

- `podshift --help` builds the main help: the head, the command groups and the closing line, with no `{{commands}}` left. It is saved as `help-main.log` in the run folder.
- Every module and shortcut is listed exactly once, with a description.
- An unknown name, `podshift --help <name>`, fails with exit 1 and a message.

Markdown help for one command needs glow, so it is not run here. To check the help files without running anything, use `lint-help-files`.

## Examples

```sh
./test dev-cli-help
```
