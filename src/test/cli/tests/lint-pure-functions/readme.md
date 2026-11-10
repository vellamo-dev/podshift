# lint-pure-functions

Checks the unit test files without running them. Every PodShift file tagged `# @unit-test: yes` must have a bats file `src/test/unit/<function>.bats`, and every bats file there must belong to a tagged file.

Only pure functions are tagged: arguments in, text out, nothing read from the system. The tests themselves run in `unit-pure-functions`.

## Examples

```sh
./test lint-pure-functions
```
