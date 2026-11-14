#!/usr/bin/env bash
# @file: cockpit-services-journal-error.sh
# @source-dir: src/server/opt/podshift/cockpit/api/fn/services
# @dest-dir: /opt/podshift/cockpit/api/fn/services
# @host-edit: no
# @group: cockpit
# @category: helper
# @unit-test: yes
# @description: Tells whether journalctl stderr shows a permission error and prints a short reason.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints a short reason when journalctl stderr shows that the journal cannot be read.
# @details:
#   Reads journalctl stderr from stdin. A permission error is a line with insufficient permissions,
#   No journal files were opened, Permission denied, Access denied or Operation not permitted, in
#   any case. Other messages, such as No journal files were found or a Hint line, are not errors:
#   the unit then simply has no entries. The reason is the first non-empty stderr line, with every
#   byte that is not printable ASCII replaced by a space, spaces squeezed and trimmed, and cut to
#   200 characters.
# @stdout: the reason, when there is a permission error.
# @exitcode: 0 for a permission error, 1 otherwise.
cockpit-services-journal-error() {
    local text reason
    text="$(head -c 8192)"
    printf '%s\n' "${text}" | grep -q -i -E 'insufficient permissions|No journal files were opened|Permission denied|Access denied|Operation not permitted' || return 1
    reason="$(printf '%s\n' "${text}" | LC_ALL=C tr -c '[:print:]\n' ' ' | LC_ALL=C tr -s ' ' | sed -e 's/^ //' -e 's/ $//' | grep -m 1 -v '^$')"
    printf '%s\n' "${reason:0:200}"
}
