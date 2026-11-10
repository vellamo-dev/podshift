# Preun actions

Pre-uninstall steps, applied in this order.

| ID | Function | Description |
|---|---|---|
| AUT | `remove-podman-auto-update` | Disables the rootless podman auto-update timer |

The post-uninstall phase (`%postun`) runs after the package files are removed, so it is self-contained in `postun.sh` (no sourced scripts).
