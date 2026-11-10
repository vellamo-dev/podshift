# postinstall-health-output

Runs `podshift health-check` as root in the installer VM in every output mode and checks the output, not the health result:

- at a terminal: colors are used, and once the spinner has cleared, the screen shows the same lines as the plain output;
- plain: no color codes, a head line, a `Result:` line, and a `Fix:` line under every warning and issue;
- `--tsv`: four tab-separated fields per check, and a verdict line;
- `--json`: valid JSON.

It passes even when the system has issues. The outputs are saved in the run folder.

## Examples

```sh
./test postinstall-health-output
```
