#!/usr/bin/env bash
# @file: dry-run-quadlet.sh
# @source-dir: src/server/opt/podshift/fn/quadlet
# @dest-dir: /opt/podshift/fn/quadlet
# @host-edit: no
# @group: quadlet
# @category: helper
# @description: Checks a staged quadlet with the Quadlet generator in dry run mode.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Runs the Quadlet generator in dry run mode on the staging directory and returns its exit code.
# @details:
#   Runs "/usr/libexec/podman/quadlet -dryrun -user" with QUADLET_UNIT_DIRS set to the staging
#   directory first and the installed quadlets second, so the staged files win over an installed
#   file of the same name and a reference to an installed .network, .volume, .image or .pod is
#   found. Nothing is generated or written. The generator exits non-zero if it hit an error. Its
#   stderr also has debug lines and warnings, so only the exit code decides; on a failure the
#   stderr is logged, without the "Loading source unit file" lines.
# @arg: $1 - staging directory, with the staged item inside.
# @arg: $2 - directory where Podman installs quadlets.
# @exitcode: 0 if the generator accepted the quadlets, 1 otherwise.
dry-run-quadlet() {
    local staging_dir quadlets_dir quadlet_bin output status
    staging_dir="${1}"
    quadlets_dir="${2}"
    quadlet_bin="/usr/libexec/podman/quadlet"

    if [[ ! -x "${quadlet_bin}" ]]; then
        logger -t podshift-qdl-install -p err "quadlet generator not found: ${quadlet_bin}"
        return 1
    fi

    # The generator prints the generated units on stdout, which is dropped.
    output="$(QUADLET_UNIT_DIRS="${staging_dir}:${quadlets_dir}" "${quadlet_bin}" -dryrun -user 2>&1 >/dev/null)"
    status=$?
    if (( status != 0 )); then
        logger -t podshift-qdl-install -p err "dry run failed with exit code ${status}"
        printf '%s\n' "${output}" | grep -v 'Loading source unit file' | logger -t podshift-qdl-install -p err
        return 1
    fi
    return 0
}
