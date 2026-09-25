#!/usr/bin/env bash
# Run the pass-2 security probes and write probe.log next to this script.
# Hermetic: every test pins HOME/TMPDIR/destinations into bats' temp dir and
# points git at an empty global config (see probe.bats).
set -uo pipefail
here="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
{
  date -u +%Y-%m-%dT%H:%M:%SZ
  git --version
  bats --verbose-run --show-output-of-passing-tests "$here/probe.bats" 2>&1
  echo "bats exit=$?"
} > "$here/probe.log" 2>&1
tail -n 5 "$here/probe.log"
