#!/usr/bin/env bash
# @file: cockpit-overview-config-user-rows.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/overview
# @dest-dir: /opt/podshift/cockpit/api/fn/overview
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Parses user-defined TSV_* keys from tsv.conf text into overview rows.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints user-defined TSV_* rows from tsv.conf text, sorted by key.
# @details:
#   Accepts the file format written by update-tsv-conf (KEY='value', with quotes in a
#   value encoded as '\'' ) and unquoted KEY=value lines. Keys must match TSV_[A-Z0-9_]+.
#   Built-in names (TSV_ENV and TSV_NW1 to TSV_NW8) are skipped. A repeated key keeps
#   the last value. An empty value is omitted. Comments and invalid lines are ignored.
#   There is no secret mark on TSV keys, so every accepted key with a value is included.
# @arg: $1 - optional tsv.conf text; when omitted, the text is read from stdin.
# @stdout: a JSON array of {id, label, value} objects, or [] when there are no user keys.
# @exitcode: 0 when the array was written, 1 when the output could not be built.
cockpit-overview-config-user-rows() {
    local raw rows
    raw="${1-}"
    if [[ -z "${raw}" && ! -t 0 ]]; then
        raw="$(cat)"
    fi
    rows="$(printf '%s\n' "${raw}" | awk '
        function unquote(v,   n) {
            n = length(v)
            if (n >= 2 && substr(v, 1, 1) == "'"'"'" && substr(v, n, 1) == "'"'"'") {
                v = substr(v, 2, n - 2)
                gsub(/'"'"'\\'"'"''"'"'/, "'"'"'", v)
            } else if (n >= 2 && substr(v, 1, 1) == "\"" && substr(v, n, 1) == "\"") {
                v = substr(v, 2, n - 2)
            }
            return v
        }
        function json_str(s) {
            gsub(/\\/, "\\\\", s)
            gsub(/"/, "\\\"", s)
            return "\"" s "\""
        }
        function is_builtin(k) {
            return k == "TSV_ENV" || k ~ /^TSV_NW[1-8]$/
        }
        /^TSV_[A-Z0-9_]+=/ {
            key = $0
            sub(/=.*/, "", key)
            val = $0
            sub(/^[^=]+=/, "", val)
            last[key] = unquote(val)
        }
        END {
            n = 0
            for (k in last) {
                if (is_builtin(k)) continue
                if (last[k] == "") continue
                n++
                keys[n] = k
            }
            for (i = 1; i <= n; i++) {
                for (j = i + 1; j <= n; j++) {
                    if (keys[j] < keys[i]) {
                        t = keys[i]; keys[i] = keys[j]; keys[j] = t
                    }
                }
            }
            printf "["
            for (i = 1; i <= n; i++) {
                k = keys[i]
                v = last[k]
                if (i > 1) printf ","
                printf "{\"id\":%s,\"label\":%s,\"value\":%s}", json_str(tolower(k)), json_str(k), json_str(v)
            }
            printf "]\n"
        }
    ')" || return 1
    printf '%s' "${rows}" | jq -c -e 'type == "array"' >/dev/null || return 1
    printf '%s\n' "${rows}"
    return 0
}
