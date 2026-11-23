#!/usr/bin/env bash
# @file: 150-quadlets-list.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: quadlets-list with podman stubbed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# quadlets-list: podman is stubbed.
qls_calls="${WORK}/quadlets.calls"
: > "${qls_calls}"
cockpit-quadlets-list-podman() {
    printf '%s\n' "${*}" >> "${qls_calls}"
    case "$*" in
        "quadlet ls --format json")
            cat "${repo}/src/test/unit/fixtures/cockpit-quadlets/ls-ok.json"
            ;;
        *)
            return 1
            ;;
    esac
}
qls_out="$(cockpit-module-quadlets-list)"
if printf '%s' "${qls_out}" | jq -e '
    (.items | length) == 8
    and .items[0].id == "backup.kube" and .items[0].type == "kube"
    and .items[4].id == "shop-api.container" and .items[4].title == "shop-api" and .items[4].app == "shop" and .items[4].pod == "shop.pod"
    and .items[6].id == "web.container" and .items[6].unitName == "web.service" and .items[6].status == "active/running"
    and ([.items[].description] | all(. == ""))
' >/dev/null && grep -qx "quadlet ls --format json" "${qls_calls}"; then
    ok "quadlets-list-stubbed"
else
    bad "quadlets-list-stubbed" "${qls_out}"
fi

: > "${qls_calls}"
cockpit-quadlets-list-podman() {
    printf '%s\n' "${*}" >> "${qls_calls}"
    printf '[]\n'
}
qls_out="$(cockpit-module-quadlets-list)"
expect_eq "quadlets-list-empty" "${qls_out}" '{"items":[]}'

cockpit-quadlets-list-podman() {
    printf 'null\n'
}
qls_out="$(cockpit-module-quadlets-list)"
expect_eq "quadlets-list-null" "${qls_out}" '{"items":[]}'

cockpit-quadlets-list-podman() {
    :
}
qls_out="$(cockpit-module-quadlets-list)"
expect_eq "quadlets-list-blank" "${qls_out}" '{"items":[]}'

cockpit-quadlets-list-podman() {
    return 1
}
if qls_out="$(cockpit-module-quadlets-list 2>/dev/null)"; then
    bad "quadlets-list-podman-fails" "${qls_out}"
else
    ok "quadlets-list-podman-fails"
fi

cockpit-quadlets-list-podman() {
    printf 'Error: unrecognized command `quadlet`\n' >&2
    return 125
}
if qls_out="$(cockpit-module-quadlets-list 2>/dev/null)"; then
    bad "quadlets-list-unsupported" "${qls_out}"
else
    ok "quadlets-list-unsupported"
fi


