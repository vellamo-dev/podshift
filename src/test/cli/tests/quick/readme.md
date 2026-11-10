# quick

Runs the source-only checks after you download the project: the lint tests, `dev-cli-help`, and `unit-pure-functions`.

It does **not** build, install or run PodShift. A pass is not a full validation.

`unit-pure-functions` needs bats. If bats is missing, that test exits 3 with a `Fix:` line and this test is not run.

On Fedora, every `./test` needs `/etc/podshift-desktop` first. That is a host rule, not part of this test.

## Examples

```sh
bash test --plain quick
```
