# unit-pure-functions

Runs the bats unit tests in `src/test/unit/` against `src/server/opt/podshift` on this computer. No build, no install, no VM. It takes a few seconds.

Only pure functions are tested: files tagged `# @unit-test: yes`, where the output is fully set by the arguments. Each has one `<function>.bats` file. `lint-pure-functions` runs first and checks that the tags and bats files match.

bats must be installed. If it is missing, the test stops with a `Fix:` line. The tests run with a clean environment, and the output is saved as `unit-pure-functions.log` in the run folder.

## Examples

```sh
./test unit-pure-functions
```
