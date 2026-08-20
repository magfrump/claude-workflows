#!/usr/bin/env bats
# @category fast
# Guards scripts/crb-cell-status.py — the CRB arm's resume/retry gate, added by
# the 2026-08-18 pre-mortem (narrative 5).
#
# Why this exists: the predicate rejects a body containing "log in"/"logged in",
# to catch Claude Code's ~50-char "Not logged in" stub. Applied to a whole review
# body, that also rejects any genuine multi-KB review of auth code — and two of
# the five pilot instances are auth-domain (keycloak-PR36880 "Add Client resource
# type and scopes to authorization schema"; cal_com-PR11059 "OAuth credential
# sync"). The consequence is not a wrong number directly: the cell is re-paid at
# $10-40, then dropped at MAX_ATTEMPTS, and the PR silently leaves the judged
# subset — biasing which PRs the arm's headline recall comes from.
#
# The 32 result.json files already in runs/review-arms/ are used as fixtures:
# they are the corpus the predicate's rules were derived from, and pinning the
# verdict on every one of them is what makes a future edit to the rules visible.
# Note that corpus contains NO auth-domain reviews, which is exactly why it could
# not catch the bug this suite exists for — hence the synthetic cases too.
# Hermetic: reads checked-in artifacts, writes only to BATS_TEST_TMPDIR.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export SCRIPT="$REPO_ROOT/scripts/crb-cell-status.py"
}

# Write a result.json from a JSON literal and run the predicate over it.
# Sets $status (0 = complete) and $output (the reason line).
check() {
  local f="$BATS_TEST_TMPDIR/result.json"
  printf '%s' "$1" > "$f"
  run python3 "$SCRIPT" "$f"
}

# A body long enough to be a review rather than a stub.
long_body() {
  python3 -c 'print("This PR changes the authorization schema. " * 40, end="")'
}

@test "predicate script exists and is executable" {
  [ -x "$SCRIPT" ]
}

@test "a real multi-KB review is complete" {
  check "$(python3 -c '
import json
print(json.dumps({"subtype": "success", "is_error": False,
                  "result": "Findings: " + "x" * 3000}))')"
  [ "$status" -eq 0 ]
  [[ "$output" == *complete* ]]
}

# The regression this suite was written for.
@test "a long review mentioning 'logged in' is complete (auth-domain PRs)" {
  check "$(python3 -c '
import json
body = "The handler assumes the user is already logged in; see auth.go:42. " * 40
print(json.dumps({"subtype": "success", "is_error": False, "result": body}))')"
  [ "$status" -eq 0 ]
}

@test "a long review mentioning 'log in' is complete" {
  check "$(python3 -c '
import json
body = "Callers must log in before this path is reachable, so the check is dead. " * 40
print(json.dumps({"subtype": "success", "is_error": False, "result": body}))')"
  [ "$status" -eq 0 ]
}

# The two real stubs in the corpus are 51 and 56 chars, so the length floor is
# what actually rejects them — NON_REVIEW never gets consulted. Asserting the
# reason, not just the verdict, keeps that division of labour honest: if a future
# edit drops the floor, these two start depending on the substring list instead
# and the next two tests become the only thing holding the line.
@test "the short auth stub is rejected — by the length floor" {
  check '{"subtype":"success","is_error":false,"result":"Not logged in · Please run /login"}'
  [ "$status" -eq 1 ]
  [[ "$output" == *floor* ]]
}

@test "the short quota stub is rejected — by the length floor" {
  check '{"subtype":"success","is_error":false,"result":"You have hit your weekly limit · resets 9am"}'
  [ "$status" -eq 1 ]
  [[ "$output" == *floor* ]]
}

# The band NON_REVIEW actually governs: 200-300 chars — long enough to clear the
# floor, short enough that no real review is that terse (corpus minimum for a
# real review is 1,208 chars). This is the only case where the substring list is
# load-bearing, and the band is narrow on purpose: at STUB_MAX_LEN=1000 it
# reached up into real reviews, which is the failure this file guards.
@test "a mid-length auth stub is rejected by the substring rule" {
  check "$(python3 -c '
import json
body = "Not logged in · Please run /login to authenticate. " * 5
print(json.dumps({"subtype": "success", "is_error": False, "result": body}))')"
  [ "$status" -eq 1 ]
  [[ "$output" == *"non-review stub"* ]]
}

@test "a mid-length quota stub is rejected by the substring rule" {
  check "$(python3 -c '
import json
body = "You have hit your weekly limit · resets Thu 9am UTC. " * 4
print(json.dumps({"subtype": "success", "is_error": False, "result": body}))')"
  [ "$status" -eq 1 ]
  [[ "$output" == *"non-review stub"* ]]
}

@test "budget exhaustion is rejected even with a long body" {
  check "$(python3 -c '
import json
print(json.dumps({"subtype": "error_max_budget_usd", "is_error": True,
                  "result": "Partial review. " * 200}))')"
  [ "$status" -eq 1 ]
  [[ "$output" == *is_error* ]]
}

@test "a non-success subtype is rejected" {
  check '{"subtype":"error_during_execution","is_error":false,"result":"'"$(long_body)"'"}'
  [ "$status" -eq 1 ]
  [[ "$output" == *subtype* ]]
}

@test "num_turns == 0 does not by itself reject (8 e5 cells are real reviews)" {
  check "$(python3 -c '
import json
print(json.dumps({"subtype": "success", "is_error": False, "num_turns": 0,
                  "result": "Findings: " + "x" * 3000}))')"
  [ "$status" -eq 0 ]
}

@test "a body under the 200-char floor is rejected" {
  check '{"subtype":"success","is_error":false,"result":"Looks fine to me."}'
  [ "$status" -eq 1 ]
  [[ "$output" == *floor* ]]
}

@test "an empty or malformed result.json is rejected, not crashed on" {
  check 'not json at all'
  [ "$status" -eq 1 ]
  [[ "$output" == *unreadable* ]]
}

@test "a JSON array (not an object) is rejected, not crashed on" {
  check '[]'
  [ "$status" -eq 1 ]
}

# Corpus pin. The counts below were measured on the checked-in artifacts; if a
# rule change moves any cell across the line, this test says so by name.
@test "verdicts on all checked-in result.json files are unchanged" {
  run python3 - "$SCRIPT" "$REPO_ROOT" <<'PY'
import glob, importlib.util, json, os, sys
spec = importlib.util.spec_from_file_location("ccs", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
root = sys.argv[2]
complete, incomplete = [], []
# EXCLUDE the live sweep's own output dir. The glob is dynamic but the counts
# below are fixed, and run-host.sh writes runs/review-arms/crb-pipeline/<slug>/
# result.json -- which is NOT gitignored. Without this filter the first paid cell
# of the sweep turns this suite red, mid-sweep, with a message that reads as "the
# predicate regressed" -- in the same directory as the containment guard's
# non-vacuity pin. Found by the 2026-08-19 tech-debt and test-strategy critics,
# who reproduced it with one synthetic cell file.
LIVE = os.path.join(root, "runs/review-arms/crb-pipeline")
for p in sorted(glob.glob(os.path.join(root, "runs/review-arms/**/result.json"),
                          recursive=True)):
    if p.startswith(LIVE + os.sep):
        continue
    try:
        d = json.load(open(p))
    except Exception:
        incomplete.append((p, "unreadable")); continue
    ok, why = m.status(d)
    (complete if ok else incomplete).append((os.path.relpath(p, root), why))
print(f"complete={len(complete)} incomplete={len(incomplete)}")
for p, why in incomplete:
    print(f"  INCOMPLETE {p} :: {why}")
PY
  [ "$status" -eq 0 ]
  # 32 cells, of which exactly 3 are known-bad: one budget exhaustion and two
  # quota stubs. Any other split means the predicate moved.
  [[ "$output" == *"complete=29 incomplete=3"* ]]
  [[ "$output" == *"mfc-hygiene/rep1"* ]]
  [[ "$output" == *"mfc-postfix/rep2"* ]]
  [[ "$output" == *"mfc-postfix/rep3"* ]]
}

# Mutation-caught gap: the suite had no fixture in the 300-1000 char band, so
# reverting STUB_MAX_LEN to 1000 -- verbatim the defect all three k=3 replicates
# caught -- left every test green. Reported by the 2026-08-19 test-strategy
# critic's mutation run (30 mutations, 22 caught, 10 missed).
@test "STUB_MAX_LEN cannot be raised back to 1000 unnoticed" {
  # 700 chars: above the 300 cutoff, below a 1000 one. A real review this short
  # does not exist in the corpus (minimum 1,208), so it must count as COMPLETE.
  check "$(python3 -c '
import json
body = "The user must be logged in before this handler runs. " * 13
assert 300 < len(body) < 1000, len(body)
print(json.dumps({"subtype": "success", "is_error": False, "result": body}))')"
  [ "$status" -eq 0 ]
}

# Exit codes are a consumed contract: run-host.sh re-pays $10-40 on exit 1.
@test "a usage error exits 2, not 1 — it is not a verdict" {
  run python3 "$SCRIPT"
  [ "$status" -eq 2 ]
  run python3 "$SCRIPT" --help
  [ "$status" -eq 2 ]
  run python3 "$SCRIPT" a b c
  [ "$status" -eq 2 ]
}
