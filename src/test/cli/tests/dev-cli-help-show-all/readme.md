# dev-cli-help-show-all

Prints the help straight from `src/server/opt/podshift` on this computer, for you to read: first the main help (through `dev-cli-help-show`), then `podshift --help <command>` for every module and shortcut, each under a heading such as `── podshift --help config ──`. A command without a help file shows `(no help file)`. The output is also saved as `help-show-all.log` in the run folder.

Markdown help is shown with glow, as on the server, so glow must be installed. If it is missing, the test stops with a `Fix:` line. Because the test runner captures the output, glow prints it without colors.

It checks nothing beyond that the help runs. For checks, use `dev-cli-help` and `lint-help-files`.

## Examples

```sh
./test dev-cli-help-show-all
```
