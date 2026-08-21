#!/usr/bin/env bats
# @category fast
# The first EXECUTING tests for runs/review-arms/crb-pipeline/run-host.sh.
#
# Why this file exists, and why the earlier answer was wrong. `run-host.sh` is
# 690 lines and every dollar the arm spends flows through it, and until now it
# had no test that ran it — the coverage was `bash -n` plus greps over its text.
# Two review rounds deferred this as "a scope call bigger than the commit". The
# 2026-08-19 terminal test-strategy pass withdrew that call by execution:
#
#   * reverting `egress_leg` to its broken pipeline form left 64/64 green;
#   * changing its halt to a warn ALSO left 64/64 green — and the preflight then
#     printed "the allowlist is NOT filtering. The answer key is reachable from a
#     review cell" and went on to reach the paid cell, exit 0;
#   * eight of eight structural pins were defeated, two of them by grep's
#     substring match (`grep -q 'audit_rc" -gt 1'` is satisfied by `-gt 10`,
#     which makes an unchecked cell bank as clean).
#
# Text pins cannot see wiring. The fix is small: a PATH shim that answers as
# `docker` and a scripted exit code, so the branches can be RUN. Everything here
# is what those mutations would have to survive.
#
# Hermetic: no docker, no network, no API key, no real clone. The shim records
# argv and returns what the case tells it to; $ROOT is redirected to a fixture
# tree so nothing touches external/crb-eval or the real run dir.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export RUNNER="$REPO_ROOT/runs/review-arms/crb-pipeline/run-host.sh"
}

setup() {
  export FIX="$BATS_TEST_TMPDIR/fix"
  export BIN="$FIX/bin"
  mkdir -p "$BIN" "$FIX/log"
  export DOCKER_LOG="$FIX/log/docker.argv"
  : > "$DOCKER_LOG"
  # Default: every docker call succeeds and prints an HTTP code, so the egress
  # legs pass unless a case says otherwise.
  export SHIM_HTTP="000"          # what a PROXIED curl to a blocked host returns
  export SHIM_API_HTTP="401"      # ... and to the allowlisted host
  export SHIM_DIRECT="000"        # ... and what the NO-proxy leg returns
  export SHIM_EXIT="0"

  cat > "$BIN/docker" <<'SHIM'
#!/usr/bin/env bash
# Stands in for docker. Records argv, then answers per the SHIM_* env vars.
printf '%s\0' "$@" >> "$DOCKER_LOG"; printf '\n---\n' >> "$DOCKER_LOG"
# The no-direct-route leg is the one docker run with NO proxy env, which is how
# it is told apart here — the same property that makes it a distinct leg.
case "$*" in
  *audit.sh*)            exit "${SHIM_AUDIT_EXIT:-0}" ;;
  *"api.anthropic.com"*) echo "${SHIM_API_HTTP}" ;;
  *github.com*)
    case "$*" in
      *HTTPS_PROXY*) echo "${SHIM_HTTP}" ;;
      *)             echo "${SHIM_DIRECT}" ;;
    esac ;;
  *)                     : ;;
esac
exit "${SHIM_EXIT:-0}"
SHIM
  chmod +x "$BIN/docker"
  export PATH="$BIN:$PATH"
}

# Run just the egress preflight block, with the runner's own `set -euo pipefail`
# and its real egress_leg/in_cell_net definitions extracted verbatim. Extracting
# by line range rather than re-typing is what makes this a test OF the runner
# and not of a copy of it.
run_preflight() {
  python3 - "$RUNNER" "$FIX/preflight.sh" "$REPO_ROOT" <<'EXTRACT'
import re, sys
src = open(sys.argv[1]).read()
start = src.index('in_cell_net() {')
end = src.index('# ── Preflight: auth AND skill registration')
block = src[start:end]
open(sys.argv[2], "w").write(
    "set -euo pipefail\n"
    f'ROOT={sys.argv[3]!r}\n'
    'EGRESS_NET=crb-test-net\nPROXY_URL=http://proxy:3128\nREVIEW_IMAGE=img\n'
    'NET_CREATE_CMD="docker network create --internal --subnet 172.31.250.0/24 crb-test-net"\n'
    + block)
EXTRACT
  run bash "$FIX/preflight.sh"
}

@test "harness sanity: a fully passing preflight exits 0 and runs the legs" {
  export SHIM_HTTP=403          # refused through the proxy
  # SHIM_DIRECT stays 000: no route at all without the proxy.
  run_preflight
  [ "$status" -eq 0 ]
  [[ "$output" == *"reachable through the proxy"* ]]
  [[ "$output" == *"refused"* ]]
  [[ "$output" == *"unroutable without the proxy"* ]]
}

# The defect the extraction was supposed to fix, and which no test could see:
# a failing leg must HALT. Both the old pipeline form (errexit killed the shell
# at the pipeline, status 1, no message) and a halt->warn mutation reached the
# paid cell.
@test "a failing egress leg halts with exit 5 and says why" {
  export SHIM_HTTP=200          # github SERVED through the proxy
  run_preflight
  [ "$status" -eq 5 ]
  [[ "$output" == *"allowlist is NOT filtering"* ]]
  [[ "$output" == *"refusing to spend"* ]]
}

# The fail-open the terminal security pass executed: a docker run that never
# starts leaves stdout empty, and an empty observation used to read as a pass on
# the leg the other two depend on.
@test "an empty observation from a dead docker halts rather than passing" {
  export SHIM_API_HTTP=""
  run_preflight
  [ "$status" -eq 5 ]
  [[ "$output" == *"not evidence"* ]]
}

@test "the preflight never reaches later legs after one fails" {
  export SHIM_API_HTTP=""       # leg 1 fails
  run_preflight
  [ "$status" -eq 5 ]
  [[ "$output" != *"unroutable without the proxy"* ]]
}

# --internal is the single flag the containment story rests on, and the runner
# must hand the leg the command it actually runs.
@test "a network created without a bare --internal halts the preflight" {
  export SHIM_HTTP=403
  run_preflight   # regenerate, then rewrite the captured command
  sed -i 's/--internal --subnet/--internal=false --subnet/' "$FIX/preflight.sh"
  run bash "$FIX/preflight.sh"
  [ "$status" -eq 5 ]
  [[ "$output" == *"NOT created with a bare --internal flag"* ]]
}

# ── the audit's three-valued contract, executed ─────────────────────────────
# `grep -q 'audit_rc" -gt 1'` is satisfied by `-gt 10`, which drops exit 2
# through both branches and banks an unchecked cell as clean. Running the branch
# is the only instrument that catches that.

audit_branch() {   # <audit exit code>
  python3 - "$RUNNER" "$FIX/audit.sh" <<'EXTRACT'
import sys
src = open(sys.argv[1]).read()
start = src.index('  audit_rc=0')
end = src.index('  # The clone is left as the container wrote it;')
open(sys.argv[2], "w").write(
    "set -uo pipefail\n"
    'id=fixture; clone=/nonexistent; head_sha=deadbeef\n'
    'ROOT="${REPO_ROOT}"; REVIEW_IMAGE=img; dest="$DEST"\n'
    + src[start:end])
EXTRACT
  SHIM_AUDIT_EXIT="$1" run bash "$FIX/audit.sh"
}

@test "audit exit 0 is clean, 1 voids, 2 aborts the sweep" {
  export DEST="$FIX/cell"; mkdir -p "$DEST"; echo '{}' > "$DEST/result.json"

  audit_branch 0
  [ "$status" -eq 0 ]
  [ ! -f "$DEST/CONTAINMENT_FAILED" ]

  audit_branch 2
  [ "$status" -eq 4 ]
  [[ "$output" == *"could not run"* ]]
  [[ "$output" == *"NOT a void"* ]]
  [ ! -f "$DEST/CONTAINMENT_FAILED" ]   # an unchecked cell is not a contaminated one

  audit_branch 1
  [ "$status" -eq 7 ]                   # halts on a void unless overridden
  [ -f "$DEST/CONTAINMENT_FAILED" ]
  run python3 -c 'import json,sys; d=json.load(open(sys.argv[1])); print(d["subtype"], d["is_error"])' "$DEST/result.json"
  [[ "$output" == "containment_failed True" ]]
}

# docker's own failures (125 daemon error / 126 not executable / 127 not found)
# are "could not check", not contamination.
@test "docker's own failure codes abort rather than void" {
  export DEST="$FIX/cell2"; mkdir -p "$DEST"; echo '{}' > "$DEST/result.json"
  for rc in 125 126 127; do
    rm -f "$DEST/CONTAINMENT_FAILED"
    audit_branch "$rc"
    [ "$status" -eq 4 ]
    [ ! -f "$DEST/CONTAINMENT_FAILED" ]
  done
}

@test "CONTINUE_ON_VOID keeps going but still records the void" {
  export DEST="$FIX/cell3"; mkdir -p "$DEST"; echo '{}' > "$DEST/result.json"
  CONTINUE_ON_VOID=1 audit_branch 1
  [ "$status" -eq 0 ]
  [ -f "$DEST/CONTAINMENT_FAILED" ]
  [[ "$output" == *"continuing despite the void"* ]]
}
