#!/usr/bin/env bash
# @file: 510-verify-spec-scriptlets.sh
# @source-dir: src/test/cli/tests/lint-spec-scriptlets/steps
# @group: test
# @category: step
# @description: Verify spec scriptlet calls.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Checks that %post, %preun and %posttrans call their scripts with "$1", and that %postun uses -f %{SOURCE1}.
# @arg: $1 - the run folder.
# @stdout: NOTE with the count, and a DETAIL line for each problem.
# @exitcode: 0 if all are fine, 2 otherwise (PodShift problem).
verify-spec-scriptlets() {
    local line
    local run_dir spec bad
    run_dir="${1}"
    spec="podshift.spec"
    if [[ ! -f "${spec}" ]]; then
        echo "DETAIL: ${spec} was not found"
        write-log "${run_dir}" lint-spec-scriptlets "podshift.spec missing"
        echo "NOTE: 0 checks, 1 not OK"
        return 2
    fi
    bad=0
    while IFS= read -r line; do
        [[ -n "${line}" ]] || continue
        echo "DETAIL: ${line}"
        bad=$((bad + 1))
    done < <(awk '
        function is_section(line) {
            return line ~ /^%(description|prep|build|install|check|files|preun|postun|posttrans|pre|post|changelog|package)([ \t]|$)/
        }
        BEGIN {
            post_ok = 0; preun_ok = 0; posttrans_ok = 0; postun_ok = 0
            post_seen = 0; preun_seen = 0; posttrans_seen = 0; postun_seen = 0
        }
        /^%postun([ \t]|$)/ {
            section = "postun"; postun_seen = 1
            if (index($0, "-f %{SOURCE1}")) postun_ok = 1
            next
        }
        /^%posttrans([ \t]|$)/ { section = "posttrans"; posttrans_seen = 1; next }
        /^%preun([ \t]|$)/ { section = "preun"; preun_seen = 1; next }
        /^%post([ \t]|$)/ { section = "post"; post_seen = 1; next }
        is_section($0) { section = ""; next }
        section == "post" && index($0, "/opt/podshift/rpm/post.sh \"" "$" "1\"") { post_ok = 1 }
        section == "preun" && index($0, "/opt/podshift/rpm/preun.sh \"" "$" "1\"") { preun_ok = 1 }
        section == "posttrans" && index($0, "/opt/podshift/rpm/posttrans.sh \"" "$" "1\"") { posttrans_ok = 1 }
        END {
            if (!post_seen) print "%post section was not found"
            else if (!post_ok) print "%post does not call /opt/podshift/rpm/post.sh \"" "$" "1\""
            if (!preun_seen) print "%preun section was not found"
            else if (!preun_ok) print "%preun does not call /opt/podshift/rpm/preun.sh \"" "$" "1\""
            if (!posttrans_seen) print "%posttrans section was not found"
            else if (!posttrans_ok) print "%posttrans does not call /opt/podshift/rpm/posttrans.sh \"" "$" "1\""
            if (!postun_seen) print "%postun section was not found"
            else if (!postun_ok) print "%postun does not use -f %{SOURCE1}"
        }
    ' "${spec}")
    write-log "${run_dir}" lint-spec-scriptlets "Scriptlets: 4 checks, ${bad} with problems"
    echo "NOTE: 4 checks, ${bad} not OK"
    (( bad == 0 )) || return 2
}
