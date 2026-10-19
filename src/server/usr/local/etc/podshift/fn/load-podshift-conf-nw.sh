#!/usr/bin/env bash
# @file: load-podshift-conf-nw.sh
# @dir: /usr/local/etc/podshift/fn
# @group: network
# @description: Derives and exports the host's network IP addresses.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints all NetworkManager connection object paths.
# @stdout: prints one connection path per line.
print-all-nw-conf-paths() {
    busctl call org.freedesktop.NetworkManager /org/freedesktop/NetworkManager/Settings \
        org.freedesktop.NetworkManager.Settings ListConnections 2>/dev/null | \
        grep -o '/org/freedesktop/NetworkManager/Settings/[0-9]*' | sort -u
}

# @description: Prints every NetworkManager connection and its IPv4 addresses.
# @stdout: prints connection names and their IPs.
# @exitcode: 0 on success, 1 if no connections are found.
print-nw-conf-ip4s() {
    local paths settings conn_name ips
    paths=$(print-all-nw-conf-paths)
    if [ -z "$paths" ]; then
        echo "No connections found!"
        return 1
    fi
    for path in $paths; do
        # Get settings using the method
        settings=$(
            busctl call org.freedesktop.NetworkManager "$path" \
                org.freedesktop.NetworkManager.Settings.Connection GetSettings 2>/dev/null
        )
        if [ -n "${settings}" ]; then
            # Extract connection name
            conn_name=$(echo "${settings}" | grep '"id" s "' | sed 's/.*"id" s "\([^"]*\)".*/\1/')
            if [ -n "${conn_name}" ]; then
                echo "${conn_name}:"
                # Extract IP addresses
                ips=$(
                    echo "${settings}" | grep -o '"address" s "[0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+"' | sed 's/.*"\([0-9]\+\.[0-9]\+\.[0-9]\+\.[0-9]\+\)".*/\1/'
                )
                if [ -n "${ips}" ]; then
                    echo "${ips}" | sed 's/^/  /'
                else
                    echo "  No IPs configured"
                fi
            fi
        fi
        echo ""
    done
}

# @description: Prints the IPv4 addresses for a given connection name.
# @param: $1 - connection name
# @stdout: prints the IPs for that connection.
print-nw-conf-ip4s-for() {
    local conn_name="$1"
    print-nw-conf-ip4s | awk -v conn="${conn_name}" '
		$0 ~ "^" conn ":" { found=1; next }
		found && /^  [0-9]/ { print $1; next }
		found && /^$/ { found=0; exit }
	'
}

# @description: Reads IPv4 addresses from the [ipv4] section of the NetworkManager config file in order.
# @param: $1 - connection name (e.g. cloud-init-eth0)
# @stdout: prints the IPs, space-separated.
get-config-ips-sudo() {
    local nw_conf conf_file address_lines sorted_lines ip_fields ip_addresses
    nw_conf="$1"
    conf_file="/etc/NetworkManager/system-connections/${nw_conf}.nmconnection"
    # Check if the config file exists
    [[ ! -f "${conf_file}" ]] && return 0
    # Extract lines starting with 'addressX=' from the [ipv4] section
    address_lines=$(awk '/^\[ipv4\]$/{flag=1;next}/^\[/{flag=0}flag&&/^address[0-9]+=/' "${conf_file}")
    # Sort addresses numerically (e.g., address1 before address2)
    sorted_lines=$(echo "${address_lines}" | sort -V)
    # Extract the IP part (before comma or slash)
    ip_fields=$(echo "${sorted_lines}" | cut -d'=' -f2 | cut -d',' -f1 | cut -d'/' -f1)
    # Filter out empty lines and return IPs as a space-separated string
    ip_addresses=$(echo "${ip_fields}" | grep -v '^$')
    echo "${ip_addresses}"
}

# @description: Retrieves the active IPv4 addresses for a connection from the system.
# @param: $1 - connection name (e.g. "cloud-init eth0")
# @stdout: prints the IPs, space-separated.
get-system-ips() {
    local nw_conf system_ips
    nw_conf="$1"
    # Check if the connection is active
    nmcli connection show --active | grep -q "^${nw_conf}\b" || return 0
    # Get all IPv4 addresses for the connection
    system_ips=$(nmcli -t -f IP4.ADDRESS connection show "${nw_conf}" | cut -d':' -f2 | cut -d'/' -f1 | grep -v '^$')
    # Return IPs as a space-separated string
    echo "${system_ips}"
}

# @description: Exports TSV_NW1..8 with the host's IPv4 addresses, ordered by the config file.
# @exitcode: 0 always.
podshift-conf-nw() {
    local initializer device_name system_nw_conf system_ips conf_ips ip_count conf_ip sys_ip i
    local -a system_ips_array conf_ips_array matched_ips_array remaining_ips_array
    # Read configuration from a conf file
    source /usr/local/etc/podshift/fn/load-podshift-conf-runtime.sh --now
    initializer="${PODSHIFT_NW_INITIALIZER}"
    [ -z "$initializer" ] && initializer="cloud-init"
    device_name="${PODSHIFT_NW_DEVICE}"
    [ -z "$device_name" ] && device_name="eth0"
    system_nw_conf="${initializer} ${device_name}"
    # Get system IPs
    system_ips=$(get-system-ips "${system_nw_conf}" | grep -v '^$')
    [[ -z "${system_ips}" ]] && return 0
    readarray -t system_ips_array <<<"${system_ips}"
    # Get config IPs
    conf_ips=$(print-nw-conf-ip4s-for "${system_nw_conf}" | grep -v '^$')
    readarray -t conf_ips_array <<<"${conf_ips}"
    # Match system IPs to config file order
    matched_ips_array=()
    for conf_ip in "${conf_ips_array[@]}"; do
        for sys_ip in "${system_ips_array[@]}"; do
            if [[ "${sys_ip}" == "${conf_ip}" ]]; then
                matched_ips_array+=("${sys_ip}")
                break
            fi
        done
    done
    # Append remaining system IPs not in config
    remaining_ips_array=()
    for sys_ip in "${system_ips_array[@]}"; do
        local FOUND=0
        for conf_ip in "${conf_ips_array[@]}"; do
            if [[ "${sys_ip}" == "${conf_ip}" ]]; then
                FOUND=1
                break
            fi
        done
        if [[ $FOUND -eq 0 ]]; then
            remaining_ips_array+=("${sys_ip}")
        fi
    done
    # Combine matched (config order) and remaining system IPs
    matched_ips_array=("${matched_ips_array[@]}" "${remaining_ips_array[@]}")
    # Export variables (up to 8 IPs)
    ip_count=${#matched_ips_array[@]}
    for (( i = 0; i < ip_count && i < 8; i++ )); do
        # echo "TSV_NW$((i + 1))=${MATCHED_IPS_ARRAY[i]}"
        export "TSV_NW$((i + 1))=${matched_ips_array[i]}"
    done
    # Unset extra variables if fewer IPs
    for (( i = ip_count + 1; i <= 8; i++ )); do
        unset "TSV_NW${i}"
    done
}

# @description: Prints the defined TSV_NW* environment variables (up to 8).
# @stdout: prints the defined TSV_NW* variables.
podshift-conf-nw-print() {
    local i var_name var_value
    echo -e "\nSystem has the following IPv4s defined:\n"
    for (( i = 1; i <= 8; i++ )); do
        var_name="TSV_NW${i}"
        var_value="${!var_name}"
        [[ -n "${var_value}" ]] && echo "  ${var_name}=${var_value}"
    done
    echo ""
}

# Executes only when called or sourced with --print or --now
if [[ "${BASH_SOURCE[0]}" == "${0}" || "${BASH_ARGV[0]:-}" != "${BASH_SOURCE[0]}" ]]; then
    if [[ "${1}" == "--print" ]]; then
        podshift-conf-nw
        podshift-conf-nw-print
    elif [[ "${1}" == "--now" ]]; then
        podshift-conf-nw
    fi
fi