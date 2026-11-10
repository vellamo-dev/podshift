# clean-rpm-output

Removes the exported RPM packages in `artifacts/rpm/`. Other files there are not touched.

## Examples

```sh
./test clean-rpm-output
./test clean-rpm-output build-rpm-export   # clean, then build a new RPM
```
