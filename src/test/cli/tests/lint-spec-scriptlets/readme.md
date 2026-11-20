# lint-spec-scriptlets

Checks `podshift.spec` without running anything:

- `%post` calls `/opt/podshift/rpm/post.sh "$1"`
- `%preun` calls `/opt/podshift/rpm/preun.sh "$1"`
- `%posttrans` calls `/opt/podshift/rpm/posttrans.sh "$1"`
- `%postun` uses `-f %{SOURCE1}`

It needs no VM, container or bats.

## Examples

```sh
./test --plain lint-spec-scriptlets
```
