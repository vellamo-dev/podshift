#!/usr/bin/env bash
# @file: main.sh
# @dir: /opt/podshift/cli/modules/network
# @group: cli
# @description: Examines, prints, checks, sets, fixes, and reloads the host's external network.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Dispatches the network subcommands.
# @param: $1 - optional subcommand (examine, print, check, set).
podshift-network() {
    case "${1:-}" in
        ""|examine) shift; podshift-network-examine "$@" ;;
        print)       podshift-network-print ;;
        check)       podshift-network-check ;;
        set)         shift; podshift-network-set "$@" ;;
        fix)         podshift-network-fix ;;
        reload)      podshift-network-reload ;;
        *) echo "Unknown network subcommand: ${1}. See 'podshift network --help'." >&2; return 1 ;;
    esac
}

# @description: Detects and prints the external network facts and advice.
podshift-network-examine() {
    local backend device gateway connection mode ips line n
    if [[ "${1:-}" == "--json" ]]; then
        podshift-network-examine-json
        return
    fi
    # shellcheck source=../../../fn/network/nw-common.sh
    source /opt/podshift/fn/network/nw-common.sh

    backend="$(nw-backend)"
    device="$(nw-device)"
    gateway="$(nw-gateway)"
    connection="$(nw-connection)"
    mode="$(nw-mode)"
    ips="$(nw-ips)"

    echo "Network"
    echo "  Backend    ${backend}"
    [[ -n "${connection}" ]] && echo "  Connection ${connection}"
    echo "  Device     ${device:-none}"
    echo "  Gateway    ${gateway:-none}"
    case "${mode}" in
        manual) echo "  Mode       manual (static)" ;;
        auto)   echo "  Mode       auto (DHCP)" ;;
        *)      echo "  Mode       ${mode}" ;;
    esac
    if [[ -n "${ips}" ]]; then
        n=1
        while IFS= read -r line; do
            [[ -n "${line}" ]] || continue
            echo "  TSV_NW${n}    ${line}"
            n=$((n + 1))
        done <<<"${ips}"
    else
        echo "  IPs        none detected"
    fi

    echo
    echo "Notes"
    case "${mode}" in
        auto)
            echo "  * Mode is DHCP - the IP may change on reboot. To pin it:"
            echo "      nmcli connection modify ${connection} ipv4.method manual ipv4.addresses <ip>/24 ipv4.gateway ${gateway}"
            echo "      nmcli connection up ${connection}"
            ;;
        manual)
            echo "  * Static configuration - the IPs are stable."
            ;;
        *)
            echo "  * Could not determine the active connection or its IP method."
            ;;
    esac
    if [[ -z "${device}" ]]; then
        echo "  * No default route found - the machine may have no internet path."
    fi
}

# @description: Prints the derived external IPv4 addresses.
podshift-network-print() {
    local i var_name var_value
    # shellcheck source=../../../fn/load-podshift-conf-nw.sh
    source /opt/podshift/fn/load-podshift-conf-nw.sh --now
    for (( i = 1; i <= 8; i++ )); do
        var_name="TSV_NW${i}"
        var_value="${!var_name}"
        if [[ -n "${var_value}" ]]; then
            echo "${var_name}=${var_value}"
        fi
    done
    return 0
}

# @description: Runs the network health checks and prints a verdict.
# @exitcode: 0 = OK, 1 = WARN, 2 = FAIL.
podshift-network-check() {
    local backend device gateway mode ips line rc
    local fail_count warn_count
    # shellcheck source=../../../fn/network/nw-common.sh
    source /opt/podshift/fn/network/nw-common.sh

    backend="$(nw-backend)"
    device="$(nw-device)"
    gateway="$(nw-gateway)"
    mode="$(nw-mode)"
    ips="$(nw-ips)"

    fail_count=0
    warn_count=0

    echo "Network check"

    if [[ -n "${device}" ]]; then
        echo "  Default route   OK     ${device} via ${gateway}"
    else
        echo "  Default route   FAIL   no default route"
        fail_count=$((fail_count + 1))
    fi

    if [[ -n "${ips}" ]]; then
        line="$(printf '%s' "${ips}" | head -n1)"
        echo "  External IP     OK     ${line}"
    else
        echo "  External IP     FAIL   no external IPv4"
        fail_count=$((fail_count + 1))
    fi

    echo "  Outgoing"
    podshift-network-check-outgoing
    rc=$?
    case "${rc}" in
        1) warn_count=$((warn_count + 1)) ;;
        2) fail_count=$((fail_count + 1)) ;;
    esac

    if [[ "${backend}" != "none" ]]; then
        echo "  Backend         OK     ${backend}"
    else
        echo "  Backend         WARN   no network backend active"
        warn_count=$((warn_count + 1))
    fi

    case "${mode}" in
        auto)
            echo "  Mode            WARN   DHCP - IP may change on reboot"
            warn_count=$((warn_count + 1))
            ;;
        manual)
            echo "  Mode            OK     static"
            ;;
        *)
            echo "  Mode            WARN   ${mode}"
            warn_count=$((warn_count + 1))
            ;;
    esac

    echo
    if (( fail_count > 0 )); then
        echo "Result: FAIL (${fail_count} failure, ${warn_count} warning)"
        return 2
    elif (( warn_count > 0 )); then
        echo "Result: WARN (${warn_count} warning)"
        return 1
    else
        echo "Result: OK"
        return 0
    fi
}

# @description: Probes outgoing connectivity to public hosts.
# @stdout: prints one OK/FAIL line per host.
# @exitcode: 0 = all reachable, 1 = some reachable, 2 = none reachable.
podshift-network-check-outgoing() {
    local -a hosts
    local host reachable total
    if ! command -v curl >/dev/null 2>&1; then
        echo "    curl not installed"
        return 1
    fi
    hosts=(quay.io registry-1.docker.io github.com gitlab.com codeberg.org)
    total=${#hosts[@]}
    reachable=0
    for host in "${hosts[@]}"; do
        if curl -s -o /dev/null --max-time 3 "https://${host}/" 2>/dev/null; then
            echo "    ${host}  OK"
            reachable=$((reachable + 1))
        else
            echo "    ${host}  FAIL"
        fi
    done
    if (( reachable == 0 )); then
        return 2
    elif (( reachable < total )); then
        return 1
    fi
    return 0
}

# @description: Lists devices or sets the network override.
# @param: $@ - [--device <device>] [--initializer <initializer>] [--force].
podshift-network-set() {
    local key value force known
    key=""
    value=""
    force=0
    known=1

    while [[ $# -gt 0 ]]; do
        case "${1}" in
            --device)      key="PODSHIFT_NW_DEVICE";      value="${2:-}"; [[ -n "${2:-}" ]] && shift ;;
            --initializer) key="PODSHIFT_NW_INITIALIZER"; value="${2:-}"; [[ -n "${2:-}" ]] && shift ;;
            --force)       force=1 ;;
            *) echo "Unknown option: ${1}" >&2; return 1 ;;
        esac
        shift
    done

    if [[ -z "${key}" ]]; then
        podshift-network-set-device-menu
        return
    fi

    if [[ -z "${value}" ]]; then
        case "${key}" in
            PODSHIFT_NW_DEVICE)      podshift-network-set-device-menu ;;
            PODSHIFT_NW_INITIALIZER) podshift-network-set-initializer-menu ;;
        esac
        return
    fi

    known=1
    podshift-network-set-validate "${key}" "${value}" || known=0
    podshift-network-set-write "${key}" "${value}" "${force}" "${known}"
}

# @description: Interactive menu to select a network device.
podshift-network-set-device-menu() {
    local detected dev i choice
    local -a devices
    # shellcheck source=../../../fn/network/nw-common.sh
    source /opt/podshift/fn/network/nw-common.sh
    detected="$(nw-device)"
    while IFS= read -r dev; do
        [[ -n "${dev}" && "${dev}" != "lo" ]] && devices+=("${dev}")
    done < <(ls /sys/class/net/ 2>/dev/null)

    if [[ ${#devices[@]} -eq 0 ]]; then
        echo "No devices found." >&2
        return 1
    fi

    echo "Available devices:"
    for i in "${!devices[@]}"; do
        dev="${devices[$i]}"
        if [[ "${dev}" == "${detected}" ]]; then
            echo "  $((i + 1)). ${dev}   (detected, current)"
        else
            echo "  $((i + 1)). ${dev}"
        fi
    done
    echo

    read -r -p "Select [1-${#devices[@]}] or [c]ancel: " choice
    case "${choice}" in
        c|C|"") echo "Cancelled."; return 0 ;;
    esac
    if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#devices[@]} )); then
        podshift-network-set-write "PODSHIFT_NW_DEVICE" "${devices[$((choice - 1))]}" 0 1
    else
        echo "Invalid selection." >&2
        return 1
    fi
}

# @description: Interactive menu to select a network initializer, detected from the system.
podshift-network-set-initializer-menu() {
    local -a values labels
    local i choice backend
    # shellcheck source=../../../fn/network/nw-common.sh
    source /opt/podshift/fn/network/nw-common.sh
    backend="$(nw-backend)"

    if [[ -f /etc/cloud/cloud.cfg ]] || command -v cloud-init >/dev/null 2>&1; then
        values+=("cloud-init")
        labels+=("cloud-init (cloud images, e.g. Hetzner)")
    fi
    case "${backend}" in
        NetworkManager)
            values+=("NetworkManager")
            labels+=("NetworkManager (active)")
            ;;
        systemd-networkd)
            values+=("systemd-networkd")
            labels+=("systemd-networkd (active)")
            ;;
    esac

    if [[ ${#values[@]} -eq 0 ]]; then
        echo "No network initializer detected." >&2
        return 1
    fi

    echo "Detected initializers:"
    for i in "${!values[@]}"; do
        echo "  $((i + 1)). ${labels[$i]}"
    done
    echo

    read -r -p "Select [1-${#values[@]}] or [c]ancel: " choice
    case "${choice}" in
        c|C|"") echo "Cancelled."; return 0 ;;
    esac
    if [[ "${choice}" =~ ^[0-9]+$ ]] && (( choice >= 1 && choice <= ${#values[@]} )); then
        podshift-network-set-write "PODSHIFT_NW_INITIALIZER" "${values[$((choice - 1))]}" 0 1
    else
        echo "Invalid selection." >&2
        return 1
    fi
}

# @description: Validates that a device or initializer was detected.
# @param: $1 - key, $2 - value.
# @exitcode: 0 if detected, 1 if unknown.
podshift-network-set-validate() {
    local key value
    key="${1}"
    value="${2}"
    # shellcheck source=../../../fn/network/nw-common.sh
    source /opt/podshift/fn/network/nw-common.sh
    case "${key}" in
        PODSHIFT_NW_DEVICE)
            [[ -d "/sys/class/net/${value}" ]]
            return
            ;;
        PODSHIFT_NW_INITIALIZER)
            case "${value}" in
                cloud-init)       [[ -f /etc/cloud/cloud.cfg ]] || command -v cloud-init >/dev/null 2>&1; return ;;
                NetworkManager)   [[ "$(nw-backend)" == "NetworkManager" ]]; return ;;
                systemd-networkd) [[ "$(nw-backend)" == "systemd-networkd" ]]; return ;;
            esac
            ;;
    esac
    return 1
}

# @description: Writes the network override with confirmation.
# @param: $1 - key, $2 - value, $3 - force (0/1), $4 - known (0/1).
podshift-network-set-write() {
    local key value force known answer prompt label b n
    key="${1}"
    value="${2}"
    force="${3}"
    known="${4:-1}"
    b=$'\033[1m'
    n=$'\033[0m'
    case "${key}" in
        PODSHIFT_NW_DEVICE)      label="Device" ;;
        PODSHIFT_NW_INITIALIZER) label="Initializer" ;;
    esac
    if [[ "${known}" -eq 1 ]]; then
        prompt="Set ${key}=${value}. Continue? [${b}y${n}es/${b}c${n}ancel] "
    else
        prompt="${label} '${value}' does not exist in the system. Are you sure you want to set it? [${b}y${n}es/${b}c${n}ancel] "
    fi
    if [[ "${force}" -eq 1 ]]; then
        answer="yes"
    else
        read -r -p "${prompt}" answer
    fi
    case "${answer}" in
        yes|y|Y)
            # shellcheck source=../../../fn/utils/update-podshift-conf.sh
            source /opt/podshift/fn/utils/update-podshift-conf.sh --set "${key}" "${value}"
            ;;
        *)
            echo "Cancelled."
            ;;
    esac
}

# @description: Detects network problems and interactively repairs the configuration.
# @exitcode: 0 on success.
podshift-network-fix() {
    local backend device gateway mode ips
    local current_device current_initializer did_fix d
    local -a ip_devices
    # shellcheck source=../../../fn/network/nw-common.sh
    source /opt/podshift/fn/network/nw-common.sh
    # shellcheck source=../../../fn/load-podshift-conf-runtime.sh
    source /opt/podshift/fn/load-podshift-conf-runtime.sh --now

    backend="$(nw-backend)"
    device="$(nw-device)"
    gateway="$(nw-gateway)"
    mode="$(nw-mode)"
    ips="$(nw-ips)"
    current_device="${PODSHIFT_NW_DEVICE:-}"
    current_initializer="${PODSHIFT_NW_INITIALIZER:-}"
    did_fix=0

    echo "Network fix"
    echo "Note: fix only repairs PodShift's configuration (device and initializer). It does not change the system's network."
    echo

    echo "Configuration:"
    echo "  Initializer  ${current_initializer:-auto-detect}"
    echo "  Device       ${current_device:-auto-detect}"
    echo

    # Non-fixable system issues: warn and advise.
    [[ -z "${gateway}" ]] && echo "  No default route    a system issue; fix cannot repair this."
    [[ -z "${ips}" ]]      && echo "  No external IP      a system issue; fix cannot repair this."
    [[ "${mode}" == "auto" ]] && echo "  DHCP mode           a system setting; fix cannot change this."

    # Fixable: the initializer is missing or wrong.
    if [[ -z "${current_initializer}" ]]; then
        if [[ -f /etc/cloud/cloud.cfg ]] || command -v cloud-init >/dev/null 2>&1; then
            echo
            echo "cloud-init is present but no initializer is configured."
            podshift-network-set-initializer-menu
            did_fix=1
        fi
    elif ! podshift-network-set-validate "PODSHIFT_NW_INITIALIZER" "${current_initializer}"; then
        echo
        echo "The configured initializer '${current_initializer}' is not detected on this system."
        podshift-network-set-initializer-menu
        did_fix=1
    fi

    # Fixable: the configured device does not exist.
    if [[ -n "${current_device}" && ! -d "/sys/class/net/${current_device}" ]]; then
        echo
        echo "The configured device '${current_device}' does not exist (detected: ${device})."
        podshift-network-set-device-menu
        did_fix=1
    fi

    # Fixable: several devices carry an IP address, so the main one is ambiguous.
    while IFS= read -r d; do
        [[ -n "${d}" && "${d}" != "lo" ]] || continue
        [[ -n "$(ip -4 -o addr show dev "${d}" 2>/dev/null)" ]] && ip_devices+=("${d}")
    done < <(ls /sys/class/net/ 2>/dev/null)
    if (( ${#ip_devices[@]} > 1 )); then
        echo
        echo "Several devices carry an IP address (${ip_devices[*]}); the main one is ambiguous."
        podshift-network-set-device-menu
        did_fix=1
    fi

    if [[ "${did_fix}" -eq 1 ]]; then
        echo
        echo "Resulting state:"
        podshift-network-print
    else
        echo
        echo "Nothing to fix in the configuration. Run 'podshift nw check' for the full health check."
    fi
    echo
    echo "Done."
    return 0
}

# @description: Re-derives TSV_NW1..8 and prints export commands for the current shell.
# @exitcode: 0 always.
podshift-network-reload() {
    local i var_name var_value
    # shellcheck source=../../../fn/load-podshift-conf-nw.sh
    source /opt/podshift/fn/load-podshift-conf-nw.sh --now
    echo "Apply to this shell with: eval \"\$(podshift nw reload)\"" >&2
    for (( i = 1; i <= 8; i++ )); do
        var_name="TSV_NW${i}"
        var_value="${!var_name}"
        if [[ -n "${var_value}" ]]; then
            printf 'export %s=%q\n' "${var_name}" "${var_value}"
        fi
    done
    return 0
}

# @description: Quotes and escapes a value as a JSON string.
# @param: $1 - value.
# @stdout: the JSON string (including quotes).
json-q() {
    local s
    s="${1}"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    printf '"%s"' "${s}"
}

# @description: Prints the examine facts as a single line of JSON.
# @stdout: one line of JSON.
podshift-network-examine-json() {
    local backend device gateway connection mode ips line n
    # shellcheck source=../../../fn/network/nw-common.sh
    source /opt/podshift/fn/network/nw-common.sh

    backend="$(nw-backend)"
    device="$(nw-device)"
    gateway="$(nw-gateway)"
    connection="$(nw-connection)"
    mode="$(nw-mode)"
    ips="$(nw-ips)"

    printf '{'
    printf '"backend":%s' "$(json-q "${backend}")"
    printf ',"connection":%s' "$(json-q "${connection}")"
    printf ',"device":%s' "$(json-q "${device}")"
    printf ',"gateway":%s' "$(json-q "${gateway}")"
    printf ',"mode":%s' "$(json-q "${mode}")"
    printf ',"ips":['
    n=0
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        [[ ${n} -gt 0 ]] && printf ','
        printf '%s' "$(json-q "${line}")"
        n=$((n + 1))
    done <<<"${ips}"
    printf ']}'
    printf '\n'
}

podshift-network "$@"
