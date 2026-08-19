#!/usr/bin/env bats
# @category fast
# Guards reset_clone()/classify_strays() in scripts/crb-materialize.py, added by
# the 2026-08-18 pre-mortem (narratives 1 and 2).
#
# Why this exists: the between-cells reset was `git checkout -- .` plus
# `git clean -qfdx`, which restores tracked files FROM THE INDEX. It undid
# neither a commit nor a `git add`, and the containment check reads refs and
# remotes rather than the index — so a staged edit rode invisibly into the next
# attempt, and a commit (which the payload's own CLAUDE.md instructs the
# reviewing agent to make) voided the cell AND left the clone failing its
# pre-run check forever after.
#
# The fix has to cut a fine line: undo agent work, but still VOID for the thing
# the control exists to catch. So the load-bearing assertions here are the two
# negatives — a re-added remote and a commit outside the reviewed ancestry must
# still fail, or the fix has quietly disarmed the answer-key guard.
#
# Hermetic: builds throwaway git repos in BATS_TEST_TMPDIR, no network, no
# clones, and never touches external/crb-eval or the real manifest.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export SCRIPT="$REPO_ROOT/scripts/crb-materialize.py"
}

setup() {
  export CLONE="$BATS_TEST_TMPDIR/clone"
  rm -rf "$CLONE"; mkdir -p "$CLONE"
  git -C "$CLONE" init -q
  git -C "$CLONE" config user.email t@t; git -C "$CLONE" config user.name t
  echo base > "$CLONE/f.txt"
  git -C "$CLONE" add f.txt; git -C "$CLONE" commit -qm base
  export BASE=$(git -C "$CLONE" rev-parse HEAD)
  git -C "$CLONE" branch -f main "$BASE"
  echo change > "$CLONE/f.txt"
  git -C "$CLONE" commit -qam "the PR under review"
  export HEAD_SHA=$(git -C "$CLONE" rev-parse HEAD)
  git -C "$CLONE" branch -f review "$HEAD_SHA"
  git -C "$CLONE" checkout -q review
  # materialize() leaves no remote; mirror that.
  git -C "$CLONE" remote remove origin 2>/dev/null || true
}

# Call reset_clone() + verify_containment() the way --reset does.
reset_and_verify() {
  run python3 - "$SCRIPT" "$CLONE" "$HEAD_SHA" "$BASE" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("mat", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
dst, head, base = Path(sys.argv[2]), sys.argv[3], sys.argv[4]
try:
    note = m.reset_clone(dst, "fixture", head, base)
    n, stat = m.verify_containment(dst, "fixture", head)
except Exception as e:
    print(f"VOID: {e}")
    sys.exit(1)
print(f"OK: {note}")
PY
}

@test "a clean clone verifies and needs no reset" {
  reset_and_verify
  [ "$status" -eq 0 ]
  [[ "$output" == "OK: " ]]
}

# Narrative 1: the agent commits its rubric, as the payload CLAUDE.md tells it to.
@test "an agent commit on top of the reviewed head is reset, not voided" {
  echo "# rubric" > "$CLONE/docs-review.md"
  git -C "$CLONE" add docs-review.md
  git -C "$CLONE" commit -qm "docs(review): rubric"
  reset_and_verify
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 agent commit"* ]]
  [ "$(git -C "$CLONE" rev-parse review)" = "$HEAD_SHA" ]
  [ ! -f "$CLONE/docs-review.md" ]
}

@test "the clone still verifies on the NEXT cell after an agent commit" {
  git -C "$CLONE" commit -q --allow-empty -m "agent work"
  reset_and_verify
  [ "$status" -eq 0 ]
  # The pre-run check of the following cell — this is what used to fail forever.
  reset_and_verify
  [ "$status" -eq 0 ]
  [[ "$output" == "OK: " ]]
}

# Narrative 2: `git add` of a tracked file survived `git checkout -- .`.
@test "a staged edit to a tracked file is undone" {
  echo contaminated > "$CLONE/f.txt"
  git -C "$CLONE" add f.txt
  reset_and_verify
  [ "$status" -eq 0 ]
  [[ "$output" == *"dirty path"* ]]
  [ "$(cat "$CLONE/f.txt")" = change ]
  [ -z "$(git -C "$CLONE" status --porcelain)" ]
}

@test "an unstaged edit and an untracked file are undone" {
  echo contaminated > "$CLONE/f.txt"
  echo junk > "$CLONE/untracked.md"
  reset_and_verify
  [ "$status" -eq 0 ]
  [ "$(cat "$CLONE/f.txt")" = change ]
  [ ! -f "$CLONE/untracked.md" ]
}

@test "a gitignored file the review created is removed" {
  printf 'ignored/\n' > "$CLONE/.gitignore"
  # `review` is checked out, so the commit advances it — a `git branch -f review`
  # here would fail exactly the way materialize() warns about at
  # crb-materialize.py's materialize(), which documents the same footgun.
  git -C "$CLONE" add .gitignore; git -C "$CLONE" commit -qm ignore
  export HEAD_SHA=$(git -C "$CLONE" rev-parse HEAD)
  mkdir -p "$CLONE/ignored"; echo cached > "$CLONE/ignored/state.json"
  reset_and_verify
  [ "$status" -eq 0 ]
  [ ! -f "$CLONE/ignored/state.json" ]
}

@test "a branch the agent created is pruned" {
  git -C "$CLONE" branch scratch
  git -C "$CLONE" checkout -q scratch
  git -C "$CLONE" commit -q --allow-empty -m "on a side branch"
  reset_and_verify
  [ "$status" -eq 0 ]
  run git -C "$CLONE" for-each-ref --format='%(refname)' refs/heads
  [[ "$output" != *scratch* ]]
  [ "$(git -C "$CLONE" rev-parse HEAD)" = "$HEAD_SHA" ]
}

@test "main is restored if the agent deletes or moves it" {
  git -C "$CLONE" branch -D main
  reset_and_verify
  [ "$status" -eq 0 ]
  [ "$(git -C "$CLONE" rev-parse main)" = "$BASE" ]
}

# ── The two that must still VOID. If either of these starts passing, the
# answer-key guard has been disarmed and the arm's numbers are meaningless.

@test "a re-added remote still VOIDS the cell" {
  git -C "$CLONE" remote add origin https://example.invalid/x.git
  reset_and_verify
  [ "$status" -eq 1 ]
  [[ "$output" == *VOID* ]]
  [[ "$output" == *remote* ]]
}

@test "a commit outside the reviewed ancestry still VOIDS the cell" {
  # The shape a fetch of the merged upstream future would leave: a ref pointing
  # at history that does not descend from the reviewed head.
  git -C "$CLONE" checkout -q --orphan upstream-future
  git -C "$CLONE" rm -rqf . 2>/dev/null || true
  echo "the merged fix" > "$CLONE/fix.txt"
  git -C "$CLONE" add fix.txt
  git -C "$CLONE" commit -qm "the answer key"
  reset_and_verify
  [ "$status" -eq 1 ]
  [[ "$output" == *VOID* ]]
  [[ "$output" == *"NOT descended"* ]]
}

# ── Fetch traces. The k=3 fact-check on cf6e7c9 refuted, by execution in all
# three replicates, the claim that "with no remote there is no route to fetch".
# `git fetch <URL> <refspec>` needs no remote and lands in .git/FETCH_HEAD,
# which `git rev-list --all` does not walk. r1 fetched an answer key with zero
# remotes, deleted the ref, committed the content on top of the head — and the
# guard passed it as benign agent work. These tests pin the detection that
# replaced that claim.

# Build a separate repo to act as the "upstream future" holding the merged fix.
make_answer_key_repo() {
  export UPSTREAM="$BATS_TEST_TMPDIR/upstream"
  rm -rf "$UPSTREAM"; mkdir -p "$UPSTREAM"
  git -C "$UPSTREAM" init -q
  git -C "$UPSTREAM" config user.email t@t; git -C "$UPSTREAM" config user.name t
  echo "the merged upstream fix" > "$UPSTREAM/ANSWER_KEY.txt"
  git -C "$UPSTREAM" add ANSWER_KEY.txt
  git -C "$UPSTREAM" commit -qm "the answer key"
}

@test "r1's exact attack: fetch by URL, delete the ref, commit on top — VOIDS" {
  make_answer_key_repo
  # No remote is configured at any point.
  [ -z "$(git -C "$CLONE" remote)" ]
  git -C "$CLONE" fetch -q "file://$UPSTREAM" master:refs/heads/stolen 2>/dev/null \
    || git -C "$CLONE" fetch -q "file://$UPSTREAM" main:refs/heads/stolen
  git -C "$CLONE" cat-file -p refs/heads/stolen:ANSWER_KEY.txt > "$CLONE/leaked.txt"
  git -C "$CLONE" update-ref -d refs/heads/stolen
  git -C "$CLONE" add leaked.txt
  git -C "$CLONE" commit -qm "review notes"   # descends from head — looks benign
  [ -z "$(git -C "$CLONE" remote)" ]          # still no remote
  reset_and_verify
  [ "$status" -eq 1 ]
  [[ "$output" == *VOID* ]]
}

@test "a bare fetch by URL leaves FETCH_HEAD and VOIDS" {
  make_answer_key_repo
  git -C "$CLONE" fetch -q "file://$UPSTREAM" 2>/dev/null || true
  [ -f "$CLONE/.git/FETCH_HEAD" ]
  reset_and_verify
  [ "$status" -eq 1 ]
  [[ "$output" == *VOID* ]]
  [[ "$output" == *FETCH_HEAD* ]]
}

# The regression risk of the fix itself: fetch_traces() runs `git fsck
# --no-reflogs`, so the commits reset_clone() discards ARE unreachable and would
# void the next cell if the reflogs were not expired. This is the test that the
# detection does not eat the benign case it was carved around.
#
# The iteration-2 fact-check found the earlier version of this pair vacuous:
# without --no-reflogs, fsck treated the reflog as a root, nothing ever read as
# unreachable, and deleting scrub_object_store() left the suite green. The
# companion test below now fails without the call, which is what makes this one
# mean something.
@test "consecutive benign cells stay clean — reset restores the object baseline" {
  git -C "$CLONE" commit -q --allow-empty -m "cell 1 agent commit"
  reset_and_verify
  [ "$status" -eq 0 ]
  [ ! -f "$CLONE/.git/FETCH_HEAD" ]
  git -C "$CLONE" commit -q --allow-empty -m "cell 2 agent commit"
  reset_and_verify
  [ "$status" -eq 0 ]
  reset_and_verify
  [ "$status" -eq 0 ]
  [[ "$output" == "OK: " ]]
}

# Non-vacuity: with scrub_object_store() stubbed out, the SAME benign sequence
# must fail. Without this, "consecutive benign cells stay clean" passes whether
# or not the call exists — which is exactly what the iteration-2 fact-check
# caught, by deleting the call and watching the suite stay green.
@test "scrub_object_store is load-bearing — benign sequence VOIDS without it" {
  git -C "$CLONE" commit -q --allow-empty -m "cell 1 agent commit"
  run python3 - "$SCRIPT" "$CLONE" "$HEAD_SHA" "$BASE" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("mat", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
m.scrub_object_store = lambda dst: None          # the call under test, removed
dst, head, base = Path(sys.argv[2]), sys.argv[3], sys.argv[4]
m.reset_clone(dst, "fixture", head, base)        # cell 1: discards the commit
try:                                             # cell 2 pre-run check
    m.reset_clone(dst, "fixture", head, base)
    m.verify_containment(dst, "fixture", head)
except Exception as e:
    print(f"VOID: {e}"); sys.exit(1)
print("OK — scrub_object_store was NOT load-bearing")
PY
  [ "$status" -eq 1 ]
  [[ "$output" == *VOID* ]]
  [[ "$output" == *unreachable* ]]
}

# fsck's exit status is no longer swallowed, so a clone that makes fsck error
# would void every cell of the sweep. materialize() removes the remote before
# pruning refs precisely so refs/remotes/origin/HEAD is not left dangling —
# `update-ref -d` would dereference that symref and delete its target instead.
@test "a dangling origin/HEAD symref is detected, and scrub heals it" {
  git -C "$CLONE" symbolic-ref refs/remotes/origin/HEAD refs/heads/nonexistent
  run python3 - "$SCRIPT" "$CLONE" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("mat", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
dst = Path(sys.argv[2])
print("BEFORE:", m.fetch_traces(dst))
m.scrub_object_store(dst)
print("AFTER:", m.fetch_traces(dst))
PY
  [ "$status" -eq 0 ]
  [[ "$output" == *"AFTER: []"* ]]
}

# Real clones are SHALLOW (--depth 50). git fsck on a shallow repo can complain
# about the grafted boundary; --connectivity-only is what keeps it quiet. If
# this fires, every cell of the sweep voids on a false positive.
@test "fetch-trace detection is quiet on a SHALLOW clone" {
  make_answer_key_repo
  for i in 1 2 3; do
    echo "c$i" >> "$UPSTREAM/f.txt"
    git -C "$UPSTREAM" add f.txt; git -C "$UPSTREAM" commit -qm "c$i"
  done
  SHALLOW="$BATS_TEST_TMPDIR/shallow"
  rm -rf "$SHALLOW"
  git clone -q --depth=1 "file://$UPSTREAM" "$SHALLOW"
  git -C "$SHALLOW" config user.email t@t; git -C "$SHALLOW" config user.name t
  [ -f "$SHALLOW/.git/shallow" ]
  git -C "$SHALLOW" remote remove origin
  run python3 - "$SCRIPT" "$SHALLOW" <<'PY'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("mat", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
dst = Path(sys.argv[2])
m.scrub_object_store(dst)          # the baseline materialize() leaves
print("TRACES:", m.fetch_traces(dst))
PY
  [ "$status" -eq 0 ]
  [[ "$output" == "TRACES: []" ]]
}

# ── CLI-level coverage. The mutation run found that `--reset` could be made a
# COMPLETE no-op with all 38 tests green: every case above drives reset_clone()
# via importlib, while run-host.sh calls only the CLI. These exercise the path
# production actually uses.

cli() { run python3 "$SCRIPT" "$@"; }

# Drives main() with DST_ROOT and MANIFEST pointed at the fixture, so the CLI
# dispatch is exercised end to end. $1 = extra argv. Prints RC and output.
run_cli() {
  run python3 - "$SCRIPT" "$CLONE" "$HEAD_SHA" "$BASE" "$@" <<'PY'
import importlib.util, json, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("mat", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
clone, head, base, extra = Path(sys.argv[2]), sys.argv[3], sys.argv[4], sys.argv[5:]
m.DST_ROOT = clone.parent
man = clone.parent / "manifest.json"
man.write_text(json.dumps({clone.name: {"head": head, "base": base}}))
m.MANIFEST = man
# The slug must follow its mode flag directly: --reset takes nargs="+", so
# `--reset --dry-run SLUG` leaves it with zero values and argparse errors.
sys.argv = ["crb-materialize.py", extra[0], clone.name] + extra[1:]
try:
    m.main()
    print("RC=0")
except SystemExit as e:
    print(f"RC={e.code}")
PY
}

@test "the --reset CLI actually resets — not just the library function" {
  git -C "$CLONE" commit -q --allow-empty -m "agent commit"
  [ "$(git -C "$CLONE" rev-parse review)" != "$HEAD_SHA" ]
  run_cli --reset
  [[ "$output" == *"RC=0"* ]]
  [[ "$output" == *"containment ok"* ]]
  # The CLI, not reset_clone() directly, must have moved the ref back.
  [ "$(git -C "$CLONE" rev-parse review)" = "$HEAD_SHA" ]
}

@test "the --reset CLI VOIDS on contamination" {
  make_answer_key_repo
  git -C "$CLONE" fetch -q "file://$UPSTREAM" 2>/dev/null || true
  run_cli --reset
  [[ "$output" != *"RC=0"* ]]
  [[ "$output" == *"CONTAINMENT CHECK FAILED"* ]]
}

@test "--dry-run does NOT perform a destructive reset" {
  git -C "$CLONE" commit -q --allow-empty -m "agent commit"
  moved=$(git -C "$CLONE" rev-parse review)
  run_cli --reset --dry-run
  [[ "$output" == *"RC=0"* ]]
  [[ "$output" == *"Nothing touched"* ]]
  [[ "$output" != *"containment ok"* ]]
  # Still moved: --dry-run must not have reset anything.
  [ "$(git -C "$CLONE" rev-parse review)" = "$moved" ]
}

@test "--heal clears a pre-2026-08-19 clone's baseline artifacts" {
  make_answer_key_repo
  git -C "$CLONE" fetch -q "file://$UPSTREAM" 2>/dev/null || true
  [ -f "$CLONE/.git/FETCH_HEAD" ]
  run_cli --heal
  [[ "$output" == *"RC=0"* ]]
  [[ "$output" == *"healed"* ]]
  [ ! -f "$CLONE/.git/FETCH_HEAD" ]
}

@test "--heal is offered as the remediation for a pre-2026-08-19 clone" {
  run grep -c -- "--heal" "$BATS_TEST_DIRNAME/../runs/review-arms/crb-pipeline/run-host.sh"
  [ "$status" -eq 0 ]
  [ "$output" -ge 1 ]
}

@test "a tag pointing outside the reviewed ancestry still VOIDS the cell" {
  git -C "$CLONE" checkout -q --orphan sidecar
  git -C "$CLONE" rm -rqf . 2>/dev/null || true
  echo x > "$CLONE/x.txt"; git -C "$CLONE" add x.txt
  git -C "$CLONE" commit -qm sidecar
  git -C "$CLONE" tag answer-key
  git -C "$CLONE" checkout -q review
  git -C "$CLONE" branch -D sidecar 2>/dev/null || true
  reset_and_verify
  [ "$status" -eq 1 ]
  [[ "$output" == *VOID* ]]
}
