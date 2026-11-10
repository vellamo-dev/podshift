#!/usr/bin/env bash
# @file: text-distance.sh
# @source-dir: src/test/cli/shared/fn/utils
# @group: test
# @category: helper
# @description: Counts how many typos apart two words are.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi

# @description: Prints the Levenshtein distance: the single-letter changes that turn one word into another.
# @arg: $1 - the first word, for example hots-check.
# @arg: $2 - the second word, for example host-check.
# @stdout: the distance, for example 2.
text-distance() {
    awk -v a="${1}" -v b="${2}" 'BEGIN {
        n = length(a); m = length(b)
        for (i = 0; i <= n; i++) d[i, 0] = i
        for (j = 0; j <= m; j++) d[0, j] = j
        for (i = 1; i <= n; i++) {
            for (j = 1; j <= m; j++) {
                cost = (substr(a, i, 1) == substr(b, j, 1)) ? 0 : 1
                best = d[i - 1, j] + 1
                if (d[i, j - 1] + 1 < best) best = d[i, j - 1] + 1
                if (d[i - 1, j - 1] + cost < best) best = d[i - 1, j - 1] + cost
                d[i, j] = best
            }
        }
        print d[n, m]
    }'
}
