# build-container-stop

Stops the RPM builder container (`ps-rpm-builder-fc45`) and the cockpit-podshift RPM builder container (`ps-ui-rpm-builder-fc45`) after use, so they free their memory. On a Mac this matters most, because each container runs in its own small VM.

The containers are only stopped, never removed, so you can still look inside them. The next `build-container-start` or `ui-rpm-build` replaces them with fresh containers from the cached images. A container that is not running shows `not running`. The cockpit-podshift RPM builder is skipped when that project is missing.

Set `TST_KEEP_BUILDERS=true` to keep both running, for debugging. The steps then show `kept`.

The build bundles run it after `build-rpm-export`, before the VM tests start. `ui-rpm-build` also stops its own builder at the end.

## Examples

```bash
./test build-container-stop                            # stop both builder containers
TST_KEEP_BUILDERS=true ./test bundle-build-install-validate   # keep them running after the build
```
