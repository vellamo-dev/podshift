# update-self
Updates PodShift to the latest version with `dnf`, and the PodShift Cockpit UI (`cockpit-podshift`) with it when it is installed.

It works only when PodShift was installed from a repository such as COPR. An install from an RPM file cannot be updated this way.

- When `cockpit-podshift` is installed and in an enabled repository, both packages are updated in one transaction. Reload the PodShift page in Cockpit afterwards to load the new UI.
- When `cockpit-podshift` is installed but in no enabled repository, for example from an RPM file, only PodShift is updated and a note says the UI was skipped.
- When `cockpit-podshift` is not installed, only PodShift is updated. This command never installs the UI.

## Usage `(root)`

Update PodShift, and the UI when it is installed:

```bash
sudo podshift update-self
```
