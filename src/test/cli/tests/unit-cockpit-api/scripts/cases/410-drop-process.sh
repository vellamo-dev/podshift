#!/usr/bin/env bash
# @file: 410-drop-process.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: log-drop-history, drop-process drop IDs and the drop handler runs.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# log-drop-history: the Description of a Quadlet file is added, a .zip is not read, an unknown status
# or a missing or invalid drop ID logs nothing.
# shellcheck source=/dev/null
source "${PODSHIFT}/fn/quadlet/log-drop-history.sh"
: > "${drop_log}"
drop_id="018bcfe5-6800-7012-b456-789abcdef012"
log-drop-history "${drop_id}" web.container installing "" "${drop_in}/web.container"
log-drop-history "${drop_id}" shop.zip validated "" "${drop_in}/shop.zip"
log-drop-history "${drop_id}" web.container done
log-drop-history "" web.container installed
log-drop-history not-an-id web.container installed
if [[ "$(cat "${drop_log}")" == '-t podshift-drop-history -p info {"id":"018bcfe5-6800-7012-b456-789abcdef012","name":"web.container","status":"installing","description":"Web test"}
-t podshift-drop-history -p info {"id":"018bcfe5-6800-7012-b456-789abcdef012","name":"shop.zip","status":"validated"}' ]]; then
    ok "log-drop-history"
else
    bad "log-drop-history" "$(cat "${drop_log}")"
fi
unset -f load-podshift-conf-main logger cockpit-quadlet-drop-file-meta
rm -rf "${drop_root}" "${drop_log}" "${WORK}/meta.file"

# drop-process: every item gets a new drop ID. A Quadlet file gets the ID line as line 1 (an older
# one is replaced), a zip gets the ID after .zip in its queued name, and a refused item is logged
# with its own ID. stat -c is mapped to BSD stat on a Mac and logger is stubbed.
# shellcheck source=/dev/null
source "${PODSHIFT}/fn/service/drop-process.sh" || true
dp_root="${WORK}/drop-process-case"
dp_log="${WORK}/drop-process.log"
dp_re='^[0-9a-f]{8}-[0-9a-f]{4}-7[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$'
mkdir -p "${dp_root}/drop" "${dp_root}/queue" "${dp_root}/trash"
: > "${dp_log}"
load-podshift-conf-main() {
    PODSHIFT_DROP_DIR="${dp_root}/drop"
    PODSHIFT_TRASH_DIR="${dp_root}/trash"
    PODSHIFT_QUADLET_VALIDATION_QUEUE_DIR="${dp_root}/queue"
    PODSHIFT_DROP_MAX_BUNDLE_SIZE=50
    PODSHIFT_DROP_QUADLET_EXTENSIONS=".container,.volume,.network,.image"
    PODSHIFT_DROP_SETTLE=0
}
logger() { printf '%s\n' "$*" >> "${dp_log}"; }
stat() {
    local fmt
    if [[ "${1-}" == "-c" ]]; then
        # Skip --, or BSD stat with no file reads stdin, whose time is often a second ahead.
        fmt="${2}"
        shift 2
        [[ "${1-}" == "--" ]] && shift
        command stat -c "${fmt}" -- "$@" 2>/dev/null && return 0
        case "${fmt}" in
            %Y) command stat -f %m -- "$@" ;;
            %s) command stat -f %z -- "$@" ;;
        esac
        return
    fi
    command stat "$@"
}
printf '# podshift-drop-id: 018bcfe5-6800-7000-8000-000000000000\n[Container]\nImage=x\n' > "${dp_root}/drop/web.container"
printf 'zip' > "${dp_root}/drop/shop.zip"
printf 'x' > "${dp_root}/drop/notes.txt"
podshift-drop-process
dp_stat_stub="$(declare -f stat)"
unset -f stat
dp_id_web="$(sed -n 's/^# podshift-drop-id: //p' "${dp_root}/queue/web.container")"
dp_zip="$(find "${dp_root}/queue" -name 'shop.zip.*' -exec basename {} \;)"
dp_ids="$(sed -n 's/^-t podshift-drop-history -p info //p' "${dp_log}" | jq -r '.id + " " + .name + " " + .status')"
if [[ "$(sed -n 1p "${dp_root}/queue/web.container")" == "# podshift-drop-id: ${dp_id_web}" ]] \
    && [[ "$(grep -c 'podshift-drop-id' "${dp_root}/queue/web.container")" == "1" ]] \
    && grep -Eq "${dp_re}" <<< "${dp_id_web}" \
    && [[ "${dp_id_web}" != "018bcfe5-6800-7000-8000-000000000000" ]] \
    && [[ "$(drop_mode "${dp_root}/queue/web.container")" == "644" ]] \
    && grep -Eq "${dp_re}" <<< "${dp_zip#shop.zip.}" \
    && [[ "$(cat "${dp_root}/queue/${dp_zip}")" == "zip" ]] \
    && [[ -f "${dp_root}/trash/notes.txt" ]] \
    && [[ -z "$(find "${dp_root}/drop" "${dp_root}/queue" -name '.drop-id.*')" ]] \
    && grep -qx "${dp_id_web} web.container accepted" <<< "${dp_ids}" \
    && grep -qx "${dp_zip#shop.zip.} shop.zip accepted" <<< "${dp_ids}" \
    && [[ "$(grep -c ' notes.txt refused$' <<< "${dp_ids}")" == "1" ]] \
    && [[ "$(cut -d ' ' -f 1 <<< "${dp_ids}" | sort -u | wc -l | tr -d '[:space:]')" == "3" ]]; then
    ok "drop-process-drop-id"
else
    bad "drop-process-drop-id" "${dp_ids} queue $(ls -a "${dp_root}/queue") log $(cat "${dp_log}")"
fi

# drop-process: a file whose time is in the future is skipped and gets the time now, so it is not
# held back until the clock catches up; the next run takes it.
eval "${dp_stat_stub}"
rm -rf "${dp_root}/drop" "${dp_root}/queue" "${dp_root}/trash"
mkdir -p "${dp_root}/drop" "${dp_root}/queue" "${dp_root}/trash"
: > "${dp_log}"
printf '[Container]\nImage=x\n' > "${dp_root}/drop/late.container"
touch -t 209901010000 "${dp_root}/drop/late.container"
podshift-drop-process
dp_late_mtime="$(stat -c %Y -- "${dp_root}/drop/late.container")"
dp_late_first="$(ls -A "${dp_root}/queue" "${dp_root}/trash")"
podshift-drop-process
unset -f stat
if [[ "${dp_late_first}" == "$(printf '%s:\n\n%s:' "${dp_root}/queue" "${dp_root}/trash")" ]] \
    && (( ${dp_late_mtime:-9999999999} <= $(date +%s) )) \
    && grep -q "skipping late.container, its time was in the future and is reset to now" "${dp_log}" \
    && [[ -f "${dp_root}/queue/late.container" ]]; then
    ok "drop-process-future-time"
else
    bad "drop-process-future-time" "mtime ${dp_late_mtime} first ${dp_late_first} queue $(ls -a "${dp_root}/queue") log $(cat "${dp_log}")"
fi
unset -f load-podshift-conf-main logger
rm -rf "${dp_root}" "${dp_log}"

# Handler runs: bad arguments never reach the session; quadlet-drop may send more than 65536 bytes,
# up to 131072; other actions keep 65536.
drop_n=0
for drop_body in \
    '{"apiVersion":1,"action":"quadlet-drop","args":{"name":"a.zip"}}' \
    '{"apiVersion":1,"action":"quadlet-drop","args":{"name":"a.zip","content":"QUJD","extra":1}}' \
    '{"apiVersion":1,"action":"quadlet-drop","args":{"name":"a.zip","content":"ab$="}}' \
    '{"apiVersion":1,"action":"quadlet-drop","args":{"name":"","content":"QUJD"}}' \
    '{"apiVersion":1,"action":"quadlet-drop-history","args":{"max":5}}' \
    '{"apiVersion":1,"action":"quadlet-install-log","args":{"all":true}}'; do
    drop_n=$((drop_n + 1))
    reset_mocks
    MODE="emit"
    EMIT='{"name":"a.zip","ok":true}'
    run_serve "${drop_body}"
    if expect_code "quadlet-drop-handler-invalid-args-${drop_n}" "INVALID_ARGS"; then
        if [[ ! -s "${ARGV}" && "$(field '.request.args')" == "null" ]]; then
            ok "quadlet-drop-handler-invalid-args-${drop_n}"
        else
            bad "quadlet-drop-handler-invalid-args-${drop_n}" "argv $(head -c 300 "${ARGV}")"
        fi
    fi
done
reset_mocks
MODE="emit"
EMIT='{"name":"a.zip","ok":true}'
run_serve "{\"apiVersion\":1,\"action\":\"quadlet-drop\",\"args\":{\"name\":\"a.zip\",\"content\":\"$(printf 'A%.0s' $(seq 1 68269) | head -c 68268)\"}}"
if expect_code "quadlet-drop-request-over-65536" "OK"; then
    if [[ "$(field '.data.ok')" == "true" ]] && grep -q 'cockpit-run-in-session.sh quadlet-drop ' "${ARGV}"; then
        ok "quadlet-drop-request-over-65536"
    else
        bad "quadlet-drop-request-over-65536" "$(head -c 300 "${ARGV}")"
    fi
fi
reset_mocks
MODE="emit"
EMIT='{"name":"a.zip","ok":true}'
run_serve "{\"apiVersion\":1,\"action\":\"quadlet-drop\",\"args\":{\"name\":\"a.zip\",\"content\":\"$(dd if=/dev/zero bs=131072 count=1 2>/dev/null | tr '\0' 'A')\"}}"
expect_code "quadlet-drop-request-over-131072" "INVALID_REQUEST" && [[ ! -s "${ARGV}" ]] && ok "quadlet-drop-request-over-131072"
reset_mocks
MODE="emit"
EMIT='{"key":"TSV_APP","ok":true}'
run_serve "{\"apiVersion\":1,\"action\":\"config-set\",\"args\":{\"key\":\"TSV_APP\",\"value\":\"$(dd if=/dev/zero bs=70000 count=1 2>/dev/null | tr '\0' 'x')\"}}"
if expect_code "config-set-request-over-65536" "INVALID_REQUEST" && [[ ! -s "${ARGV}" && "$(field '.request')" == "null" ]]; then
    ok "config-set-request-over-65536"
fi

