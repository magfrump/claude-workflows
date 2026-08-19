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

@test "the egress preflight tests both directions and blocks the sweep" {
  # Positive leg, filter leg, and route leg. Dropping any one leaves a control
  # that can pass for the wrong reason.
  grep -q 'api.anthropic.com reachable through the proxy' "$RUNNER"
  grep -q 'github.com refused through the proxy' "$RUNNER"
  grep -q 'github.com unroutable without the proxy' "$RUNNER"
  # Each failure path must stop the sweep rather than warn.
  n=$(grep -c 'exit 5' "$RUNNER")
  [ "$n" -ge 3 ]
}
