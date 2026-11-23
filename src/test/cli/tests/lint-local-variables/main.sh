#!/usr/bin/env bash
# @file: main.sh
# @source-dir: src/test/cli/tests/lint-local-variables
# @group: test
# @category: entry
# @title: Linting local variables
# @platforms: all
# @description: Checks that every lowercase variable a function or bats test sets is declared local in it.
# @details:
#   Reads the shell and bats files of src/server, src/deployment and src/test with awk. Nothing is run.
# @license: AGPL-3.0-or-later
# @license-url: https://github.com/vellamo-dev/podshift/blob/main/LICENSE
# @author: Vellamo.fyi
