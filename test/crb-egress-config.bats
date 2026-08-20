#!/usr/bin/env bats
# @category fast
# Guards the egress allowlist for the CRB direction-1 arm (2026-08-18 rubric R3,
# 2026-08-19 R4): the review container runs on an --internal docker network
# whose only route out is a tinyproxy sidecar allowing exactly one host.
#
# What this file can and cannot do. It CANNOT prove the allowlist filters —
# that needs docker, and it is proven by execution in run-host.sh's own egress
# preflight, whose three legs must pass before any paid cell. What it CAN do is
# pin the two ways the control silently stops existing between sweeps:
#   * the allowlist quietly growing a host, or the proxy config losing
#     FilterDefaultDeny (at which point the filter allows everything);
#   * run-host.sh growing a container that is not on the restricted network, or
#     regaining a host-side `git` call against the clone.
# Both are edits nobody would flag in review without a test naming them.
#
# Hermetic: reads repository files only. No docker, no network.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export DOCKER_DIR="$REPO_ROOT/runs/review-arms/crb-pipeline/docker"
  export RUNNER="$REPO_ROOT/runs/review-arms/crb-pipeline/run-host.sh"
}

@test "the allowlist names exactly one host, anchored" {
  run grep -c '^[^#]' "$DOCKER_DIR/egress-allowlist"
  [ "$output" = "1" ]
  run grep '^[^#]' "$DOCKER_DIR/egress-allowlist"
  [ "$output" = '^api\.anthropic\.com$' ]
}

# FilterDefaultDeny inverts the filter's sense: entries are what is ALLOWED.
# Without it the same file becomes a blocklist of one host and everything else
# is permitted — a failure that looks identical from the outside until the
# preflight's negative leg runs.
@test "the proxy config denies by default and points at the allowlist" {
  run grep -E '^[[:space:]]*FilterDefaultDeny[[:space:]]+Yes' "$DOCKER_DIR/tinyproxy.conf"
  [ "$status" -eq 0 ]
  run grep -E '^[[:space:]]*Filter[[:space:]]+"/etc/tinyproxy/filter"' "$DOCKER_DIR/tinyproxy.conf"
  [ "$status" -eq 0 ]
  run grep -E '^[[:space:]]*FilterURLs[[:space:]]+Off' "$DOCKER_DIR/tinyproxy.conf"
  [ "$status" -eq 0 ]
}

@test "the proxy tunnels 443 only and serves only the pinned subnet" {
  run grep -E '^[[:space:]]*ConnectPort[[:space:]]+443' "$DOCKER_DIR/tinyproxy.conf"
  [ "$status" -eq 0 ]
  # An open Allow would proxy for anything else on this host's default bridge,
  # which the proxy is also attached to.
  run grep -E '^[[:space:]]*Allow[[:space:]]+0\.0\.0\.0/0' "$DOCKER_DIR/tinyproxy.conf"
  [ "$status" -ne 0 ]
  subnet=$(grep -oE '^[[:space:]]*Allow[[:space:]]+[0-9./]+' "$DOCKER_DIR/tinyproxy.conf" | awk '{print $2}')
  grep -q "EGRESS_SUBNET=\"\${EGRESS_SUBNET:-$subnet}\"" "$RUNNER"
}

@test "the review image bakes the CLI rather than installing per cell" {
  run grep -E 'npm install -g "@anthropic-ai/claude-code' "$DOCKER_DIR/Dockerfile.review"
  [ "$status" -eq 0 ]
  # An `npx -y` in the runner would put registry.npmjs.org back in the path of
  # every paid cell, which is what the baked image exists to avoid.
  run grep -n 'npx -y @anthropic-ai/claude-code' "$RUNNER"
  [ "$status" -ne 0 ]
}

@test "every container that carries the API key is on the restricted network" {
  # Each `docker run` block that passes ANTHROPIC_API_KEY must also name the
  # egress network. Blocks are line-continuation joined first.
  run bash -c 'python3 - "$0" <<'"'"'PY'"'"'
import re, sys
src = open(sys.argv[1]).read().replace("\\\n", " ")
bad = [l for l in src.splitlines()
       if "docker run" in l and "ANTHROPIC_API_KEY" in l and "$EGRESS_NET" not in l]
print("\n".join(bad))
sys.exit(1 if bad else 0)
PY' "$RUNNER"
  [ "$status" -eq 0 ]
}

@test "the audit container has no network and no key" {
  run bash -c 'python3 - "$0" <<'"'"'PY'"'"'
import sys
src = open(sys.argv[1]).read().replace("\\\n", " ")
audit = [l for l in src.splitlines() if "crb-audit-clone.sh" in l and "docker run" in l]
assert audit, "no docker run invokes the audit script"
line = audit[0]
assert "--network none" in line, line
assert "ANTHROPIC_API_KEY" not in line, line
PY' "$RUNNER"
  [ "$status" -eq 0 ]
}

# The disposable-clone invariant, stated where a future edit would trip it:
# nothing on the host may run git against the clone the container wrote.
@test "the runner never runs host git against the work clone" {
  run grep -nE '^[^#]*\bgit\b[^#]*"\$clone"' "$RUNNER"
  [ "$status" -ne 0 ]
  run grep -nE '^[^#]*git -C "\$CLONES' "$RUNNER"
  [ "$status" -ne 0 ]
}

@test "the runner restores from the baseline before every cell" {
  run grep -E 'crb-materialize\.py" --restore "\$id"' "$RUNNER"
  [ "$status" -eq 0 ]
  # The modes it replaced must be gone, not merely unused: --reset was the
  # in-place host-git repair, --heal its one-shot companion.
  run grep -E 'crb-materialize\.py" --(reset|heal)' "$RUNNER"
  [ "$status" -ne 0 ]
}

@test "the egress preflight runs all five legs and blocks the sweep" {
  # Verdicts live in scripts/crb-egress-verdict.sh (pinned by
  # test/crb-egress-verdict.bats); this pins that every leg is actually invoked.
  # Dropping any one leaves a control that can pass for the wrong reason — and
  # the --internal leg exists because dropping that flag was invisible to every
  # other leg, all of which go through the proxy by construction.
  for leg in internal-net api-reachable filter-blocks plain-http no-direct-route; do
    grep -q "egress_leg $leg" "$RUNNER"
  done
  # A failed leg must stop the sweep rather than warn.
  grep -q 'exit 5' "$RUNNER"
}

# ── the runner's spend and verdict wiring ────────────────────────────────────
# run-host.sh has no executing test (582 lines, all the money), so these are
# structural pins on the three places the 2026-08-19 review found it deciding
# something it should not. Each is written as the defect it must catch.

@test "the audit's exit 2 is NOT treated as contamination" {
  # A bare `if ! docker run` collapsed "could not check" (2) and docker's own
  # 125/126/127 into VOID, publishing detected contamination about a $10-40 cell
  # that was never checked.
  # `^[^#]*` so the explanatory comment describing the old shape does not match.
  run grep -nE '^[^#]*if ! docker run' "$RUNNER"
  [ "$status" -ne 0 ]
  grep -q 'audit_rc=0' "$RUNNER"
  grep -q 'audit_rc" -gt 1' "$RUNNER"
  grep -q 'audit_rc" -eq 1' "$RUNNER"
  # And an unrunnable audit stops the sweep rather than guessing either way.
  grep -A4 'audit_rc" -gt 1' "$RUNNER" | grep -q 'exit 4' 
}

@test "MAX_ATTEMPTS is checked outside the result.json test" {
  # Nested inside it, the guard could not see a container that died before
  # emitting a result event: no result.json meant no guard, so the cell re-ran
  # on every resume forever while ledgering cost_usd 0.
  run python3 - "$RUNNER" <<'CHECK'
import re, sys
src = open(sys.argv[1]).read()
i_guard = src.index('MAX_ATTEMPTS"')
# Walk back to the nearest enclosing `if [ -s "$dest/result.json" ]` and make
# sure the guard is not inside one.
head = src[:i_guard]
last_open = head.rfind('if [ -s "$dest/result.json" ]')
last_close = head.rfind('\n  fi\n')
assert last_open == -1 or last_close > last_open, "MAX_ATTEMPTS guard is nested inside the result.json test"
CHECK
  [ "$status" -eq 0 ]
}

@test "the sweep budget is checked before a cell, not after it" {
  # At the bottom of the loop every early `continue` jumped it, so a resume
  # already over the ceiling paid one more full cell first.
  grep -q 'sweep_spend_ok()' "$RUNNER"
  run python3 - "$RUNNER" <<'CHECK'
import sys
src = open(sys.argv[1]).read()
loop = src.index('for id in "${INSTANCES[@]}"; do')
call = src.index('sweep_spend_ok ||')
body = src[loop:call]
# Nothing may `continue` between the top of the loop body and the gate.
assert 'continue' not in body, "an early continue precedes the sweep-budget gate"
CHECK
  [ "$status" -eq 0 ]
}

@test "a sweep that voided any cell does not exit 0" {
  grep -q 'CONTAINMENT_FAILED' "$RUNNER"
  grep -q 'exit 6' "$RUNNER"
}

@test "PREFLIGHT_ONLY runs the controls and stops before any paid cell" {
  grep -q 'PREFLIGHT_ONLY' "$RUNNER"
  # It must stop AFTER the preflights and BEFORE the cell loop — DRY_RUN exits
  # before the images are even built, which is why it could not serve this role.
  run python3 - "$RUNNER" <<'CHECK'
import sys
src = open(sys.argv[1]).read()
stop = src.index('PREFLIGHT_ONLY=1 — images built')
assert src.index('=== egress preflight') < stop, "PREFLIGHT_ONLY stops before the egress preflight"
assert src.index('=== preflight') < stop, "PREFLIGHT_ONLY stops before the auth preflight"
assert stop < src.index('for id in "${INSTANCES[@]}"; do'), "PREFLIGHT_ONLY does not stop before the cell loop"
CHECK
  [ "$status" -eq 0 ]
}

@test "proxy liveness is probed per cell, not once at t=0" {
  run python3 - "$RUNNER" <<'CHECK'
import sys
src = open(sys.argv[1]).read()
loop = src.index('for id in "${INSTANCES[@]}"; do')
# rindex, not index: the header comment quotes the same command line, and
# searching forward from 0 finds that instead of the actual invocation.
review = src.rindex('-p "/code-review main"')
body = src[loop:review]
assert 'in_cell_net' in body, "no in-loop egress probe before the paid container"
CHECK
  [ "$status" -eq 0 ]
}
