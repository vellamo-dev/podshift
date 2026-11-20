# quick

Runs the source-only checks after you download the project: the lint tests, `dev-cli-help`, `unit-pure-functions`, `unit-cli-selinux`, `unit-post-selinux` and `precheck-unit`.

It does **not** build, install or run PodShift. A pass is not a full validation.

`unit-pure-functions`, `unit-cli-selinux`, `unit-post-selinux` and `precheck-unit` need bats. If bats is missing, `unit-pure-functions` exits 3 with a `Fix:` line and this test is not run.

On Fedora, every `./test` needs `/etc/podshift-desktop` first. That is a host rule, not part of this test.

## Examples

```sh
bash test --plain quick
```
