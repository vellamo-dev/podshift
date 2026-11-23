#!/usr/bin/env bash
# @file: 170-inspect-handler.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: inspect through the handler, and the inspect module per kind.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# inspect: the handler passes args to the session; bad kind or ref never reaches it.
reset_mocks
MODE="emit"
EMIT='{"kind":"volume","ref":"pgdata","found":true,"object":{"Name":"pgdata","Driver":"local"}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"volume","ref":"pgdata"}}'
if expect_code "inspect-mock-session" "OK"; then
    if [[ "$(field '.data.object.Name')" == "pgdata" && "$(field '.data.found')" == "true" && "$(field '.request.args.ref')" == "pgdata" ]] \
        && grep -q -- '--expand-environment=no' "${ARGV}" && grep -q 'cockpit-run-in-session.sh inspect ' "${ARGV}" \
        && grep -q 'kind' "${STDIN}" && grep -q 'pgdata' "${STDIN}" && ! grep -q 'pgdata' "${ARGV}" && ! grep -q 'pgdata' "${LOG}"; then
        ok "inspect-mock-session"
    else
        bad "inspect-mock-session" "${LAST_OUT} argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"container","ref":"gone","found":false}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"container","ref":"gone"}}'
if expect_code "inspect-not-found" "OK"; then
    [[ "$(field '.data.found')" == "false" && "$(field '.data.object')" == "null" ]]
    expect_status "inspect-not-found" $? "${LAST_OUT}"
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"secret","ref":"3c8e1f0a9b7d6c5e4f3a2b1c0","found":true,"object":{"ID":"3c8e1f0a9b7d6c5e4f3a2b1c0","Spec":{"Name":"db-password"}}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"secret","ref":"3c8e1f0a9b7d6c5e4f3a2b1c0"}}'
if expect_code "inspect-secret-session" "OK"; then
    [[ "$(field '.data.kind')" == "secret" && "$(field '.data.object.Spec.Name')" == "db-password" ]] && grep -q 'secret' "${STDIN}"
    expect_status "inspect-secret-session" $? "${LAST_OUT}"
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"volume","ref":"pgdata","object":{}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"volume","ref":"pgdata"}}'
expect_code "inspect-output-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "inspect-output-contract"

long_ref="$(printf 'a%.0s' {1..257})"
inspect_bad_n=0
for inspect_case in \
    '{"kind":"pod","ref":"x"}|kind' \
    '{"kind":"","ref":"x"}|kind' \
    '{"ref":"x"}|kind' \
    '{"kind":"volume"}|ref' \
    '{}|kind, ref' \
    '{"kind":"volume","ref":""}|ref' \
    '{"kind":"volume","ref":"-rm"}|ref' \
    '{"kind":"volume","ref":"--all"}|ref' \
    '{"kind":"volume","ref":"a b"}|ref' \
    '{"kind":"volume","ref":"a;b"}|ref' \
    '{"kind":"volume","ref":"a$(id)"}|ref' \
    '{"kind":"volume","ref":"a\nb"}|ref' \
    '{"kind":"volume","ref":1}|ref' \
    "{\"kind\":\"volume\",\"ref\":\"${long_ref}\"}|ref" \
    '{"kind":"volume","ref":"x","all":true}|all' \
    '{"kind":"volume","ref":"x","mode":"zip"}|mode' \
    '{"kind":"volume","ref":"x","mode":""}|mode' \
    '{"kind":"pod","ref":"-x","mode":1}|kind, mode, ref'; do
    inspect_args="${inspect_case%|*}"
    inspect_want="Given arguments are not supported: ${inspect_case##*|}."
    inspect_bad_n=$((inspect_bad_n + 1))
    reset_mocks
    MODE="emit"
    EMIT='{"kind":"volume","ref":"x","found":false}'
    run_serve "{\"apiVersion\":1,\"action\":\"inspect\",\"args\":${inspect_args}}"
    if expect_code "inspect-invalid-args-${inspect_bad_n}" "INVALID_ARGS"; then
        if [[ ! -s "${ARGV}" && "$(field '.request.args')" == "null" && "$(field '.status.message')" == "${inspect_want}" ]]; then
            ok "inspect-invalid-args-${inspect_bad_n}"
        else
            bad "inspect-invalid-args-${inspect_bad_n}" "${inspect_args}: $(field '.status.message')"
        fi
    fi
done

reset_mocks
MODE="emit"
EMIT='{"kind":"volume","ref":"x","found":false}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"volume","ref":"x","<b>":1}}'
if expect_code "inspect-invalid-args-unnamed" "INVALID_ARGS" && [[ "$(field '.status.message')" == "Given arguments are not supported." ]]; then
    ok "inspect-invalid-args-unnamed"
else
    bad "inspect-invalid-args-unnamed" "$(field '.status.message')"
fi

reset_mocks
MODE="emit"
EMIT='{"kind":"container","ref":"db","found":true,"file":{"path":"/run/user/300/podshift/inspect-Ab12Cd34Ef.json","size":200000}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"container","ref":"db","mode":"file"}}'
expect_code "inspect-file-mode-session" "OK" && [[ "$(field '.data.file.size')" == "200000" ]] && grep -q '"mode":"file"' "${STDIN}"
expect_status "inspect-file-mode-session" $? "${LAST_OUT}"

reset_mocks
MODE="emit"
EMIT='{"kind":"container","ref":"db","found":true,"file":{"path":"/etc/shadow","size":1}}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"container","ref":"db","mode":"file"}}'
expect_code "inspect-file-path-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "inspect-file-path-contract"

reset_mocks
MODE="emit"
EMIT='{"kind":"image","ref":"big","found":true,"tooLarge":true,"size":300000}'
run_serve '{"apiVersion":1,"action":"inspect","args":{"kind":"image","ref":"big"}}'
expect_code "inspect-too-large-session" "OK" && [[ "$(field '.data.tooLarge')" == "true" && "$(field '.data.size')" == "300000" ]]
expect_status "inspect-too-large-session" $? "${LAST_OUT}"

reset_mocks
MODE="emit"
EMIT='{"pong":true,"uid":300}'
run_serve '{"apiVersion":1,"action":"ping","args":{}}'
if expect_code "ping-empty-args-through-tunnel" "OK"; then
    if grep -q -- '--expand-environment=no' "${ARGV}" && grep -q 'cockpit-run-in-session.sh ping $' "${ARGV}" && grep -qx '{}' "${STDIN}"; then
        ok "ping-empty-args-through-tunnel"
    else
        bad "ping-empty-args-through-tunnel" "argv $(cat "${ARGV}")"
    fi
fi

# inspect module: podman is stubbed with the unit fixtures, one per kind.
ins_fix="${repo}/src/test/unit/fixtures/cockpit-inspect"
ins_calls="${WORK}/inspect.calls"
: > "${ins_calls}"
cockpit-inspect-podman() {
    printf '%s\n' "${*}" >> "${ins_calls}"
    case "${2-} ${3-} ${4-}" in
        "inspect -- db"|"inspect -- alpine"|"inspect -- pgdata"|"inspect -- podman"|"inspect -- db-password")
            cat "${ins_fix}/${1}.json"
            ;;
        "inspect -- "*)
            printf '[]\n'
            return 125
            ;;
        "exists -- broken")
            return 125
            ;;
        "exists -- "*)
            return 1
            ;;
        *)
            return 2
            ;;
    esac
}
inspect_contract="$(jq -c '.output' "${API}/modules/inspect/capability.json")"
for ins_pair in container:db image:alpine volume:pgdata network:podman secret:db-password; do
    ins_kind="${ins_pair%%:*}"
    ins_ref="${ins_pair#*:}"
    ins_out="$(cockpit-module-inspect "{\"kind\":\"${ins_kind}\",\"ref\":\"${ins_ref}\"}")"
    printf '%s' "${ins_out}" | jq -e --arg kind "${ins_kind}" --arg ref "${ins_ref}" --argjson want "$(jq -c '.[0]' "${ins_fix}/${ins_kind}.json")" \
        '.kind == $kind and .ref == $ref and .found == true and .object == $want' >/dev/null \
        && cockpit-validate-contract "${inspect_contract}" "${ins_out}" \
        && grep -qx "${ins_kind} inspect -- ${ins_ref}" "${ins_calls}"
    expect_status "inspect-module-${ins_kind}" $? "${ins_out}"
done

ins_out="$(cockpit-module-inspect '{"kind":"volume","ref":"missing"}')"
[[ "${ins_out}" == '{"kind":"volume","ref":"missing","found":false}' ]] && cockpit-validate-contract "${inspect_contract}" "${ins_out}"
expect_status "inspect-module-not-found" $? "${ins_out}"

if ins_out="$(cockpit-module-inspect '{"kind":"network","ref":"broken"}' 2>/dev/null)"; then
    bad "inspect-module-podman-fails" "${ins_out}"
else
    ok "inspect-module-podman-fails"
fi

: > "${ins_calls}"
if ins_out="$(cockpit-module-inspect '{"kind":"pod","ref":"db"}' 2>/dev/null)" || [[ -s "${ins_calls}" ]]; then
    bad "inspect-module-bad-kind" "${ins_out}"
else
    ok "inspect-module-bad-kind"
fi
if ins_out="$(cockpit-module-inspect '{"kind":"volume","ref":"-a"}' 2>/dev/null)" || [[ -s "${ins_calls}" ]]; then
    bad "inspect-module-bad-ref" "${ins_out}"
else
    ok "inspect-module-bad-ref"
fi

