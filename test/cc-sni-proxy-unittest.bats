#!/usr/bin/env bats
# @category slow
# Runs test/test_cc_sni_proxy.py (the cc-sni-proxy unittest suite) so the bats
# runners — scripts/run-tests.sh and scripts/health-check.sh — gate on it.
# Before this wrapper nothing ran the Python file.
#
# Hermetic: the Python suite uses loopback sockets only (a fake upstream on
# 127.0.0.1 via the proxy's --upstream-port seam) and invokes no network binary.
#
# Invoked as a script, not `python3 -m unittest test/...`: the stdlib `test`
# package shadows this directory and that form raises ImportError.
#
# Usage: bats test/cc-sni-proxy-unittest.bats

@test "the cc-sni-proxy unittest suite passes" {
  run python3 "$BATS_TEST_DIRNAME/test_cc_sni_proxy.py"
  echo "$output"
  [ "$status" -eq 0 ]
  # unittest prints "OK" (or "OK (skipped=N)") as its final verdict line.
  [[ "${lines[${#lines[@]}-1]}" =~ ^OK ]]
  # Guard against a vacuous run: at least one test actually executed.
  [[ "$output" =~ Ran\ [1-9][0-9]*\ tests? ]]
}
