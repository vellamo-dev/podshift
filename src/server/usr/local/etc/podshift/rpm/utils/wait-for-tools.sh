#!/usr/bin/env bash
# wait-for-tools.sh
# /usr/local/etc/podshift/rpm/utils
# Waits for the tools required by the post-transaction steps to become
# available. The tools are declared as RPM requirements, but this guards
# against a package transaction that has not finished making them
# available yet.

if [[ -z "${DIR_288235C4FD95:-}" ]]; then
    DIR_288235C4FD95="$(CDPATH='' cd -P -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    readonly DIR_288235C4FD95
fi

# Returns 0 when every named tool is on PATH.
has-all-tools() {
    local tool
    for tool in "$@"; do
        command -v "${tool}" >/dev/null 2>&1 || return 1
    done
    return 0
}

# Waits for the required tools, returning non-zero on timeout.
wait-for-tools() {
    local required_tools max_tries count
    # shellcheck source=../../fn/utils/print-warning.sh
    source "${DIR_288235C4FD95}/../../fn/utils/print-warning.sh"
    required_tools=(firewall-cmd semanage)
    max_tries=30
    count=0

    # Return immediately if all required tools are already available.
    if has-all-tools "${required_tools[@]}"; then
        return 0
    fi

    # Otherwise wait and check periodically.
    echo -e "\nWaiting for tools to become available..."
    while [ "${count}" -lt "${max_tries}" ]; do
        sleep 3
        count=$((count + 1))
        if has-all-tools "${required_tools[@]}"; then
            return 0
        fi
        echo -e "\tStill waiting... (${count}/${max_tries})"
    done

    print-warning "required tools (${required_tools[*]}) not available after ${max_tries} tries."
    return 1
}
