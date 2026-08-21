#!/usr/bin/env bats
# @category fast
# Guards the disposable-clone design in scripts/crb-materialize.py
# (snapshot_baseline / restore_clone), which replaced the in-place reset_clone()
# that test/crb-containment-reset.bats used to pin.
#
# Why the replacement: the reset repaired the clone with HOST git commands run
# against a `.git` that a --dangerously-skip-permissions container had just had
# write access to. The 2026-08-19 review executed five host-side code-execution
# paths out of that (hooks, core.hooksPath, core.fsmonitor, a smudge filter
# reachable from tracked .gitattributes alone) plus a core.worktree redirect
# that deleted files in an unrelated host directory. Wiping and re-extracting a
# hash-pinned baseline means the host never reads that `.git` at all.
#
# The load-bearing assertions here are therefore different from the old file's.
# They are not "does it still void" — voiding moved to the audit, which
# test/crb-audit-clone.bats pins — they are:
#   (a) a restore leaves NO trace of what the previous cell did, including the
#       cases the old reset could not undo (a commit, a staged edit, a nested
#       repo, a deleted `main`, a re-added remote);
#   (b) a baseline that does not match its manifest hash REFUSES to restore,
#       because a tampered baseline is a silently contaminated every-cell;
#   (c) --dry-run does not destroy anything, the defect A1 recorded against the
#       mode this one replaced.
#
# Hermetic: throwaway git repos in BATS_TEST_TMPDIR, no network, and DST_ROOT /
# BASELINE_ROOT / MANIFEST are all monkeypatched away from the real ones.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export SCRIPT="$REPO_ROOT/scripts/crb-materialize.py"
  export AUDIT="$REPO_ROOT/scripts/crb-audit-clone.sh"
}

setup() {
  export WORK="$BATS_TEST_TMPDIR/work"
  export CLONE="$WORK/clones/fixture"
  mkdir -p "$CLONE" "$WORK/baselines"
  git -C "$CLONE" init -q
  git -C "$CLONE" config user.email t@t; git -C "$CLONE" config user.name t
  echo base > "$CLONE/f.txt"
  mkdir -p "$CLONE/docs"; echo '# notes' > "$CLONE/docs/notes.md"
  git -C "$CLONE" add -A; git -C "$CLONE" commit -qm base
  export BASE=$(git -C "$CLONE" rev-parse HEAD)
  git -C "$CLONE" branch -f main "$BASE"
  echo change > "$CLONE/f.txt"
  git -C "$CLONE" commit -qam "the PR under review"
  export HEAD_SHA=$(git -C "$CLONE" rev-parse HEAD)
  git -C "$CLONE" branch -f review "$HEAD_SHA"
  git -C "$CLONE" checkout -q review
}

# Load crb-materialize with DST_ROOT/BASELINE_ROOT/MANIFEST redirected into the
# test tmpdir, then run one snippet against it.
run_mat() {
  run python3 - "$SCRIPT" "$WORK" "$@" <<'PY'
import importlib.util, json, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("mat", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
work = Path(sys.argv[2])
m.DST_ROOT = work / "clones"
m.BASELINE_ROOT = work / "baselines"
m.MANIFEST = work / "manifest.json"
op = sys.argv[3]
mf = json.loads(m.MANIFEST.read_text()) if m.MANIFEST.exists() else {}
try:
    if op == "snapshot":
        rec = m.snapshot_baseline(m.DST_ROOT / "fixture", "fixture")
        mf.setdefault("fixture", {}).update(rec)
        m.MANIFEST.write_text(json.dumps(mf, indent=2))
        print("SNAPSHOT OK")
    elif op == "restore":
        print("RESTORE OK:", m.restore_clone("fixture", mf["fixture"]))
    elif op == "index":
        print(json.dumps(m.artifact_index(m.DST_ROOT / "fixture"), sort_keys=True))
except Exception as e:
    print(f"FAILED: {e}")
    sys.exit(1)
PY
}

@test "snapshot then restore is a byte-identical round trip" {
  run_mat snapshot
  [ "$status" -eq 0 ]
  before=$(cd "$CLONE" && git rev-parse review main && cat f.txt)
  run_mat restore
  [ "$status" -eq 0 ]
  after=$(cd "$CLONE" && git rev-parse review main && cat f.txt)
  [ "$before" = "$after" ]
}

@test "restore erases an agent commit, a staged edit and a created branch" {
  run_mat snapshot
  echo agent > "$CLONE/f.txt"
  git -C "$CLONE" commit -qam "agent work"
  echo staged > "$CLONE/f.txt"; git -C "$CLONE" add f.txt
  git -C "$CLONE" branch agent-branch
  run_mat restore
  [ "$status" -eq 0 ]
  [ "$(git -C "$CLONE" rev-parse review)" = "$HEAD_SHA" ]
  [ "$(cat "$CLONE/f.txt")" = "change" ]
  run git -C "$CLONE" rev-parse --verify agent-branch
  [ "$status" -ne 0 ]
  [ -z "$(git -C "$CLONE" status --porcelain)" ]
}

# The case the old `git clean -qfdx` silently skipped (needed -ff), and which no
# containment check could see: a different object store is invisible to
# FETCH_HEAD, `fsck --no-reflogs` and `rev-list --all`. A wipe does not care.
@test "restore destroys a nested clone of the answer key" {
  run_mat snapshot
  mkdir -p "$CLONE/vendor/answer-key"
  git -C "$CLONE/vendor/answer-key" init -q
  echo "the merged fix" > "$CLONE/vendor/answer-key/fix.txt"
  run_mat restore
  [ "$status" -eq 0 ]
  [ ! -d "$CLONE/vendor" ]
}

@test "restore erases a re-added remote and a deleted main" {
  run_mat snapshot
  git -C "$CLONE" remote add origin https://example.invalid/x
  git -C "$CLONE" branch -D main
  run_mat restore
  [ "$status" -eq 0 ]
  [ -z "$(git -C "$CLONE" remote)" ]
  [ "$(git -C "$CLONE" rev-parse main)" = "$BASE" ]
}

# A baseline is the definition of "clean" for every later cell, so an unverified
# one would launder contamination into all of them at once.
@test "a tampered baseline refuses to restore" {
  run_mat snapshot
  printf 'junk' >> "$WORK/baselines/fixture.tar"
  run_mat restore
  [ "$status" -ne 0 ]
  [[ "$output" == *"sha256 mismatch"* ]]
  [[ "$output" == *"refusing to restore"* ]]
}

@test "restore refuses when the manifest carries no baseline hash" {
  run_mat snapshot
  python3 - "$WORK/manifest.json" <<'PY'
import json, sys
d = json.load(open(sys.argv[1])); d["fixture"].pop("baseline_sha256")
json.dump(d, open(sys.argv[1], "w"))
PY
  run_mat restore
  [ "$status" -ne 0 ]
  [[ "$output" == *"no baseline_sha256"* ]]
}

@test "artifact_index covers .md/.json, skips .git, and ignores symlinks" {
  ln -s /etc/passwd "$CLONE/evil.md"
  mkdir -p "$CLONE/sub"; echo '{}' > "$CLONE/sub/x.json"
  echo 'not an artifact' > "$CLONE/sub/x.txt"
  run_mat index
  [ "$status" -eq 0 ]
  [[ "$output" == *"docs/notes.md"* ]]
  [[ "$output" == *"sub/x.json"* ]]
  [[ "$output" != *"evil.md"* ]]
  [[ "$output" != *"x.txt"* ]]
  [[ "$output" != *".git/"* ]]
}

# A1 on the 2026-08-19 rubric: --dry-run was silently ignored by the destructive
# mode it replaced, which performed the full reset while advertising otherwise.
@test "CLI --restore --dry-run destroys nothing" {
  run python3 "$SCRIPT" --restore fixture --dry-run
  [ "$status" -eq 0 ]
  [[ "$output" == *"Nothing touched"* ]]
  [ -f "$CLONE/f.txt" ]
}

# The CLI is the ONLY surface run-host.sh uses, so a mutation that no-ops the
# library function must fail here too (A3: the old suite drove reset_clone via
# importlib only, so replacing the call site with `note = ""` stayed green).
@test "CLI --restore reaches restore_clone (no-op mutation would fail)" {
  run_mat snapshot
  echo agent > "$CLONE/f.txt"
  cp "$WORK/manifest.json" "$BATS_TEST_TMPDIR/m.json"
  run env CRB_TEST_WORK="$WORK" python3 - "$SCRIPT" "$WORK" <<'PY'
import importlib.util, json, subprocess, sys
from pathlib import Path
# Drive main() the way the shell does, with the roots redirected.
src = Path(sys.argv[1]).read_text()
work = Path(sys.argv[2])
src = src.replace('DST_ROOT = WORKSPACE / "external/crb-eval"',
                  f'DST_ROOT = Path("{work}/clones")')
src = src.replace('MANIFEST = WORKSPACE / "runs/review-arms/crb/instances.json"',
                  f'MANIFEST = Path("{work}/manifest.json")')
src = src.replace('BASELINE_ROOT = DST_ROOT / ".baselines"',
                  f'BASELINE_ROOT = Path("{work}/baselines")')
patched = work / "mat_patched.py"
patched.write_text(src)
r = subprocess.run([sys.executable, str(patched), "--restore", "fixture"],
                   capture_output=True, text=True)
print(r.stdout, r.stderr)
sys.exit(r.returncode)
PY
  [ "$status" -eq 0 ]
  [ "$(cat "$CLONE/f.txt")" = "change" ]
}

# ── scrub_object_store non-vacuity ──────────────────────────────────────────
# The deleted crb-containment-reset.bats had a dedicated pin for this and it did
# NOT carry over: `grep -rn scrub_object_store test/` returned zero hits, while
# the 2026-08-19 fact-check reproduced by execution that the function is still
# load-bearing, and the test-strategy pass showed its whole body could be
# replaced with `return` leaving 37/37 green.
#
# What it is load-bearing FOR: materialize()'s own fetches leave `.git/FETCH_HEAD`
# and unreachable objects behind, and crb-audit-clone.sh voids a cell on exactly
# those two signals. Without the scrub, EVERY baseline carries them, EVERY cell
# voids, and the audit's checks mean nothing. So both halves are asserted here:
# the signals are present before, and absent after.

@test "scrub_object_store is non-vacuous: it clears the signals the audit voids on" {
  # Reproduce what materialize() leaves behind: an object whose ref is then gone
  # (reads as unreachable under --no-reflogs) plus a FETCH_HEAD.
  git -C "$CLONE" checkout -q -b tmp-fetched
  echo fetched > "$CLONE/fetched.txt"
  git -C "$CLONE" add fetched.txt; git -C "$CLONE" commit -qm "as if fetched"
  git -C "$CLONE" checkout -q review
  git -C "$CLONE" branch -qD tmp-fetched
  printf '%s\tbranch\n' "$HEAD_SHA" > "$CLONE/.git/FETCH_HEAD"

  # BEFORE: both signals present. Asserted, so this case cannot pass by the
  # fixture quietly failing to set them up.
  [ -e "$CLONE/.git/FETCH_HEAD" ]
  run git -C "$CLONE" fsck --unreachable --no-reflogs --connectivity-only --no-progress
  [[ "$output" == *"unreachable commit"* ]]

  run python3 - "$SCRIPT" "$CLONE" <<'SCRUB'
import importlib.util, sys
from pathlib import Path
spec = importlib.util.spec_from_file_location("mat", sys.argv[1])
m = importlib.util.module_from_spec(spec); spec.loader.exec_module(m)
m.scrub_object_store(Path(sys.argv[2]))
SCRUB
  [ "$status" -eq 0 ]

  # AFTER: both gone. A no-op body fails here.
  [ ! -e "$CLONE/.git/FETCH_HEAD" ]
  run git -C "$CLONE" fsck --unreachable --no-reflogs --connectivity-only --no-progress
  [[ "$output" != *"unreachable commit"* ]]
}

# The consequence, end to end: a baseline taken from a tree still carrying those
# signals produces a clone the audit voids. This is what makes the coupling
# visible — remove the scrub from materialize() and every cell voids as
# contamination, which is indistinguishable from a contaminated sweep.
@test "a baseline carrying fetch traces yields a clone the audit VOIDS" {
  printf '%s\tbranch\n' "$HEAD_SHA" > "$CLONE/.git/FETCH_HEAD"
  run_mat snapshot
  [ "$status" -eq 0 ]
  run_mat restore
  [ "$status" -eq 0 ]
  run bash "$AUDIT" "$CLONE" "$HEAD_SHA"
  [ "$status" -eq 1 ]
  [[ "$output" == *"FETCH_HEAD present"* ]]
}

# ── the baseline's OTHER half ───────────────────────────────────────────────
# The baseline is one contract with two artifacts. Until the 2026-08-19 review,
# only the tar was hash-pinned, atomically published and gated before the cell;
# the index was written non-atomically, hashed by nothing, and first touched at
# harvest time — i.e. AFTER the $10-40 review was paid. A stale index silently
# changes which files count as "the pipeline wrote this", and nothing could see
# it. These cases pin the fix on the half that used to be unprotected.

@test "snapshot records a hash for the index as well as the tar" {
  run_mat snapshot
  [ "$status" -eq 0 ]
  run python3 -c 'import json,sys; d=json.load(open(sys.argv[1]))["fixture"]; print(d["baseline_sha256"][:8], d["baseline_index_sha256"][:8])' "$WORK/manifest.json"
  [ "$status" -eq 0 ]
  [ -n "$output" ]
}

@test "a tampered index refuses to restore, before the cell is paid for" {
  run_mat snapshot
  printf '{"planted.md": "0000"}' > "$WORK/baselines/fixture.index.json"
  run_mat restore
  [ "$status" -ne 0 ]
  [[ "$output" == *"INDEX sha256 mismatch"* ]]
  [[ "$output" == *"refusing to restore"* ]]
}

@test "a missing index refuses to restore" {
  run_mat snapshot
  rm -f "$WORK/baselines/fixture.index.json"
  run_mat restore
  [ "$status" -ne 0 ]
  [[ "$output" == *"no baseline index"* ]]
}

# A baseline written before the index was pinned must not silently restore: the
# manifest field is absent, which is exactly the state a half-upgraded arm is in.
@test "a manifest with no index hash refuses to restore" {
  run_mat snapshot
  python3 - "$WORK/manifest.json" <<'STRIP'
import json, sys
d = json.load(open(sys.argv[1])); d["fixture"].pop("baseline_index_sha256")
json.dump(d, open(sys.argv[1], "w"))
STRIP
  run_mat restore
  [ "$status" -ne 0 ]
  [[ "$output" == *"baseline_index_sha256"* ]]
}

# One owner for the layout. run-host.sh used to spell `.baselines/$id.tar` and
# `.baselines/$id.index.json` itself, in two places — the hand-copy failure
# crb_common.py's docstring exists to prevent, reproduced in new code.
@test "baseline_paths is the single definition of the layout, and the runner uses it" {
  run python3 "$SCRIPT" --baseline-paths some-slug
  [ "$status" -eq 0 ]
  [[ "${lines[0]}" == *"/.baselines/some-slug.tar" ]]
  [[ "${lines[1]}" == *"/.baselines/some-slug.index.json" ]]
  grep -q -- '--baseline-paths' "$REPO_ROOT/runs/review-arms/crb-pipeline/run-host.sh"
  run grep -nE '\.baselines/\$(id|slug)' "$REPO_ROOT/runs/review-arms/crb-pipeline/run-host.sh"
  [ "$status" -ne 0 ]
}

# The mode that baselined an existing clone in place is gone: it was the last
# host-git-against-an-untrusted-`.git` path, and the runner printed it as the
# remedy on the path every pre-baseline clone takes.
@test "there is no mode that baselines an existing clone in place" {
  run python3 "$SCRIPT" --snapshot fixture
  [ "$status" -ne 0 ]
  [[ "$output" == *"unrecognized arguments"* || "$output" == *"invalid choice"* || "$output" == *"usage"* ]]
  run grep -n -- '--snapshot' "$REPO_ROOT/runs/review-arms/crb-pipeline/run-host.sh"
  [ "$status" -ne 0 ]
}
