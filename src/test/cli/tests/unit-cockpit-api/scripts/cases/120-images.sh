#!/usr/bin/env bash
# @file: 120-images.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: images-list with podman and systemctl stubbed.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# images-list: podman and systemctl are stubbed; Quadlet .image and .container files are real files.
img_home="${WORK}/images-home"
mkdir -p "${img_home}/quadlets/shop.qdl-bundle"
printf '[Image]\nImage=docker.io/library/busybox:latest\n' > "${img_home}/quadlets/shop.qdl-bundle/cache.image"
printf '[Image]\nImage=quay.io/missing/image\n' > "${img_home}/quadlets/missing.image"
printf '[Container]\nImage=docker.io/library/nginx:1.27\n' > "${img_home}/quadlets/shop.qdl-bundle/web.container"
cockpit-images-list-podman() {
    case "${1-} ${2-}" in
        "image ls")
            printf '%s\n' '[{"Id":"e1c50b84a672c4e6a8c0"},{"Id":"9f1c3e28b4d1a3c5e7f9"},{"Id":"abbc135a7d39c0e8a2fd"},{"Id":"abbc135a7d39c0e8a2fd"},{"Id":"0123456789ab01234567"}]'
            ;;
        "image inspect")
            printf '%s\n' '[
                {"Id":"0123456789ab01234567","RepoTags":[],"Created":"2026-11-10T09:00:00Z","Architecture":"amd64","Os":"linux","Size":512},
                {"Id":"9f1c3e28b4d1a3c5e7f9","RepoTags":["docker.io/library/nginx:1.27"],"Digest":"sha256:c8e4d91a07b2d4f6a8c0","Created":"2026-10-20T08:30:00Z","Config":{"Cmd":["nginx"]},"Architecture":"amd64","Os":"linux","Size":61900000},
                {"Id":"abbc135a7d39c0e8a2fd","RepoTags":["docker.io/library/alpine:latest","docker.io/library/alpine:3.20"],"Created":"2026-11-05T12:12:00+02:00","Config":{"Cmd":["/bin/sh"]},"Architecture":"amd64","Os":"linux","Size":8950000},
                {"Id":"e1c50b84a672c4e6a8c0","RepoTags":["docker.io/library/busybox:latest"],"Created":"2026-09-14T00:00:00Z","Config":{"Cmd":["sh"]},"Architecture":"arm64","Os":"linux","Size":4430000}
            ]'
            ;;
        "ps -a")
            printf '%s\n' '[
                {"Id":"1a2b3c4d5e6f","Names":["web"],"ImageID":"9f1c3e28b4d1a3c5e7f9","State":"running","Labels":{"PODMAN_SYSTEMD_UNIT":"web.service"}},
                {"Id":"2b3c4d5e6f7a","Names":["loose"],"ImageID":"abbc135a7d39c0e8a2fd","State":"exited","Labels":null}
            ]'
            ;;
        *)
            return 1
            ;;
    esac
}
cockpit-images-list-systemctl() {
    local unit first
    first=1
    while [[ "${1-}" != "--" && $# -gt 0 ]]; do shift; done
    shift
    for unit in "$@"; do
        (( first == 1 )) || printf '\n'
        first=0
        case "${unit}" in
            cache-image.service) printf 'ActiveState=inactive\nFragmentPath=/run/user/300/systemd/generator/cache-image.service\nSourcePath=%s\n' "${img_home}/quadlets/shop.qdl-bundle/cache.image" ;;
            web.service) printf 'ActiveState=active\nFragmentPath=/run/user/300/systemd/generator/web.service\nSourcePath=%s\n' "${img_home}/quadlets/shop.qdl-bundle/web.container" ;;
            *) printf 'ActiveState=inactive\nFragmentPath=\nSourcePath=\n' ;;
        esac
    done
}
images_out="$(HOME="${img_home}" PODSHIFT_PODMAN_QUADLETS_DIR="${img_home}/quadlets" cockpit-module-images-list)"
images_contract="$(jq -c '.output' "${API}/modules/images-list/capability.json")"
if printf '%s' "${images_out}" | jq -e '
    ([.items[].title] == ["<none>","alpine","busybox","nginx"])
    and ((.items[] | select(.title == "alpine") | [.id, .fullId]) == ["abbc135a7d39", "abbc135a7d39c0e8a2fd"])
    and ([.items[] | {(.title): .source}] | add) == {"<none>":"unmanaged","alpine":"unmanaged","busybox":"quadlet","nginx":"container"}
    and ([.items[] | {(.title): .status}] | add) == {"<none>":"Unused","alpine":"In use","busybox":"Unused","nginx":"In use"}
    and ((.items[] | select(.title == "alpine") | [.rows[] | select(.id == "tags" or .id == "created" or .id == "used-by") | .value])
        == ["latest, 3.20","2026-11-05T10:12:00Z","loose (Exited)"])
    and ([.items[] | {(.title): .running}] | add) == {"<none>":false,"alpine":false,"busybox":false,"nginx":true}
    and ((.items[] | select(.title == "nginx") | .rows[] | select(.id == "used-by") | .value) == "web (Running)")
    and ((.items[] | select(.title == "busybox") | .groups[1]) == {"id":"systemd","label":"Systemd","rows":[
        {"id":"unit","label":"Unit name","value":"cache-image.service"},
        {"id":"unit_state","label":"Unit state","value":"inactive"},
        {"id":"file","label":"File","value":"~/quadlets/shop.qdl-bundle/cache.image"},
        {"id":"app","label":"App","value":"shop"}]})
    and ((.items[] | select(.title == "nginx") | .groups[1].rows) == [
        {"id":"unit","label":"Unit name","value":"web.service"},
        {"id":"unit_state","label":"Unit state","value":"active"},
        {"id":"file","label":"File","value":"~/quadlets/shop.qdl-bundle/web.container"},
        {"id":"app","label":"App","value":"shop"}])
' >/dev/null && cockpit-validate-contract "${images_contract}" "${images_out}"; then
    ok "images-list-stubbed"
else
    bad "images-list-stubbed" "${images_out}"
fi

cockpit-images-list-podman() {
    case "${1-} ${2-}" in
        "image ls") printf '[]\n' ;;
        "ps -a") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
images_out="$(HOME="${WORK}/images-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/images-none" cockpit-module-images-list)"
expect_eq "images-list-empty" "${images_out}" '{"items":[]}'

cockpit-images-list-podman() {
    case "${1-} ${2-}" in
        "image ls") printf '[]\n' ;;
        *) return 1 ;;
    esac
}
if images_out="$(HOME="${WORK}/images-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/images-none" cockpit-module-images-list 2>/dev/null)"; then
    bad "images-list-ps-fails" "${images_out}"
else
    ok "images-list-ps-fails"
fi

cockpit-images-list-podman() {
    return 1
}
if images_out="$(HOME="${WORK}/images-none" PODSHIFT_PODMAN_QUADLETS_DIR="${WORK}/images-none" cockpit-module-images-list 2>/dev/null)"; then
    bad "images-list-podman-fails" "${images_out}"
else
    ok "images-list-podman-fails"
fi

