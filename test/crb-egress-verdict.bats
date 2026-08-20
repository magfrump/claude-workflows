#!/usr/bin/env bats
# @category fast
# Guards scripts/crb-egress-verdict.sh — the PASS/FAIL rules of the egress
# preflight, which is the control the whole arm's containment story rests on.
#
# Why this file exists: the rules used to live inline in run-host.sh, where
# test/crb-egress-config.bats could pin that the legs EXISTED but nothing could
# see what they CONCLUDED. The 2026-08-19 test-strategy pass proved the gap by
# mutation — widening leg 2 to accept HTTP 200, neutering leg 3 to
# `[ -n "$direct" ]`, and dropping `--internal` from `docker network create`
# each left 37/37 tests green with every "ok" line still printed. Each of those
# three mutations now fails a case below.
#
# The cases are written as the mutations they must catch, not as a restatement
# of the implementation. NOTE the limit found by the iteration-2 fact-check: a
# case here mutates the STRING handed to the verdict script, which does not
# prove the runner hands it a truthful one. Dropping `--internal` from the
# runner's own `docker network create` survived every case in this file until
# the last one below was added.
#
# Hermetic: pure argument-in / verdict-out. No docker, no network, no files.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export VERDICT="$REPO_ROOT/scripts/crb-egress-verdict.sh"
}

verdict() { run bash "$VERDICT" "$@"; }

# ── leg 0: --internal ────────────────────────────────────────────────────────
# The single flag the containment story rests on. Without it the network routes
# to the internet directly and EVERY other leg still passes, because they all go
# through the proxy by construction. That is what made the mutation invisible.

@test "internal-net passes when the network really was created --internal" {
  verdict internal-net "docker network create --internal --subnet 172.31.250.0/24 crb-inner"
  [ "$status" -eq 0 ]
}

@test "MUTATION: dropping --internal from the network create FAILS" {
  verdict internal-net "docker network create --subnet 172.31.250.0/24 crb-inner"
  [ "$status" -eq 1 ]
  [[ "$output" == *"WITHOUT --internal"* ]]
}

# ── leg 1: the API must be reachable through the proxy ───────────────────────

@test "api-reachable accepts any HTTP status, including 401" {
  for code in 200 401 403 404 500; do
    verdict api-reachable "$code"
    [ "$status" -eq 0 ]
  done
}

@test "api-reachable FAILS on 000 — a cell could not run at all" {
  verdict api-reachable 000
  [ "$status" -eq 1 ]
  [[ "$output" == *"unreachable through the proxy"* ]]
}

# ── legs 2 / 2b: a non-allowlisted host must be refused ──────────────────────
# github.com is where the answer key lives, over HTTPS and over plain HTTP.
# ConnectPort scopes CONNECT only, so the plain-HTTP path is a separate question
# and http_proxy is exported to every cell.

@test "filter-blocks and plain-http accept a 403 or a connect-level refusal" {
  for leg in filter-blocks plain-http; do
    for code in 403 000; do
      verdict "$leg" "$code"
      [ "$status" -eq 0 ]
    done
  done
}

@test "MUTATION: accepting HTTP 200 from a non-allowlisted host FAILS" {
  for leg in filter-blocks plain-http; do
    verdict "$leg" 200
    [ "$status" -eq 1 ]
    [[ "$output" == *"allowlist is NOT filtering"* ]]
    [[ "$output" == *"refusing to spend"* ]]
  done
}

@test "a served redirect from a non-allowlisted host also FAILS" {
  verdict filter-blocks 301
  [ "$status" -eq 1 ]
}

# ── leg 3: no route at all without the proxy ─────────────────────────────────
# This is what contains a subprocess that ignores HTTPS_PROXY — curl, git,
# anything the agent shells out to.

@test "no-direct-route passes only on 000" {
  verdict no-direct-route 000
  [ "$status" -eq 0 ]
}

@test "MUTATION: any answer at all without the proxy FAILS" {
  for code in 200 301 403 500; do
    verdict no-direct-route "$code"
    [ "$status" -eq 1 ]
    [[ "$output" == *"network is not internal"* ]]
  done
}

# A 403 here is the specific trap: it is a PASS for leg 2 and must be a FAIL
# here, because it means something answered on a network that should have no
# route. A shared "refusal" predicate across the two legs would miss it.
@test "403 passes filter-blocks and FAILS no-direct-route" {
  verdict filter-blocks 403
  [ "$status" -eq 0 ]
  verdict no-direct-route 403
  [ "$status" -eq 1 ]
}

# ── usage ────────────────────────────────────────────────────────────────────
# Exit 2 is not a verdict. The runner treats a nonzero as "do not spend", so a
# usage error failing closed is right — but it must be distinguishable.

@test "usage errors exit 2, distinct from a failed leg" {
  run bash "$VERDICT"
  [ "$status" -eq 2 ]
  run bash "$VERDICT" api-reachable
  [ "$status" -eq 2 ]
  run bash "$VERDICT" not-a-leg 200
  [ "$status" -eq 2 ]
  run bash "$VERDICT" "" 200
  [ "$status" -eq 2 ]
}

# ── the runner actually uses it ──────────────────────────────────────────────
# Extraction only helps if the runner stopped deciding for itself.

# The mutation that survived the whole suite: the case above proves the verdict
# script REJECTS a create-line without --internal, but the runner could still be
# building one. This asserts the command the runner actually constructs and then
# runs, which is the thing the leg is handed.
@test "the runner's own network create really carries --internal" {
  runner="$REPO_ROOT/runs/review-arms/crb-pipeline/run-host.sh"
  run grep -E '^\s*NET_CREATE_CMD="docker network create' "$runner"
  [ "$status" -eq 0 ]
  [[ "$output" == *"--internal"* ]]
  # ...and that the create is executed via that variable, so the asserted string
  # is the command that runs rather than a decorative copy of it.
  grep -qE '^\s*\$NET_CREATE_CMD >' "$runner"
  # ...and that the leg is handed that same variable.
  grep -q 'egress_leg internal-net "$NET_CREATE_CMD"' "$runner"
}

@test "run-host.sh delegates every leg to the verdict script" {
  runner="$REPO_ROOT/runs/review-arms/crb-pipeline/run-host.sh"
  for leg in internal-net api-reachable filter-blocks plain-http no-direct-route; do
    grep -q "egress_leg $leg" "$runner"
  done
  # And does not re-implement a verdict inline: no bare http-code comparison
  # against the legs' sentinel values in the preflight block.
  run grep -nE '\[ "\$(api_code|gh_code|direct)"' "$runner"
  [ "$status" -ne 0 ]
}
