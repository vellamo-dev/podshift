# dev-cli-help-show

Prints `podshift --help` straight from `src/server/opt/podshift` on this computer, for you to read. It needs no build or install, and checks nothing beyond that the help runs. The output is also saved as `help-show-main.log` in the run folder.

For checks, use `dev-cli-help` and `lint-help-files`. To read the help of every command too, use `dev-cli-help-show-all`.

## Examples

```sh
./test dev-cli-help-show
```
