#!/usr/bin/env bash
# @file: 300-config.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/cases
# @group: test
# @category: helper
# @description: config-set, config-unset and env-set.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
#
# Sourced in order by run-cockpit-api-cases.sh, so it shares the variables and mocks set up before it.

# --- config-set, config-unset and env-set ---
# The modules run in this process with real files in a temporary folder. The caller gates,
# load-podshift-conf-main and sudo are stubbed; the real tsv-rules.conf is used.
# shellcheck source=/dev/null
source "${API}/modules/config-set/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/config-unset/module.sh"
# shellcheck source=/dev/null
source "${API}/modules/env-set/module.sh"
cfg_dir="${WORK}/config"
mkdir -p "${cfg_dir}"
cfg_tsv="${cfg_dir}/tsv.conf"
cfg_runtime="${cfg_dir}/runtime.conf"
cfg_rules="${PODSHIFT}/conf/tsv-rules.conf"
cfg_set_contract="$(jq -c '.output' "${API}/modules/config-set/capability.json")"
cfg_unset_contract="$(jq -c '.output' "${API}/modules/config-unset/capability.json")"
env_set_contract="$(jq -c '.output' "${API}/modules/env-set/capability.json")"
cfg_secret="Secrets don't belong in config. Use a Podman secret instead."
require-podshift() { return 0; }
require-admin() { return 0; }
sudo() { "$@"; }
load-podshift-conf-main() {
    PODSHIFT_TSV_CONF="${cfg_tsv}"
    PODSHIFT_TSV_RULES_CONF="${cfg_rules}"
    PODSHIFT_RUNTIME_CONF="${cfg_runtime}"
    PODSHIFT_RUNTIME_CONF_TEMPLATES="${PODSHIFT}/assets/tpl"
}
printf "# Custom TSV_* variables used by quadlets.\nTSV_KEEP='kept'\n" > "${cfg_tsv}"

cfg_out="$(cockpit-module-config-set '{"key":"TSV_APP_DOMAIN","value":"example.com"}')"
if [[ "${cfg_out}" == '{"key":"TSV_APP_DOMAIN","ok":true}' ]] \
    && cockpit-validate-contract "${cfg_set_contract}" "${cfg_out}" \
    && grep -qx "TSV_APP_DOMAIN='example.com'" "${cfg_tsv}" && grep -qx "TSV_KEEP='kept'" "${cfg_tsv}"; then
    ok "config-set-saves"
else
    bad "config-set-saves" "${cfg_out} file $(tr '\n' ';' < "${cfg_tsv}")"
fi

cfg_out="$(cockpit-module-config-set '{"key":"TSV_APP_DOMAIN","value":"example.org"}')"
if [[ "${cfg_out}" == '{"key":"TSV_APP_DOMAIN","ok":true}' ]] \
    && [[ "$(grep -c '^TSV_APP_DOMAIN=' "${cfg_tsv}")" == "1" ]] && grep -qx "TSV_APP_DOMAIN='example.org'" "${cfg_tsv}"; then
    ok "config-set-replaces"
else
    bad "config-set-replaces" "${cfg_out} file $(tr '\n' ';' < "${cfg_tsv}")"
fi

cfg_before="$(cat "${cfg_tsv}")"
cfg_n=0
for cfg_case in \
    'INVALID_NAME|{"key":"TSV_app","value":"x"}' \
    'INVALID_NAME|{"key":"TSV_A\nB","value":"x"}' \
    'RESERVED_NAME|{"key":"TSV_NW1","value":"x"}' \
    'RESERVED_NAME|{"key":"TSV_NWORDER","value":"x"}' \
    'RESERVED_NAME|{"key":"TSV_ENV","value":"dev"}' \
    'RESERVED_NAME|{"key":"TSV_ENV2","value":"x"}' \
    'SENSITIVE_NAME|{"key":"TSV_DB_PASSWORD","value":"x"}' \
    'SENSITIVE_NAME|{"key":"TSV_API_KEY","value":"x"}' \
    'EMPTY_VALUE|{"key":"TSV_APP","value":""}' \
    'INVALID_VALUE|{"key":"TSV_APP","value":"a\"b"}' \
    'INVALID_VALUE|{"key":"TSV_APP","value":"ok\n"}' \
    'INVALID_VALUE|{"key":"TSV_APP","value":"a\u0000b"}' \
    'INVALID_VALUE|{"key":"TSV_APP","value":"end\\"}' \
    'SENSITIVE_VALUE|{"key":"TSV_APP","value":"gh''p_abcdefghijABCDEFGHIJ0123456789abcdef"}' \
    'SENSITIVE_VALUE|{"key":"TSV_APP","value":"AKIA''IOSFODNN7EXAMPLE"}'; do
    cfg_n=$((cfg_n + 1))
    cfg_want="${cfg_case%%|*}"
    cfg_args="${cfg_case#*|}"
    cfg_out="$(cockpit-module-config-set "${cfg_args}")"
    printf '%s' "${cfg_out}" | jq -e --arg want "${cfg_want}" '.ok == false and .error == $want and (.message | length) > 0' >/dev/null \
        && cockpit-validate-contract "${cfg_set_contract}" "${cfg_out}" \
        && [[ "${cfg_out}" != *ghp_* && "${cfg_out}" != *AKIA* ]] \
        && [[ "$(cat "${cfg_tsv}")" == "${cfg_before}" ]]
    expect_status "config-set-refused-${cfg_n}-${cfg_want}" $? "${cfg_args}: ${cfg_out}"
done

cfg_out="$(cockpit-module-config-set '{"key":"TSV_DB_PASSWORD","value":"x"}')"
printf '%s' "${cfg_out}" | jq -e --arg m "${cfg_secret}" '.message == $m' >/dev/null
expect_status "config-set-secret-message" $? "${cfg_out}"

cfg_rules="${cfg_dir}/missing-rules.conf"
cfg_out="$(cockpit-module-config-set '{"key":"TSV_NEW","value":"x"}')"
cfg_rules="${PODSHIFT}/conf/tsv-rules.conf"
printf '%s' "${cfg_out}" | jq -e '.ok == false and .error == "RULES_UNAVAILABLE"' >/dev/null \
    && cockpit-validate-contract "${cfg_set_contract}" "${cfg_out}" && ! grep -q '^TSV_NEW=' "${cfg_tsv}"
expect_status "config-set-rules-missing" $? "${cfg_out}"

cfg_out="$(cockpit-module-config-unset '{"key":"TSV_APP_DOMAIN"}')"
if [[ "${cfg_out}" == '{"key":"TSV_APP_DOMAIN","ok":true}' ]] \
    && cockpit-validate-contract "${cfg_unset_contract}" "${cfg_out}" \
    && ! grep -q '^TSV_APP_DOMAIN=' "${cfg_tsv}" && grep -qx "TSV_KEEP='kept'" "${cfg_tsv}"; then
    ok "config-unset-removes"
else
    bad "config-unset-removes" "${cfg_out} file $(tr '\n' ';' < "${cfg_tsv}")"
fi

cfg_out="$(cockpit-module-config-unset '{"key":"TSV_APP_DOMAIN"}')"
[[ "${cfg_out}" == '{"key":"TSV_APP_DOMAIN","ok":false,"error":"NOT_SET","message":"TSV_APP_DOMAIN is not set."}' ]] \
    && cockpit-validate-contract "${cfg_unset_contract}" "${cfg_out}"
expect_status "config-unset-not-set" $? "${cfg_out}"

printf "TSV_NW9='x'\nTSV_DB_PASSWORD='old'\n" >> "${cfg_tsv}"
cfg_n=0
for cfg_case in 'RESERVED_NAME|TSV_NW1' 'RESERVED_NAME|TSV_NW9' 'RESERVED_NAME|TSV_ENV' 'INVALID_NAME|tsv_keep' 'INVALID_NAME|TSV_K.*'; do
    cfg_n=$((cfg_n + 1))
    cfg_want="${cfg_case%%|*}"
    cfg_key="${cfg_case#*|}"
    cfg_out="$(cockpit-module-config-unset "$(jq -n -c --arg key "${cfg_key}" '{key: $key}')")"
    printf '%s' "${cfg_out}" | jq -e --arg want "${cfg_want}" '.ok == false and .error == $want' >/dev/null \
        && cockpit-validate-contract "${cfg_unset_contract}" "${cfg_out}" \
        && grep -q '^TSV_NW9=' "${cfg_tsv}" && grep -q '^TSV_KEEP=' "${cfg_tsv}"
    expect_status "config-unset-refused-${cfg_n}-${cfg_want}" $? "${cfg_key}: ${cfg_out}"
done

cfg_out="$(cockpit-module-config-unset '{"key":"TSV_DB_PASSWORD"}')"
[[ "${cfg_out}" == '{"key":"TSV_DB_PASSWORD","ok":true}' ]] && ! grep -q '^TSV_DB_PASSWORD=' "${cfg_tsv}"
expect_status "config-unset-old-secret-name" $? "${cfg_out}"

printf "# PodShift Runtime Configuration\nTSV_ENV=\nPODSHIFT_NW_DEVICE=\"eth0\"\n" > "${cfg_runtime}"
cfg_out="$(cockpit-module-env-set '{"value":"bad tag"}')"
printf '%s' "${cfg_out}" | jq -e '.key == "TSV_ENV" and .ok == false and .error == "INVALID_TAG"' >/dev/null \
    && cockpit-validate-contract "${env_set_contract}" "${cfg_out}" && grep -qx 'TSV_ENV=' "${cfg_runtime}"
expect_status "env-set-invalid-tag" $? "${cfg_out}"

cfg_out="$(cockpit-module-env-set '{"value":"dev"}')"
if [[ "${cfg_out}" == '{"key":"TSV_ENV","ok":true}' ]] \
    && cockpit-validate-contract "${env_set_contract}" "${cfg_out}" \
    && grep -qx "TSV_ENV='dev'" "${cfg_runtime}" && [[ "$(grep -c '^TSV_ENV=' "${cfg_runtime}")" == "1" ]] \
    && grep -qx 'PODSHIFT_NW_DEVICE="eth0"' "${cfg_runtime}"; then
    ok "env-set-sets-once"
else
    bad "env-set-sets-once" "${cfg_out} file $(tr '\n' ';' < "${cfg_runtime}")"
fi

cfg_out="$(cockpit-module-env-set '{"value":"prod"}')"
if printf '%s' "${cfg_out}" | jq -e '.ok == false and .error == "ALREADY_SET" and (.message | test("sudo podshift env --set"))' >/dev/null \
    && cockpit-validate-contract "${env_set_contract}" "${cfg_out}" && grep -qx "TSV_ENV='dev'" "${cfg_runtime}"; then
    ok "env-set-refuses-second"
else
    bad "env-set-refuses-second" "${cfg_out} file $(tr '\n' ';' < "${cfg_runtime}")"
fi

if cockpit-validate-contract "${cfg_set_contract}" '{"key":"TSV_A","ok":false,"error":"OTHER"}' \
    || cockpit-validate-contract "${cfg_set_contract}" '{"key":"TSV_A","ok":true,"value":"leak"}'; then
    bad "config-set-output-contract" "an unknown code or extra field was accepted"
else
    ok "config-set-output-contract"
fi
unset -f require-podshift require-admin sudo load-podshift-conf-main
rm -rf "${cfg_dir}"

# Handler runs: bad arguments never reach the session, config-set and config-unset enter the
# podshift session, and env-set runs in the root realm without it.
cfg_n=0
for cfg_body in \
    '{"apiVersion":1,"action":"config-set","args":{"key":"TSV_APP"}}' \
    '{"apiVersion":1,"action":"config-set","args":{"key":"TSV_APP","value":"x","extra":1}}' \
    '{"apiVersion":1,"action":"config-set","args":{"key":"","value":"x"}}' \
    '{"apiVersion":1,"action":"config-set","args":{"key":"TSV_APP","value":5}}' \
    '{"apiVersion":1,"action":"config-unset","args":{}}' \
    '{"apiVersion":1,"action":"env-set","args":{"value":"dev","force":true}}'; do
    cfg_n=$((cfg_n + 1))
    reset_mocks
    MODE="emit"
    EMIT='{"key":"TSV_APP","ok":true}'
    run_serve "${cfg_body}"
    if expect_code "config-handler-invalid-args-${cfg_n}" "INVALID_ARGS"; then
        if [[ ! -s "${ARGV}" && "$(field '.request.args')" == "null" ]]; then
            ok "config-handler-invalid-args-${cfg_n}"
        else
            bad "config-handler-invalid-args-${cfg_n}" "argv $(cat "${ARGV}")"
        fi
    fi
done

reset_mocks
MODE="emit"
EMIT='{"key":"TSV_APP","ok":true}'
run_serve '{"apiVersion":1,"action":"config-set","args":{"key":"TSV_APP","value":"a $HOME b"}}'
if expect_code "config-set-mock-session" "OK"; then
    if [[ "$(field '.data.ok')" == "true" ]] && grep -q 'cockpit-run-in-session.sh config-set ' "${ARGV}" && grep -q 'TSV_APP' "${STDIN}" && grep -qF 'a $HOME b' "${STDIN}" && ! grep -q 'TSV_APP' "${ARGV}" && ! grep -q 'TSV_APP' "${LOG}"; then
        ok "config-set-mock-session"
    else
        bad "config-set-mock-session" "${LAST_OUT} argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"key":"TSV_APP","ok":true}'
run_serve '{"apiVersion":1,"action":"config-unset","args":{"key":"TSV_APP"}}'
if expect_code "config-unset-mock-session" "OK"; then
    if grep -q 'cockpit-run-in-session.sh config-unset ' "${ARGV}"; then
        ok "config-unset-mock-session"
    else
        bad "config-unset-mock-session" "argv $(cat "${ARGV}")"
    fi
fi

reset_mocks
MODE="emit"
EMIT='{"key":"TSV_APP","ok":true,"value":"leak"}'
run_serve '{"apiVersion":1,"action":"config-set","args":{"key":"TSV_APP","value":"x"}}'
expect_code "config-set-handler-output-contract" "INTERNAL" && [[ "$(field '.data')" == "null" ]] && ok "config-set-handler-output-contract"

reset_mocks
run_serve '{"apiVersion":1,"action":"env-set","args":{"value":"-bad"}}'
if expect_code "env-set-root-realm" "OK"; then
    if [[ ! -s "${ARGV}" && "$(field '.data.error')" == "INVALID_TAG" && "$(field '.data.key')" == "TSV_ENV" ]]; then
        ok "env-set-root-realm"
    else
        bad "env-set-root-realm" "${LAST_OUT} argv $(cat "${ARGV}")"
    fi
fi

