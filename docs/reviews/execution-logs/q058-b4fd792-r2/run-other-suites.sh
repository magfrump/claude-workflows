#!/usr/bin/env bash
# Run the two suites (besides install-host and cc-isolated-functions) that make up
# the "315/315" count claimed by 648124c and b4fd792. Usage: run-other-suites.sh <worktree>
cd "$1" || exit 99
date -u +%FT%TZ
echo "== link-claude-home-wiring"; bats test/link-claude-home-wiring.bats; echo "rc=$?"
echo "== hooks";                   bats test/hooks;                        echo "rc=$?"
