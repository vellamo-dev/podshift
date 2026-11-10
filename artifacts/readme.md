# Artifacts

Generated output from build and test runs. Only this readme is tracked in git; everything else here is transient and gitignored.

- `logs/` - timestamped test logs.
- `rpm/` - the built RPM package.
- `tmp/` - miscellaneous temporary data.
- `work/` - temporary files created by agents and automation.

To keep each worker's data separate, use a subdirectory under `work/`.

The test engine creates these folders when it starts and stops if any of them is missing, not a real directory, or not writable. They can be deleted at any time; the next run recreates them.

Do not place items directly in this directory; use the subdirectories listed above.
