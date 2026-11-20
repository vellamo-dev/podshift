#!/usr/bin/env bash
# @file: precheck.sh
# @source-dir: utils/portable
# @group: portable
# @category: entry
# @description: Checks whether PodShift can be installed and run on this machine, without changing anything.
# @details:
#   Answers one question before you install PodShift: can PodShift be installed on this
#   machine, and will it work here? It gathers facts about the system, shows them, then
#   checks them step by step. A blocker stops the run.
#   Run it with one line (with sudo it also does a dnf dry run):
#   curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | bash
#   curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | sudo bash
#   curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | bash -s -- --json
#   Read-only: it never installs anything, never enables a repository and never writes a
#   file. Only dnf itself may refresh its metadata cache when it is asked which package
#   versions are available.
#   Exit codes: 0 Ready, 1 Ready with warnings, 2 Not possible, 3 Installed, 4 wrong option.
#   This file is the single-file exception to the repository's one-function-per-file rule
#   (see docs/coding.md, Functions): it has to run on its own, so it holds several functions
#   and sources nothing. It needs Bash 3.2 or newer and tools that Fedora ships. Every
#   optional tool is checked with command -v. All code is inside functions and the last line
#   calls main, so a download that is cut off does nothing.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# Under sh (dash) or a very old Bash, say so and stop. POSIX syntax only here.
if [ -z "${BASH_VERSION:-}" ]; then
    echo "precheck: this script needs Bash. Run it with bash, for example: curl -fsSL <url> | bash" >&2
    exit 2
fi

# @description: Sets the constants, the default modes and the empty result lists.
# @details:
#   Keep the constants in sync with the PodShift sources named in the comments below.
#   PRECHECK_ROOT, when set by the tests, becomes PC_ROOT and stands in for / when files are read.
# @exitcode: 0 always.
pc_init() {
    PC_VERSION="0.1.0"
    # Same as PODSHIFT_MIN_FEDORA in src/server/opt/podshift/conf/main.conf.
    PC_MIN_FEDORA=45
    # Podman 6 is planned for Fedora 45 (docs/design-choices.md, Fedora Server).
    PC_MIN_PODMAN="6.0"
    # PodShift's own scripts: the test lab needs Bash 5.0 (TST_BASH_MIN_VERSION),
    # and the server code uses Bash 4 features (mapfile, ${var,,}).
    PC_MIN_BASH="5.0"
    # This script itself.
    PC_SELF_MIN_BASH="3.2"
    # Keep in sync with Requires in podshift.spec.
    PC_REQUIRES="NetworkManager firewalld cockpit podman openssh-server policycoreutils-python-utils cockpit-selinux cockpit-podman cockpit-files pcp python3-pcp tree nano fail2ban shadow-utils unzip less glow jq"
    # docs/usage.md: sudo dnf copr enable -y vellamo/podshift
    PC_COPR="vellamo/podshift"
    PC_COPR_REPO_ID="copr:copr.fedorainfracloud.org:vellamo:podshift"
    PC_COPR_REPO_FILE="/etc/yum.repos.d/_copr:copr.fedorainfracloud.org:vellamo:podshift.repo"
    # PODSHIFT_DESKTOP_FLAG in src/server/opt/podshift/conf/main.conf.
    PC_DESKTOP_FLAG="/etc/podshift-desktop"
    # Ports PodShift opens (src/server/etc/firewalld/services/podshift.xml).
    PC_PORTS="80 81 443 1022"
    # User and groups from PodShift's sysusers.d file.
    PC_USER_UID=300
    PC_DOCS="https://github.com/vellamo-dev/podshift/blob/main/docs"

    # Hidden test hook: a folder that stands in for / when reading files.
    PC_ROOT="${PRECHECK_ROOT:-}"
    PC_MODE="plain"
    PC_JSON="no"
    PC_TIMEOUT=""

    # Results, one entry per check line.
    PC_N=0
    PC_R_SECTION=()
    PC_R_STATUS=()
    PC_R_NAME=()
    PC_R_NOTE=()
    PC_R_DETAIL=()
    # Sections for the Summary.
    PC_S_N=0
    PC_S_TITLE=()
    PC_S_STATUS=()
    PC_S_PROBLEM=()
    PC_CUR=-1
    PC_SECTIONS_PLANNED="Checking OS|Checking PodShift|Checking packages|Checking security and clashes"
    PC_SKIPPED=0
    PC_INSTALLED="no"
}

# ---------- small helpers ----------

# @description: Prints the path of a system file, under PRECHECK_ROOT when the tests set it.
# @arg: $1 - absolute path of the file, for example /etc/os-release.
# @stdout: the path, without a trailing newline.
# @exitcode: 0 always.
pc_path() {
    printf '%s%s' "${PC_ROOT}" "$1"
}

# @description: Tells whether a command exists.
# @arg: $1 - name of the command.
# @exitcode: 0 if the command exists, 1 otherwise.
pc_has() {
    command -v "$1" >/dev/null 2>&1
}

# @description: Runs a command with a time limit when the timeout tool exists, and without one otherwise.
# @arg: $1 - time limit in seconds.
# @arg: $2 - the command, followed by its arguments.
# @stdout: whatever the command prints.
# @stderr: whatever the command prints to standard error.
# @exitcode: the exit code of the command, 124 if timeout stopped it.
pc_run() {
    local secs
    secs="$1"
    shift
    if [ "${PC_TIMEOUT}" = "yes" ]; then
        timeout "${secs}" "$@"
    else
        "$@"
    fi
}

# @description: Prints one value from os-release, without quotes.
# @details:
#   Reads /etc/os-release, or /usr/lib/os-release when the first is missing, both under PC_ROOT.
#   Prints nothing when neither file can be read or the key is missing.
# @arg: $1 - the key, for example ID or VERSION_ID.
# @stdout: the value, or nothing.
# @exitcode: 0 always.
pc_osr() {
    local file
    file="$(pc_path /etc/os-release)"
    [ -r "${file}" ] || file="$(pc_path /usr/lib/os-release)"
    [ -r "${file}" ] || return 0
    grep "^$1=" "${file}" 2>/dev/null | head -n 1 | cut -d= -f2- | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'\$//"
}

# @description: Tells whether one dotted version is equal to or newer than another.
# @details:
#   Parts are split on dots and dashes. Only the leading digits of each part count, so
#   6.0.1-1.fc45 works. A missing part counts as 0.
# @arg: $1 - the version to test.
# @arg: $2 - the version to compare it with.
# @exitcode: 0 if $1 is equal to or newer than $2, 1 otherwise.
pc_ver_ge() {
    local a b x y
    a="$1"
    b="$2"
    while [ -n "${a}" ] || [ -n "${b}" ]; do
        x="${a%%[.-]*}"
        y="${b%%[.-]*}"
        if [ "${x}" = "${a}" ]; then a=""; else a="${a#*[.-]}"; fi
        if [ "${y}" = "${b}" ]; then b=""; else b="${b#*[.-]}"; fi
        x="${x%%[!0-9]*}"
        y="${y%%[!0-9]*}"
        x=$((10#${x:-0}))
        y=$((10#${y:-0}))
        [ "${x}" -gt "${y}" ] && return 0
        [ "${x}" -lt "${y}" ] && return 1
    done
    return 0
}

# @description: Prints text in a colour in interactive mode, and plain otherwise.
# @arg: $1 - ANSI colour code, for example 32 for green.
# @arg: $2 - the text.
# @stdout: the text, coloured in interactive mode, without a trailing newline.
# @exitcode: 0 always.
pc_c() {
    if [ "${PC_MODE}" = "interactive" ]; then
        printf '\033[%sm%s\033[0m' "$1" "$2"
    else
        printf '%s' "$2"
    fi
}

# @description: Prints a printf format and its arguments unless the output is JSON.
# @arg: $1 - the printf format.
# @arg: $2 - the values for the format, as many as it needs.
# @stdout: the formatted text, or nothing in JSON mode.
# @exitcode: 0 in JSON mode, otherwise the exit code of printf.
pc_say() {
    [ "${PC_JSON}" = "yes" ] && return 0
    printf "$@"
}

# @description: Prints the icon for a check status.
# @arg: $1 - the status: ok, warn, block, skip, or anything else for info.
# @stdout: one icon, coloured in interactive mode.
# @exitcode: 0 always.
pc_icon() {
    case "$1" in
        ok) pc_c 32 "✔" ;;
        warn) pc_c 33 "⚠" ;;
        block) pc_c 31 "✘" ;;
        skip) pc_c 90 "○" ;;
        *) pc_c 36 "ℹ" ;;
    esac
}

# @description: Prints a string as a quoted JSON string.
# @details:
#   Escapes backslashes, double quotes, newlines and tabs, and drops carriage returns.
# @arg: $1 - the string.
# @stdout: the JSON string with its quotes, without a trailing newline.
# @exitcode: 0 always.
pc_json_str() {
    local s
    s="$1"
    s="${s//\\/\\\\}"
    s="${s//\"/\\\"}"
    s="${s//$'\n'/\\n}"
    s="${s//$'\t'/\\t}"
    s="${s//$'\r'/}"
    printf '"%s"' "${s}"
}

# ---------- output blocks ----------

# @description: Starts a section, records it for the Summary and prints its header and Progress label.
# @arg: $1 - the section title, for example Checking OS.
# @stdout: the section header and the Progress label, or nothing in JSON mode.
# @exitcode: 0 always.
pc_section() {
    PC_CUR=${PC_S_N}
    PC_S_TITLE[PC_S_N]="$1"
    PC_S_STATUS[PC_S_N]="ok"
    PC_S_PROBLEM[PC_S_N]=""
    PC_S_N=$((PC_S_N + 1))
    if [ "${PC_MODE}" = "interactive" ]; then
        pc_say '\n\033[1;35m▶\033[0m \033[1;36m%s\033[0m\n' "$1"
    else
        pc_say '\n▶ %s\n' "$1"
    fi
    pc_say '\n    Progress:\n'
}

# @description: Records one check in the current section and prints its line.
# @details:
#   A block makes the section blocked, and a warn makes an ok section warned. The first
#   problem's name is kept for the Summary. Each skip adds to PC_SKIPPED.
# @arg: $1 - the status: ok, warn, block, skip or info.
# @arg: $2 - the check name.
# @arg: $3 - optional short note, shown in brackets.
# @arg: $4 - optional detail lines, shown indented under the check.
# @stdout: the check line and its detail lines, or nothing in JSON mode.
# @exitcode: 0 always.
pc_result() {
    local status name note detail cur
    status="$1"
    name="$2"
    note="${3:-}"
    detail="${4:-}"
    PC_R_SECTION[PC_N]="${PC_S_TITLE[PC_CUR]}"
    PC_R_STATUS[PC_N]="${status}"
    PC_R_NAME[PC_N]="${name}"
    PC_R_NOTE[PC_N]="${note}"
    PC_R_DETAIL[PC_N]="${detail}"
    PC_N=$((PC_N + 1))
    cur="${PC_S_STATUS[PC_CUR]}"
    case "${status}" in
        block)
            PC_S_STATUS[PC_CUR]="block"
            [ -n "${PC_S_PROBLEM[PC_CUR]}" ] && [ "${cur}" = "block" ] || PC_S_PROBLEM[PC_CUR]="${name}"
            ;;
        warn)
            if [ "${cur}" = "ok" ]; then
                PC_S_STATUS[PC_CUR]="warn"
                PC_S_PROBLEM[PC_CUR]="${name}"
            fi
            ;;
        skip) PC_SKIPPED=$((PC_SKIPPED + 1)) ;;
    esac
    if [ -n "${note}" ]; then
        pc_say '        %s %s [%s]\n' "$(pc_icon "${status}")" "${name}" "${note}"
    else
        pc_say '        %s %s\n' "$(pc_icon "${status}")" "${name}"
    fi
    if [ -n "${detail}" ]; then
        pc_say '%s\n' "${detail}" | sed 's/^/            /'
    fi
}

# @description: Ends the current section with its Verdict.
# @stdout: the Verdict block, or nothing in JSON mode.
# @exitcode: 0 if the section has no blocker, 1 otherwise.
pc_section_end() {
    local status text
    status="${PC_S_STATUS[PC_CUR]}"
    case "${status}" in
        ok) text="Passed" ;;
        warn) text="Passed with warnings. Read them before you install." ;;
        block) text="Blocker found. The checks stop here." ;;
    esac
    [ "${PC_S_TITLE[PC_CUR]}" = "Checking PodShift" ] && [ "${PC_INSTALLED}" = "yes" ] && status="info" \
        && text="PodShift is already installed. The install checks are not needed."
    pc_say '\n    Verdict:\n        %s %s\n' "$(pc_icon "${status}")" "${text}"
    [ "${status}" != "block" ]
}

# ---------- phase 1: gather ----------

# @description: Prints the total memory in GiB.
# @details:
#   Reads MemTotal from /proc/meminfo, or hw.memsize from sysctl on macOS.
# @stdout: the memory, for example 7.7 GiB, or unknown.
# @exitcode: 0 always.
pc_get_memory() {
    local kb bytes
    kb="$(awk '/^MemTotal:/ { print $2; exit }' "$(pc_path /proc/meminfo)" 2>/dev/null)"
    if [ -z "${kb}" ] && pc_has sysctl; then
        bytes="$(sysctl -n hw.memsize 2>/dev/null)"
        [ -n "${bytes}" ] && kb=$((bytes / 1024))
    fi
    if [ -n "${kb}" ]; then
        awk -v k="${kb}" 'BEGIN { printf "%.1f GiB", k / 1048576 }'
    else
        printf 'unknown'
    fi
}

# @description: Prints the free space on /, /var and /home.
# @stdout: one entry per existing folder, comma separated, for example / 20.1 GiB, or unknown.
# @exitcode: 0 always.
pc_get_disk() {
    local dir free out
    out=""
    for dir in / /var /home; do
        [ -d "${dir}" ] || continue
        free="$(df -Pk "${dir}" 2>/dev/null | awk 'NR == 2 { k = $4; if (k >= 1048576) printf "%.1f GiB", k / 1048576; else printf "%d MiB", k / 1024 }')"
        [ -n "${free}" ] || free="unknown"
        out="${out:+${out}, }${dir} ${free}"
    done
    printf '%s' "${out:-unknown}"
}

# @description: Prints the global IP addresses of the machine.
# @stdout: the addresses, comma separated, or unknown.
# @exitcode: 0 always.
pc_get_ips() {
    local ips
    ips=""
    if pc_has ip; then
        ips="$(ip -o addr show scope global 2>/dev/null | awk '{ sub(/\/.*/, "", $4); print $4 }' | tr '\n' ' ')"
    elif pc_has hostname; then
        ips="$(hostname -I 2>/dev/null)"
    fi
    ips="$(printf '%s' "${ips}" | awk '{ for (i = 1; i <= NF; i++) printf "%s%s", (i > 1 ? ", " : ""), $i }')"
    printf '%s' "${ips:-unknown}"
}

# @description: Prints whether /usr is writable, read-only or unknown.
# @details:
#   An image-based system (/run/ostree-booted exists) or a read-only mount of /usr (or of /
#   when /usr has no mount of its own) counts as read-only. As root on the real system, /usr
#   that root cannot write also counts as read-only.
# @stdout: read-only (image-based system), read-only (mounted read-only), read-only (not writable for root), writable or unknown.
# @exitcode: 0 always.
pc_get_usr_state() {
    local mounts opts
    if [ -e "$(pc_path /run/ostree-booted)" ]; then
        printf 'read-only (image-based system)'
        return 0
    fi
    mounts="$(pc_path /proc/mounts)"
    if [ -r "${mounts}" ]; then
        opts="$(awk '$2 == "/usr" { print $4; found = 1; exit } END { }' "${mounts}" 2>/dev/null)"
        [ -n "${opts}" ] || opts="$(awk '$2 == "/" { o = $4 } END { print o }' "${mounts}" 2>/dev/null)"
        case ",${opts}," in
            *,ro,*) printf 'read-only (mounted read-only)'; return 0 ;;
        esac
        if [ -z "${PC_ROOT}" ] && [ "${SYS_IS_ROOT}" = "yes" ] && [ ! -w /usr ]; then
            printf 'read-only (not writable for root)'
            return 0
        fi
        printf 'writable'
        return 0
    fi
    printf 'unknown'
}

# @description: Prints the version and release of an installed RPM package.
# @arg: $1 - the package name.
# @stdout: the version, for example 6.0.1-1.fc45, or nothing when rpm or the package is missing.
# @exitcode: 0 always.
pc_rpm_version() {
    pc_has rpm || return 0
    rpm -q --qf '%{VERSION}-%{RELEASE}\n' "$1" 2>/dev/null | grep -v 'not installed' | head -n 1
}

# @description: Gathers all system facts into the SYS_* variables.
# @details:
#   Covers the OS, edition, install type, kernel, architecture, both Bash versions, CPUs,
#   memory, disk, virtualisation, hostname, IP addresses, SELinux, root, /usr, the installed
#   PodShift and Podman versions and whether the PodShift Copr repo is enabled.
# @exitcode: 0 always.
pc_gather() {
    local uid
    SYS_KERNEL_NAME="$(uname -s 2>/dev/null)"
    SYS_OS_ID="$(pc_osr ID)"
    SYS_OS_NAME="$(pc_osr PRETTY_NAME)"
    SYS_OS_VERSION="$(pc_osr VERSION_ID)"
    SYS_OS_VARIANT_ID="$(pc_osr VARIANT_ID)"
    if [ -z "${SYS_OS_ID}" ] && [ "${SYS_KERNEL_NAME}" = "Darwin" ]; then
        SYS_OS_ID="macos"
        SYS_OS_VERSION="$(sw_vers -productVersion 2>/dev/null)"
        SYS_OS_NAME="macOS ${SYS_OS_VERSION}"
    fi
    [ -n "${SYS_OS_NAME}" ] || SYS_OS_NAME="${SYS_OS_ID:-unknown} ${SYS_OS_VERSION}"
    SYS_KERNEL="$(uname -r 2>/dev/null)"
    SYS_ARCH="$(uname -m 2>/dev/null)"
    SYS_BASH_VERSION="${BASH_VERSINFO[0]}.${BASH_VERSINFO[1]}.${BASH_VERSINFO[2]}"
    # The Bash PodShift uses: /bin/bash runs its RPM scripts.
    SYS_SYSTEM_BASH="$(pc_path /bin/bash)"
    [ -x "${SYS_SYSTEM_BASH}" ] || SYS_SYSTEM_BASH="$(command -v bash 2>/dev/null)"
    SYS_SYSTEM_BASH_VERSION=""
    [ -n "${SYS_SYSTEM_BASH}" ] && SYS_SYSTEM_BASH_VERSION="$("${SYS_SYSTEM_BASH}" -c 'printf "%s.%s.%s" "${BASH_VERSINFO[0]}" "${BASH_VERSINFO[1]}" "${BASH_VERSINFO[2]}"' 2>/dev/null)"
    SYS_CPU="$(getconf _NPROCESSORS_ONLN 2>/dev/null)"
    [ -n "${SYS_CPU}" ] || SYS_CPU="unknown"
    SYS_MEMORY="$(pc_get_memory)"
    SYS_DISK="$(pc_get_disk)"
    SYS_VIRT="unknown"
    if pc_has systemd-detect-virt; then
        SYS_VIRT="$(systemd-detect-virt 2>/dev/null)"
        [ -n "${SYS_VIRT}" ] || SYS_VIRT="unknown"
        [ "${SYS_VIRT}" = "none" ] && SYS_VIRT="none (bare metal)"
    fi
    SYS_HOSTNAME="$(uname -n 2>/dev/null)"
    SYS_IPS="$(pc_get_ips)"
    if pc_has getenforce; then
        SYS_SELINUX="$(getenforce 2>/dev/null | tr 'A-Z' 'a-z')"
    elif [ -r "$(pc_path /sys/fs/selinux/enforce)" ]; then
        if [ "$(cat "$(pc_path /sys/fs/selinux/enforce)" 2>/dev/null)" = "1" ]; then SYS_SELINUX="enforcing"; else SYS_SELINUX="permissive"; fi
    fi
    [ -n "${SYS_SELINUX:-}" ] || SYS_SELINUX="not available"
    uid="$(id -u 2>/dev/null)"
    SYS_USER="$(id -un 2>/dev/null)"
    if [ "${uid}" = "0" ]; then SYS_IS_ROOT="yes"; else SYS_IS_ROOT="no"; fi
    SYS_USR_STATE="$(pc_get_usr_state)"
    SYS_PODSHIFT_VERSION="$(pc_rpm_version podshift)"
    SYS_PODMAN_VERSION="$(pc_rpm_version podman)"
    if [ -z "${SYS_PODMAN_VERSION}" ] && pc_has podman; then
        SYS_PODMAN_VERSION="$(podman --version 2>/dev/null | awk '{ print $NF }')"
    fi
    # Edition from VARIANT_ID, then the boot target.
    SYS_EDITION="unknown"
    SYS_EDITION_WHY=""
    case "${SYS_OS_VARIANT_ID}" in
        server | cloud | container | iot | coreos)
            SYS_EDITION="server"; SYS_EDITION_WHY="VARIANT_ID=${SYS_OS_VARIANT_ID}" ;;
        workstation | kde | budgie | cinnamon | cosmic | i3 | lxde | lxqt | mate | miracle | sway | xfce | silverblue | kinoite | sericea | onyx)
            SYS_EDITION="desktop"; SYS_EDITION_WHY="VARIANT_ID=${SYS_OS_VARIANT_ID}" ;;
    esac
    SYS_DEFAULT_TARGET=""
    pc_has systemctl && SYS_DEFAULT_TARGET="$(systemctl get-default 2>/dev/null)"
    if [ "${SYS_EDITION}" != "desktop" ] && [ "${SYS_DEFAULT_TARGET}" = "graphical.target" ]; then
        SYS_EDITION="desktop"
        SYS_EDITION_WHY="${SYS_EDITION_WHY:+${SYS_EDITION_WHY}, }boots to a graphical desktop"
    fi
    [ "${SYS_EDITION}" = "unknown" ] && [ -n "${SYS_OS_VARIANT_ID}" ] && SYS_EDITION_WHY="VARIANT_ID=${SYS_OS_VARIANT_ID}"
    # Install type: same rule as is-install-type-desktop (the flag file exists).
    if [ -e "$(pc_path "${PC_DESKTOP_FLAG}")" ]; then SYS_INSTALL_TYPE="desktop"; else SYS_INSTALL_TYPE="server"; fi
    if [ -f "$(pc_path "${PC_COPR_REPO_FILE}")" ] && grep -q '^enabled *= *1' "$(pc_path "${PC_COPR_REPO_FILE}")" 2>/dev/null; then
        SYS_COPR_ENABLED="yes"
    else
        SYS_COPR_ENABLED="no"
    fi
}

# ---------- phase 2: show ----------

# @description: Prints one line of the System block.
# @arg: $1 - the label.
# @arg: $2 - the value.
# @stdout: the label and value, or nothing in JSON mode.
# @exitcode: 0 always.
pc_fact() {
    pc_say '        %-16s %s\n' "$1" "$2"
}

# @description: Prints the System block with the gathered facts.
# @stdout: the System header and one line per fact, or nothing in JSON mode.
# @exitcode: 0 always.
pc_show_system() {
    local who edition itype
    if [ "${PC_MODE}" = "interactive" ]; then
        pc_say '\n\033[1;35m▶\033[0m \033[1;36m%s\033[0m\n' "System"
    else
        pc_say '\n▶ %s\n' "System"
    fi
    pc_say '\n    Facts:\n'
    if [ "${SYS_IS_ROOT}" = "yes" ]; then who="root"; else who="${SYS_USER:-unknown} (not root, some checks are skipped)"; fi
    edition="${SYS_EDITION}"
    [ -n "${SYS_EDITION_WHY}" ] && edition="${edition} (${SYS_EDITION_WHY})"
    itype="${SYS_INSTALL_TYPE}"
    if [ "${SYS_INSTALL_TYPE}" = "desktop" ]; then itype="desktop (${PC_DESKTOP_FLAG} exists)"; else itype="server (no ${PC_DESKTOP_FLAG})"; fi
    pc_fact "OS" "${SYS_OS_NAME}"
    pc_fact "Edition" "${edition}"
    pc_fact "Install type" "${itype}"
    pc_fact "Kernel" "${SYS_KERNEL:-unknown}"
    pc_fact "Architecture" "${SYS_ARCH:-unknown}"
    pc_fact "Bash" "${SYS_BASH_VERSION} (running), ${SYS_SYSTEM_BASH_VERSION:-unknown} (${SYS_SYSTEM_BASH:-no bash found})"
    pc_fact "CPUs" "${SYS_CPU}"
    pc_fact "Memory" "${SYS_MEMORY}"
    pc_fact "Disk free" "${SYS_DISK}"
    pc_fact "Virtualisation" "${SYS_VIRT}"
    pc_fact "Hostname" "${SYS_HOSTNAME:-unknown}"
    pc_fact "IP addresses" "${SYS_IPS}"
    pc_fact "SELinux" "${SYS_SELINUX}"
    pc_fact "/usr" "${SYS_USR_STATE}"
    pc_fact "Running as" "${who}"
    pc_fact "PodShift" "${SYS_PODSHIFT_VERSION:-not installed}"
    pc_fact "Podman" "${SYS_PODMAN_VERSION:-not installed}"
    pc_fact "PodShift Copr" "$([ "${SYS_COPR_ENABLED}" = "yes" ] && echo enabled || echo 'not enabled')"
}

# ---------- phase 3: validate ----------

# @description: Reads versions on stdin and prints the newest.
# @details:
#   Lines that do not start with a digit are skipped.
# @stdout: the newest version, without a trailing newline, or nothing.
# @exitcode: 0 always.
pc_newest_of() {
    local v best
    best=""
    while read -r v; do
        case "${v}" in [0-9]*) ;; *) continue ;; esac
        if [ -z "${best}" ] || ! pc_ver_ge "${best}" "${v}"; then best="${v}"; fi
    done
    printf '%s' "${best}"
}

# @description: Prints the newest version dnf offers for a package.
# @arg: $1 - the package name.
# @arg: $2 - optional repository ID to limit the query to.
# @stdout: the version and release, or nothing when dnf gives no answer.
# @exitcode: 1 if dnf is missing, 0 otherwise.
pc_dnf_newest() {
    local repo_args
    pc_has dnf || return 1
    repo_args=""
    [ -n "${2:-}" ] && repo_args="--repo=$2"
    # shellcheck disable=SC2086
    LC_ALL=C pc_run 180 dnf repoquery --quiet --latest-limit=1 --queryformat='%{version}-%{release}\n' ${repo_args} "$1" 2>/dev/null \
        | pc_newest_of
}

# @description: Runs the Checking OS section: Bash, Fedora, the Fedora version and the edition or install type.
# @stdout: the section with its check lines and Verdict, or nothing in JSON mode.
# @exitcode: 0 if there is no blocker, 1 on a blocker.
pc_check_os() {
    local reason
    pc_section "Checking OS"
    pc_result ok "Bash can run this check" "Bash ${SYS_BASH_VERSION}"
    if [ "${SYS_OS_ID}" != "fedora" ]; then
        case "${SYS_OS_ID}" in
            rhel | centos | almalinux | rocky | ol)
                reason="PodShift targets Fedora, not RHEL or its rebuilds." ;;
            debian | ubuntu | linuxmint | pop)
                reason="PodShift targets Fedora. Debian and Ubuntu use AppArmor instead of SELinux and ship an older Podman." ;;
            macos)
                reason="This is macOS. PodShift installs on a Fedora server, desktop or VM." ;;
            "")
                reason="/etc/os-release was not found, so the system is unknown." ;;
            *)
                reason="PodShift installs only on Fedora." ;;
        esac
        pc_result block "OS is Fedora" "found ${SYS_OS_NAME}" "${reason}
Why Fedora: ${PC_DOCS}/design-choices.md#fedora-server"
        pc_section_end
        return 1
    fi
    pc_result ok "OS is Fedora"
    case "${SYS_OS_VERSION}" in
        '' | *[!0-9]*)
            pc_result block "Fedora ${PC_MIN_FEDORA} or newer" "version ${SYS_OS_VERSION:-unknown}" "VERSION_ID in /etc/os-release is not a number."
            pc_section_end
            return 1 ;;
    esac
    if [ "${SYS_OS_VERSION}" -lt "${PC_MIN_FEDORA}" ]; then
        pc_result block "Fedora ${PC_MIN_FEDORA} or newer" "found ${SYS_OS_VERSION}" "Upgrade to Fedora ${PC_MIN_FEDORA} or newer first. PodShift needs Podman 6, which comes with Fedora ${PC_MIN_FEDORA}."
        pc_section_end
        return 1
    fi
    pc_result ok "Fedora ${PC_MIN_FEDORA} or newer" "Fedora ${SYS_OS_VERSION}"
    if [ "${SYS_INSTALL_TYPE}" = "desktop" ]; then
        pc_result ok "Install type" "desktop install, ${PC_DESKTOP_FLAG} exists" "PodShift leaves the firewall, fail2ban and SSH login rules as they are."
    elif [ "${SYS_EDITION}" = "desktop" ]; then
        pc_result warn "Edition" "desktop, ${SYS_EDITION_WHY}" "This looks like a multi-purpose desktop machine. A server install hardens the whole machine:
it enables firewalld and fail2ban, sets SSH to key-only login, and opens ports 80, 81, 443, 1022 and 9090.
A dedicated server or VM is recommended. To try PodShift on this computer, create ${PC_DESKTOP_FLAG}
before you install, and the firewall, fail2ban and SSH login rules stay as they are."
    else
        pc_result ok "Edition" "${SYS_EDITION}${SYS_EDITION_WHY:+, ${SYS_EDITION_WHY}}"
    fi
    pc_section_end
}

# @description: Runs the Checking PodShift section and, when PodShift is installed, compares it with the newest version.
# @stdout: the section with its check lines and Verdict, or nothing in JSON mode.
# @exitcode: 0 if PodShift is not installed, 1 if it is, which ends the checks with Installed.
pc_check_podshift() {
    local newest
    pc_section "Checking PodShift"
    if [ -z "${SYS_PODSHIFT_VERSION}" ]; then
        pc_result ok "PodShift is not installed yet"
        pc_section_end
        return 0
    fi
    PC_INSTALLED="yes"
    pc_result info "PodShift is installed" "${SYS_PODSHIFT_VERSION}"
    if [ "${SYS_COPR_ENABLED}" != "yes" ]; then
        pc_result skip "Newest version" "cannot check, the ${PC_COPR} Copr repo is not enabled" "It may have been installed from an RPM file. To update from Copr: sudo dnf copr enable -y ${PC_COPR}"
    else
        newest="$(pc_dnf_newest podshift "${PC_COPR_REPO_ID}")"
        if [ -z "${newest}" ]; then
            pc_result skip "Newest version" "cannot check, dnf could not read the Copr repo"
        elif [ "${newest}" = "${SYS_PODSHIFT_VERSION}" ] || pc_ver_ge "${SYS_PODSHIFT_VERSION}" "${newest}"; then
            pc_result ok "Newest version" "up to date, ${newest} is the newest for Fedora ${SYS_OS_VERSION}"
        else
            pc_result warn "Newest version" "update available: ${newest}" "To update: sudo podshift update-self"
        fi
    fi
    pc_result info "Health of this install" "run: sudo podshift health-check"
    pc_section_end
    return 1
}

# @description: Prints the HTTP status code a URL answers with.
# @arg: $1 - the URL.
# @stdout: the HTTP code, 000 when there is no answer.
# @exitcode: 0 always.
pc_url_code() {
    LC_ALL=C pc_run 15 curl -sS -o /dev/null --max-time 10 -w '%{http_code}' "$1" 2>/dev/null || true
}

# @description: Runs a dnf dry run of PodShift's packages as root and records the result.
# @details:
#   Without root the check is recorded as skipped. The package list is PC_REQUIRES, plus
#   podshift when the Copr repo is enabled. dnf runs with --assumeno, so nothing is installed.
# @stdout: the check line, or nothing in JSON mode.
# @exitcode: 0 if the packages resolve, the check is skipped or the result is unclear, 1 on a blocker.
pc_check_dry_run() {
    local pkgs out rc problems
    if [ "${SYS_IS_ROOT}" != "yes" ]; then
        pc_result skip "dnf dry run of PodShift's packages" "needs root, run with sudo for this check"
        return 0
    fi
    if ! pc_has dnf; then
        pc_result block "dnf dry run of PodShift's packages" "dnf not found"
        return 1
    fi
    pkgs="${PC_REQUIRES}"
    [ "${SYS_COPR_ENABLED}" = "yes" ] && pkgs="${pkgs} podshift"
    # shellcheck disable=SC2086
    out="$(LC_ALL=C pc_run 300 dnf install --assumeno ${pkgs} 2>&1)"
    rc=$?
    problems="$(printf '%s\n' "${out}" | grep -E -i 'problem|no match for argument|conflict|failed to resolve|nothing provides|^error' | head -n 15)"
    if [ -n "${problems}" ]; then
        pc_result block "dnf dry run of PodShift's packages" "dnf cannot resolve them" "${problems}"
        return 1
    fi
    if printf '%s\n' "${out}" | grep -q -i -E 'transaction summary|nothing to do|operation aborted|is this ok'; then
        pc_result ok "dnf dry run of PodShift's packages" "all packages can be installed"
        return 0
    fi
    pc_result warn "dnf dry run of PodShift's packages" "unclear result (exit ${rc})" "$(printf '%s\n' "${out}" | tail -n 5)"
    return 0
}

# @description: Runs the Checking packages section: /usr, root, repositories, Copr, Podman, Bash and the dry run.
# @stdout: the section with its check lines and Verdict, or nothing in JSON mode.
# @exitcode: 0 if there is no blocker, 1 on a blocker.
pc_check_packages() {
    local code bad candidate
    pc_section "Checking packages"
    case "${SYS_USR_STATE}" in
        read-only*image*)
            pc_result block "System can install packages" "image-based system, /run/ostree-booted exists" "Fedora CoreOS, Atomic desktops and image-based (bootc) Fedora keep /usr read-only.
PodShift does not target these. See ${PC_DOCS}/design-choices.md#fedora-server"
            pc_section_end
            return 1 ;;
        read-only*)
            pc_result block "System can install packages" "/usr is ${SYS_USR_STATE}"
            pc_section_end
            return 1 ;;
        unknown)
            pc_result warn "System can install packages" "could not tell if /usr is writable" ;;
        *)
            pc_result ok "System can install packages" "/usr is writable" ;;
    esac
    if [ "${SYS_IS_ROOT}" = "yes" ]; then
        pc_result ok "Running as root"
    else
        pc_result skip "Running as root" "no, the install needs sudo; run this check with sudo for the dnf dry run"
    fi
    if pc_has curl; then
        bad=""
        code="$(pc_url_code https://mirrors.fedoraproject.org/)"
        [ "${code:-000}" = "000" ] && bad="mirrors.fedoraproject.org"
        code="$(pc_url_code https://download.copr.fedorainfracloud.org/)"
        [ "${code:-000}" = "000" ] && bad="${bad:+${bad}, }download.copr.fedorainfracloud.org"
        if [ -n "${bad}" ]; then
            pc_result warn "Repositories can be reached" "no answer from ${bad}" "dnf needs these to install PodShift. Check the network, DNS or proxy settings."
        else
            pc_result ok "Repositories can be reached" "Fedora mirrors and Copr"
        fi
    else
        pc_result skip "Repositories can be reached" "curl not found"
    fi
    if [ "${SYS_COPR_ENABLED}" = "yes" ]; then
        pc_result ok "PodShift Copr repo" "enabled"
    elif pc_has dnf && dnf copr --help >/dev/null 2>&1; then
        pc_result ok "PodShift Copr repo" "not enabled yet, the install command enables it"
    else
        pc_result warn "PodShift Copr repo" "the dnf copr command is missing" "The install command runs: sudo dnf copr enable -y ${PC_COPR}
On Fedora with dnf5 the copr command comes in the dnf5-plugins package."
    fi
    # Podman 6 or newer.
    if [ -n "${SYS_PODMAN_VERSION}" ] && pc_ver_ge "${SYS_PODMAN_VERSION}" "${PC_MIN_PODMAN}"; then
        pc_result ok "Podman ${PC_MIN_PODMAN} or newer" "installed ${SYS_PODMAN_VERSION}"
    elif ! pc_has dnf; then
        pc_result warn "Podman ${PC_MIN_PODMAN} or newer" "cannot check, dnf not found"
    else
        candidate="$(pc_dnf_newest podman)"
        if [ -z "${candidate}" ]; then
            pc_result warn "Podman ${PC_MIN_PODMAN} or newer" "cannot check, dnf gave no Podman version" "dnf could not read the repositories. Check the network, or run with sudo."
        elif pc_ver_ge "${candidate}" "${PC_MIN_PODMAN}"; then
            pc_result ok "Podman ${PC_MIN_PODMAN} or newer" "dnf offers ${candidate}${SYS_PODMAN_VERSION:+, installed ${SYS_PODMAN_VERSION}}"
        else
            pc_result block "Podman ${PC_MIN_PODMAN} or newer" "newest dnf offers is ${candidate}" "PodShift needs Podman ${PC_MIN_PODMAN} or newer."
            pc_section_end
            return 1
        fi
    fi
    # Bash for PodShift's own scripts.
    if [ -z "${SYS_SYSTEM_BASH_VERSION}" ]; then
        pc_result warn "Bash ${PC_MIN_BASH} or newer for PodShift" "could not read the version of ${SYS_SYSTEM_BASH:-bash}"
    elif pc_ver_ge "${SYS_SYSTEM_BASH_VERSION}" "${PC_MIN_BASH}"; then
        pc_result ok "Bash ${PC_MIN_BASH} or newer for PodShift" "${SYS_SYSTEM_BASH_VERSION}"
    else
        pc_result block "Bash ${PC_MIN_BASH} or newer for PodShift" "found ${SYS_SYSTEM_BASH_VERSION}" "PodShift's scripts need Bash ${PC_MIN_BASH} or newer (${SYS_SYSTEM_BASH})."
        pc_section_end
        return 1
    fi
    if ! pc_check_dry_run; then
        pc_section_end
        return 1
    fi
    pc_section_end
}

# @description: Prints the TCP ports from PC_PORTS that something already listens on.
# @stdout: the ports in use, space separated, or nothing.
# @exitcode: 1 if ss is missing, 0 otherwise.
pc_ports_in_use() {
    local port listening used
    pc_has ss || return 1
    listening="$(ss -tln 2>/dev/null | awk 'NR > 1 { n = split($4, a, ":"); print a[n] }' | sort -u)"
    used=""
    for port in ${PC_PORTS}; do
        if printf '%s\n' "${listening}" | grep -qx "${port}"; then
            used="${used:+${used} }${port}"
        fi
    done
    printf '%s' "${used}"
}

# @description: Runs the Checking security and clashes section: SELinux, Docker, ports, users, UID and SSH key.
# @stdout: the section with its check lines and Verdict, or nothing in JSON mode.
# @exitcode: 0 always, since this section only gives warnings.
pc_check_clashes() {
    local docker ports users n name home user who
    pc_section "Checking security and clashes"
    case "${SYS_SELINUX}" in
        enforcing) pc_result ok "SELinux is enforcing" ;;
        permissive)
            if [ "${SYS_INSTALL_TYPE}" = "desktop" ]; then
                pc_result warn "SELinux is not enforcing" "permissive" "PodShift relies on SELinux to keep containers apart from the server and from each other.
Fedora has it enforcing by default.
After installing, run sudo podshift selinux enforce to switch it on."
            else
                pc_result warn "SELinux is not enforcing" "permissive" "PodShift relies on SELinux to keep containers apart from the server and from each other.
Fedora has it enforcing by default.
The PodShift install switches it to enforcing."
            fi
            ;;
        *)
            pc_result warn "SELinux is not enforcing" "${SYS_SELINUX}" "PodShift relies on SELinux to keep containers apart from the server and from each other.
Fedora has it enforcing by default.
After installing, sudo podshift selinux enforce prints the steps to turn it back on."
            ;;
    esac
    docker=""
    if pc_has rpm; then
        for name in docker-ce moby-engine; do
            rpm -q "${name}" >/dev/null 2>&1 && docker="${docker:+${docker}, }${name} installed"
        done
    fi
    if pc_has systemctl && systemctl is-active --quiet docker 2>/dev/null; then
        docker="${docker:+${docker}, }docker service running"
    fi
    if [ -n "${docker}" ]; then
        pc_result warn "No Docker" "${docker}" "Docker and PodShift's Podman can fight over ports and firewall rules. A machine for PodShift alone is recommended."
    else
        pc_result ok "No Docker"
    fi
    if ports="$(pc_ports_in_use)"; then
        if [ -n "${ports}" ]; then
            pc_result warn "PodShift's ports are free" "in use: ${ports}" "PodShift uses 80 (HTTP), 81 (proxy), 443 (HTTPS) and 1022 (SSH). Something already listens on ${ports}."
        else
            pc_result ok "PodShift's ports are free" "${PC_PORTS}"
        fi
    else
        pc_result skip "PodShift's ports are free" "ss not found"
    fi
    users="$(awk -F: '$3 >= 1000 && $3 < 60000 && $7 !~ /(nologin|false)$/ { print $1 }' "$(pc_path /etc/passwd)" 2>/dev/null | tr '\n' ' ')"
    n=0
    for name in ${users}; do n=$((n + 1)); done
    if [ "${n}" -gt 1 ]; then
        pc_result warn "One person uses this machine" "${n} login users: ${users% }" "Several people log in here, so it looks like a shared machine. A dedicated server or VM is recommended."
    else
        pc_result ok "One person uses this machine" "${n} login user${users:+: ${users% }}"
    fi
    who="$(awk -F: -v id="${PC_USER_UID}" '$3 == id && $1 != "podshift" { print $1 }' "$(pc_path /etc/passwd)" 2>/dev/null | head -n 1)"
    if [ -n "${who}" ]; then
        pc_result warn "UID ${PC_USER_UID} is free for the podshift user" "used by ${who}" "PodShift creates its podshift user with UID and GID ${PC_USER_UID}."
    else
        pc_result ok "UID ${PC_USER_UID} is free for the podshift user"
    fi
    # Server installs set SSH to key-only login (50-podshift-auth.conf).
    if [ "${SYS_INSTALL_TYPE}" = "server" ]; then
        user="${SUDO_USER:-${SYS_USER}}"
        home="$(awk -F: -v u="${user}" '$1 == u { print $6 }' "$(pc_path /etc/passwd)" 2>/dev/null)"
        if [ -z "${home}" ]; then
            pc_result skip "SSH key for ${user:-this user}" "home folder not found"
        elif [ -s "$(pc_path "${home}/.ssh/authorized_keys")" ]; then
            pc_result ok "SSH key for ${user}" "${home}/.ssh/authorized_keys"
        elif [ -n "${PC_ROOT}" ] || [ "${SYS_IS_ROOT}" = "yes" ] || [ "${user}" = "${SYS_USER}" ]; then
            pc_result warn "SSH key for ${user}" "no ${home}/.ssh/authorized_keys" "A server install sets SSH to key-only login. Add your SSH key before you install,
or password logins over SSH stop working."
        fi
    fi
    pc_section_end
}

# ---------- verdict ----------

# @description: Works out the final result code from the recorded checks.
# @stdout: 3 if PodShift is installed, 2 on a blocker, 1 on a warning, 0 otherwise.
# @exitcode: 0 always.
pc_result_code() {
    local i
    [ "${PC_INSTALLED}" = "yes" ] && { echo 3; return; }
    i=0
    while [ "${i}" -lt "${PC_N}" ]; do
        [ "${PC_R_STATUS[i]}" = "block" ] && { echo 2; return; }
        i=$((i + 1))
    done
    i=0
    while [ "${i}" -lt "${PC_N}" ]; do
        [ "${PC_R_STATUS[i]}" = "warn" ] && { echo 1; return; }
        i=$((i + 1))
    done
    echo 0
}

# @description: Prints the result name for a result code.
# @arg: $1 - the result code, 0 to 3.
# @stdout: Ready, Ready with warnings, Not possible or Installed.
# @exitcode: 0 always.
pc_result_text() {
    case "$1" in
        0) echo "Ready" ;;
        1) echo "Ready with warnings" ;;
        2) echo "Not possible" ;;
        3) echo "Installed" ;;
    esac
}

# @description: Prints the Summary block with one row per planned section and the final result.
# @arg: $1 - the result code, 0 to 3.
# @stdout: the Summary block, or nothing in JSON mode.
# @exitcode: 0 always.
pc_summary() {
    local rc color text i title found status icon row width line problem msg
    rc="$1"
    case "${rc}" in
        0) color=32; msg="PodShift can be installed here." ;;
        1) color=33; msg="PodShift can be installed here. Read the warnings above first." ;;
        2) color=31; msg="PodShift cannot be installed here. Fix the blocker above and run this check again." ;;
        3) color=36; msg="PodShift is already installed." ;;
    esac
    text="$(pc_result_text "${rc}")"
    if [ "${PC_MODE}" = "interactive" ]; then
        pc_say '\n\033[1;%sm◆\033[0m \033[1mSummary\033[0m\n\n' "${color}"
    else
        pc_say '\n◆ Summary\n\n'
    fi
    width=0
    for title in $(printf '%s' "${PC_SECTIONS_PLANNED}" | tr ' |' '_ '); do
        [ "${#title}" -gt "${width}" ] && width=${#title}
    done
    for title in $(printf '%s' "${PC_SECTIONS_PLANNED}" | tr ' |' '_ '); do
        title="${title//_/ }"
        found=""
        i=0
        while [ "${i}" -lt "${PC_S_N}" ]; do
            [ "${PC_S_TITLE[i]}" = "${title}" ] && found="${i}"
            i=$((i + 1))
        done
        problem=""
        if [ -z "${found}" ]; then
            status="skip"; row="not run"
        else
            status="${PC_S_STATUS[found]}"
            problem="${PC_S_PROBLEM[found]}"
            case "${status}" in
                ok) row="passed" ;;
                warn) row="warnings" ;;
                block) row="blocked" ;;
            esac
            if [ "${title}" = "Checking PodShift" ] && [ "${PC_INSTALLED}" = "yes" ]; then
                status="info"; row="installed ${SYS_PODSHIFT_VERSION}"
            fi
        fi
        icon="$(pc_icon "${status}")"
        line="$(printf '    %s %-*s   %s' "${icon}" "${width}" "${title}" "${row}")"
        if [ -n "${problem}" ]; then
            pc_say '%s%*s %s\n' "${line}" $((10 - ${#row})) "" "${problem}"
        else
            pc_say '%s\n' "${line}"
        fi
    done
    if [ "${PC_MODE}" = "interactive" ]; then
        pc_say '\n    Result: \033[1;%sm%s\033[0m (exit %s)\n' "${color}" "${text}" "${rc}"
    else
        pc_say '\n    Result: %s (exit %s)\n' "${text}" "${rc}"
    fi
    pc_say '        %s\n' "${msg}"
    if [ "${PC_SKIPPED}" -gt 0 ] && [ "${rc}" != "2" ] && [ "${rc}" != "3" ]; then
        pc_say '        %s check(s) skipped. Run with sudo for the full check.\n' "${PC_SKIPPED}"
    fi
}

# @description: Prints the result, the system facts and every check as JSON.
# @arg: $1 - the result code, 0 to 3.
# @stdout: the JSON document.
# @exitcode: 0 always.
pc_print_json() {
    local rc i sep
    rc="$1"
    printf '{\n  "tool": "podshift-precheck",\n  "version": %s,\n' "$(pc_json_str "${PC_VERSION}")"
    printf '  "result": %s,\n  "exit_code": %s,\n  "as_root": %s,\n  "skipped": %s,\n' \
        "$(pc_json_str "$(pc_result_text "${rc}")")" "${rc}" \
        "$([ "${SYS_IS_ROOT}" = "yes" ] && echo true || echo false)" "${PC_SKIPPED}"
    printf '  "system": {\n'
    printf '    "os_id": %s,\n' "$(pc_json_str "${SYS_OS_ID}")"
    printf '    "os_name": %s,\n' "$(pc_json_str "${SYS_OS_NAME}")"
    printf '    "os_version": %s,\n' "$(pc_json_str "${SYS_OS_VERSION}")"
    printf '    "os_variant_id": %s,\n' "$(pc_json_str "${SYS_OS_VARIANT_ID}")"
    printf '    "edition": %s,\n' "$(pc_json_str "${SYS_EDITION}")"
    printf '    "install_type": %s,\n' "$(pc_json_str "${SYS_INSTALL_TYPE}")"
    printf '    "kernel": %s,\n' "$(pc_json_str "${SYS_KERNEL}")"
    printf '    "arch": %s,\n' "$(pc_json_str "${SYS_ARCH}")"
    printf '    "bash_running": %s,\n' "$(pc_json_str "${SYS_BASH_VERSION}")"
    printf '    "bash_system": %s,\n' "$(pc_json_str "${SYS_SYSTEM_BASH_VERSION}")"
    printf '    "cpus": %s,\n' "$(pc_json_str "${SYS_CPU}")"
    printf '    "memory": %s,\n' "$(pc_json_str "${SYS_MEMORY}")"
    printf '    "disk_free": %s,\n' "$(pc_json_str "${SYS_DISK}")"
    printf '    "virtualisation": %s,\n' "$(pc_json_str "${SYS_VIRT}")"
    printf '    "hostname": %s,\n' "$(pc_json_str "${SYS_HOSTNAME}")"
    printf '    "ip_addresses": %s,\n' "$(pc_json_str "${SYS_IPS}")"
    printf '    "selinux": %s,\n' "$(pc_json_str "${SYS_SELINUX}")"
    printf '    "usr": %s,\n' "$(pc_json_str "${SYS_USR_STATE}")"
    printf '    "podshift_version": %s,\n' "$(pc_json_str "${SYS_PODSHIFT_VERSION}")"
    printf '    "podman_version": %s,\n' "$(pc_json_str "${SYS_PODMAN_VERSION}")"
    printf '    "copr_enabled": %s\n' "$([ "${SYS_COPR_ENABLED}" = "yes" ] && echo true || echo false)"
    printf '  },\n  "checks": ['
    sep=""
    i=0
    while [ "${i}" -lt "${PC_N}" ]; do
        printf '%s\n    {"section": %s, "status": %s, "name": %s, "note": %s, "detail": %s}' "${sep}" \
            "$(pc_json_str "${PC_R_SECTION[i]}")" "$(pc_json_str "${PC_R_STATUS[i]}")" \
            "$(pc_json_str "${PC_R_NAME[i]}")" "$(pc_json_str "${PC_R_NOTE[i]}")" \
            "$(pc_json_str "${PC_R_DETAIL[i]}")"
        sep=","
        i=$((i + 1))
    done
    printf '\n  ]\n}\n'
}

# ---------- main ----------

# @description: Prints the help text.
# @stdout: the usage, options and exit codes.
# @exitcode: 0 always.
pc_help() {
    cat <<'HELP'
PodShift precheck: can PodShift be installed on this machine?

Usage:
  curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | bash
  curl -fsSL https://raw.githubusercontent.com/vellamo-dev/podshift/stable/utils/portable/precheck.sh | sudo bash
  bash precheck.sh [--plain] [--json] [--help]

Options:
  --plain   No colours. This is automatic when the output is not a terminal or NO_COLOR is set.
  --json    Print only a JSON result, for scripts.
  --help    Show this help.

Exit codes:
  0 Ready, 1 Ready with warnings, 2 Not possible, 3 Installed, 4 wrong option.

It only reads. It never installs anything, enables a repository or writes a file.
With sudo it also asks dnf for a dry run of PodShift's packages.
HELP
}

# @description: Reads the options, gathers the facts, runs the sections in order and prints the result.
# @arg: $1 - optional options: --plain, --json or --help (-h), in any number.
# @stdout: the report, or the JSON result with --json, or the help text with --help.
# @stderr: a message for an unknown option or a Bash older than 3.2.
# @exitcode: 0 Ready, 1 Ready with warnings, 2 Not possible, 3 Installed, 4 unknown option.
main() {
    local arg plain rc
    pc_init
    plain="no"
    for arg in "$@"; do
        case "${arg}" in
            --plain) plain="yes" ;;
            --json) PC_JSON="yes" ;;
            --help | -h) pc_help; return 0 ;;
            *) echo "precheck: unknown option: ${arg}. See --help." >&2; return 4 ;;
        esac
    done
    if [ "${BASH_VERSINFO[0]}" -lt 3 ] || { [ "${BASH_VERSINFO[0]}" -eq 3 ] && [ "${BASH_VERSINFO[1]}" -lt 2 ]; }; then
        echo "precheck: Bash ${BASH_VERSION} is too old. This check needs Bash ${PC_SELF_MIN_BASH} or newer." >&2
        echo "Result: Not possible (exit 2)" >&2
        return 2
    fi
    if [ "${plain}" = "no" ] && [ -t 1 ] && [ -z "${NO_COLOR+set}" ] && [ -n "${TERM:-}" ] && [ "${TERM:-}" != "dumb" ]; then
        PC_MODE="interactive"
    fi
    pc_has timeout && PC_TIMEOUT="yes"
    pc_gather
    pc_say 'PodShift precheck %s\n' "${PC_VERSION}"
    pc_show_system
    if pc_check_os && pc_check_podshift; then
        pc_check_packages && pc_check_clashes
    fi
    rc="$(pc_result_code)"
    pc_summary "${rc}"
    [ "${PC_JSON}" = "yes" ] && pc_print_json "${rc}"
    return "${rc}"
}

main "$@"
