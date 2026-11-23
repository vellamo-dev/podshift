#!/usr/bin/env bash
# @file: expect_row_contract.sh
# @source-dir: src/test/cli/tests/unit-cockpit-api/scripts/fn
# @group: test
# @category: helper
# @description: Checks that an overview payload has well-formed rows.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that an overview payload has well-formed rows.
expect_row_contract() {
    local name payload
    name="${1}"
    payload="${2}"
    if printf '%s' "${payload}" | jq -e '
        (.rows | type) == "array"
        and all(.rows[]; (.id | type) == "string" and (.id | test("^[a-z0-9_]+$"))
            and (.label | type) == "string" and (.label | length) > 0
            and (.value == null or (.value | type) == "string")
            and (
                (keys | sort) == ["id","label","value"]
                or (
                    (keys | sort) == ["editable","id","label","value"]
                    and (.editable | type) == "boolean"
                )
                or (
                    (keys | sort) == ["id","label","unit","value"]
                    and (.unit | type) == "string"
                    and (.unit | length) > 0
                )
                or (
                    (keys | sort) == ["id","label","scope","unit","value"]
                    and (.unit | type) == "string"
                    and (.unit | length) > 0
                    and (.scope == "user" or .scope == "system")
                )
            ))
    ' >/dev/null; then
        ok "${name}"
    else
        bad "${name}" "${payload}"
    fi
}
