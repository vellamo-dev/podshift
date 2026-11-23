# lint-local-variables

Checks the shell and bats files of `src/server`, `src/deployment` and `src/test` without running them. Every lowercase variable that a function or a bats `@test` sets must be declared with `local` in it (see `docs/coding.md`).

A name counts as set when it is assigned at the start of a statement, is a `for` loop variable or is read with `read`. Uppercase names are globals and are not checked. Quoted text, here-documents, comments and case labels such as `source=*)` are skipped. Each finding is a `DETAIL:` line `<file>:<line>: <function>: <name>`.

## Examples

```bash
./test lint-local-variables
```
