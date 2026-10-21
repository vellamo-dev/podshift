# RPM Stager — Deployment

Build-time tooling that stages the `src/server/` tree into the RPM buildroot.

It clones the directory layout and copies each file with the correct permissions (shell scripts `0755`, all other payload `0644`), driven by a single allowlist, then generates the file and directory lists consumed by the RPM spec and by SELinux `restorecon`.

Runs only when building the package — it is not part of the installed application.

All scripts run under `set -euo pipefail`, so any failure aborts the build instead of producing an incomplete RPM.

## How it runs

`rpm-install.sh` is the entry point (sourced by the spec's `%install`). It orchestrates the pipeline in this order:

1. generate the SELinux `restorecon` directory list from the source tree
2. recreate the directory layout in the build root
3. deploy `.sh` scripts (`0755`)
4. deploy allowlisted non-`.sh` files (`0644`)
5. generate `files.list` for the `%files` directive

## Step output

Each step emits a stable, machine-parseable tag, matching the install scripts' `[PS-*]` convention:

```
[PS-DP-0DP] Preparing files for RPM package...
[PS-DP-DRL] Generating directories list...
    [OK] Done
[PS-DP-DRS] Deploying directories...
    [OK] Done
[PS-DP-SHS] Deploying shell scripts...
    [OK] Done
[PS-DP-FLS] Deploying files...
    [OK] Done
[PS-DP-FLL] Generating files list...
    [OK] Done
    [OK] Files ready for RPM package creation
```

`grep '\[PS-DP-'` lists the steps; `grep '\[OK\]\|\[WARN\]'` gives the per-step status.

| Tag | Function | Purpose |
| --- | --- | --- |
| `PS-DP-0DP` | `prepare-files-for-rpm-package` | entry point / orchestrator |
| `PS-DP-DRL` | `generate-rpm-dirs-list` | generate `conf/restorecon-dirs` |
| `PS-DP-DRS` | `deploy-dirs` | recreate the directory layout |
| `PS-DP-SHS` | `deploy-sh-scripts` | deploy `.sh` scripts (`0755`) |
| `PS-DP-FLS` | `deploy-files` | deploy allowlisted files (`0644`) |
| `PS-DP-FLL` | `generate-files-list-for-rpm` | generate `files.list` |

## Files

| File | Purpose |
| --- | --- |
| `./rpm-install.sh` | Entry point. Stages `src/server` into the build root, deploys directories/scripts/files, and generates `files.list` for the `%files` directive. |
| `./allowed-extensions.conf` | Allowlist consumed by `deploy-files.sh`: the file extensions (`.conf`, `.service`, …) and extensionless basenames to deploy as `0644`. |
| `./fn/_load.sh` | Sources all deployment helper scripts so their functions share one namespace. |
| `./fn/utils/print-step.sh` | Step printer: `print-step-header` / `print-step-ok` / `print-step-warn` / `print-step-skip`. |
| `./fn/deploy-dirs.sh` | `deploy-dirs()`: recreates the source directory tree inside the build root using `install -dm755`. |
| `./fn/deploy-files.sh` | `deploy-files()`: copies non-`.sh` files listed in the allowlist (configs, systemd units, docs) into the build root with mode `0644`. |
| `./fn/deploy-sh-scripts.sh` | `deploy-sh-scripts()`: copies all `.sh` scripts into the build root with executable mode `0755`. |
| `./fn/generate-files-list-for-rpm.sh` | `generate-files-list-for-rpm()`: lists every deployed file under the build root and writes `files.list`, consumed by `%files -f files.list`. |
| `./fn/generate-rpm-dirs-list.sh` | `generate-rpm-dirs-list()`: derives the set of directories from the source tree and writes `conf/restorecon-dirs` for later SELinux `restorecon`. |

## Notes

- **`allowed-extensions.conf` is a manual whitelist.** Adding a new file type to `src/server` requires adding its extension (or basename) here — otherwise `deploy-files.sh` silently skips it and the RPM ships without it.
- **`conf/restorecon-dirs` is generated.** The source file is an empty placeholder; `generate-rpm-dirs-list.sh` overwrites it with the real directory list at build time.
