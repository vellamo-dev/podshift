# lint-cli-modules

Checks the PodShift CLI source in `src/server/opt/podshift`: every module has a valid name and a `main.sh` that passes `bash -n`, every alias is valid and points to a module, and no shortcut has the same name as a module or alias. It needs no VM or container.
