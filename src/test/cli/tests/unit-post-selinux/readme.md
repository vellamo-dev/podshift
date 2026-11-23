# unit-post-selinux

Runs the stubbed bats tests for the post `enforce-selinux` step. It needs bats, but no VM, network or root.

The tests source the step, stub `getenforce`, `setenforce` and `selinuxenabled`, and point `PODSHIFT_SELINUX_CONFIG` and `PODSHIFT_DESKTOP_FLAG` at temporary files. They cover a server install in permissive, enforcing and disabled mode, a desktop install, an upgrade, and a failed switch.

The bats files live in this test's `scripts/` folder, not in `src/test/unit/`, because that folder is only for pure functions tagged `@unit-test: yes`.

## Examples

```bash
./test --plain unit-post-selinux
```
