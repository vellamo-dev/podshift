# release-version-check

Checks that a release has reached Copr: the `Version:` in the spec on the GitHub `stable` branch must match the newest successful Copr build for Fedora 45 (`fedora-45-x86_64`). It checks podshift and cockpit-podshift. It needs only `curl`, `jq` and network: no VM, no container and no git.

Run it after you push to `stable`, once Copr has finished building. A future VM release test will run the same check first.

## Results

- **Pass**: both versions match. A different `Release` is shown, but does not fail.
- **Copr is behind**: the Copr build is missing, still running or failed. The output says which build and its state.
- **Copr is ahead**: not expected. Check what is on `stable`.
- **Network error** (exit 1): GitHub or Copr could not be read.

GitHub can serve a spec that is a few minutes old, so run it again if you just pushed.

## Settings

| Variable | Default | Meaning |
|----------|---------|---------|
| `TST_RELEASE_PACKAGES` | `podshift cockpit-podshift` | Which packages to check. |
| `TST_FEDORA_VERSION` | `45` | Fedora version of the chroot. |
| `TST_RELEASE_CHROOT` | `fedora-<version>-x86_64` | The whole chroot, for example `fedora-45-aarch64`. |

The other settings are in [tests.conf](../../shared/conf/tests.conf).

## Examples

```sh
./test release-version-check                                     # both packages
TST_RELEASE_PACKAGES=podshift ./test release-version-check       # podshift only
TST_RELEASE_PACKAGES=cockpit-podshift ./test release-version-check   # PodShift UI only
TST_FEDORA_VERSION=46 ./test release-version-check               # another Fedora
```
