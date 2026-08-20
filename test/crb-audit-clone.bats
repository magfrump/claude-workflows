#!/usr/bin/env bats
# @category fast
# Guards scripts/crb-audit-clone.sh — the post-run containment audit that
# replaced the void half of reset_clone() when clones became disposable.
#
# The audit is EVIDENCE, not the control: prevention is the egress allowlist
# (docker/egress-allowlist), and a quiet pass is never proof of cleanliness. But
# a contaminated cell scores plausibly HIGH, so a missed void is the worst
# outcome the arm has — which makes the load-bearing cases here the ones that
# must still VOID, exactly as in the reset suite this file inherits from:
#   * a re-added remote — the configured route to the merged upstream PR;
#   * FETCH_HEAD — written by `git fetch <URL>`, which needs no remote at all
#     and whose objects `rev-list --all` does not walk (2026-08-18 k=3
#     fact-check, refuted by execution in all three replicates);
#   * an unreachable commit under --no-reflogs — what fetch-then-delete-the-ref
#     leaves behind, and inert without that flag because git fsck counts reflog
#     entries as reachability roots (2026-08-19 iteration-2 fact-check);
#   * a commit that does not descend from the reviewed head;
#   * a nested repository — a separate object store, invisible to all of the
#     above.
# Plus the case that must NOT void: an agent commit on top of the head. The
# payload's own repo instructions tell the reviewing agent to commit, so voiding
# on that would void most cells of the sweep.
#
# The script runs inside a container in production. Nothing in it is
# docker-specific, so these tests drive it directly against fixture repos.
# Hermetic: no network, no clones, throwaway repos in BATS_TEST_TMPDIR.

setup_file() {
  export REPO_ROOT="$(cd "$BATS_TEST_DIRNAME/.." && pwd)"
  export AUDIT="$REPO_ROOT/scripts/crb-audit-clone.sh"
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
  # materialize() leaves neither behind; mirror that so their presence in a test
  # means what it means in production.
  git -C "$CLONE" reflog expire --expire=now --all
  git -C "$CLONE" gc --quiet --prune=now
  rm -f "$CLONE/.git/FETCH_HEAD"
}

audit() { run bash "$AUDIT" "$CLONE" "$HEAD_SHA"; }

@test "a pristine clone audits clean" {
  audit
  [ "$status" -eq 0 ]
  [[ "$output" == *"audit clean"* ]]
}

@test "an agent commit on top of the head does NOT void" {
  echo "review notes" > "$CLONE/REVIEW.md"
  git -C "$CLONE" add REVIEW.md; git -C "$CLONE" commit -qm "agent: review work"
  audit
  [ "$status" -eq 0 ]
  [[ "$output" == *"1 agent commit(s) on top of the head"* ]]
}

@test "a surviving remote VOIDS" {
  git -C "$CLONE" remote add origin https://github.com/upstream/answer-key
  audit
  [ "$status" -eq 1 ]
  [[ "$output" == *"CONTAINMENT VOID"* ]]
  [[ "$output" == *"remote(s) present"* ]]
}

@test "a FETCH_HEAD trace VOIDS" {
  printf '%s\tbranch\n' "$BASE" > "$CLONE/.git/FETCH_HEAD"
  audit
  [ "$status" -eq 1 ]
  [[ "$output" == *"FETCH_HEAD present"* ]]
}

# The shape the k=3 fact-check executed: fetch by URL (no remote configured),
# commit the content on top of `review`, delete the fetched ref. rev-list --all
# and the remote check both pass it; the unreachable-commit check is what fires.
@test "a fetched-then-deleted ref VOIDS via the unreachable commit" {
  echo "the merged upstream fix" > "$CLONE/answer.txt"
  git -C "$CLONE" add answer.txt
  git -C "$CLONE" commit -qm "answer key"
  git -C "$CLONE" reset -q --hard "$HEAD_SHA"
  git -C "$CLONE" reflog expire --expire=now --all   # the only root that hid it
  run git -C "$CLONE" rev-list --all --not "$HEAD_SHA"
  [ -z "$output" ]            # invisible to the stray check, by construction
  audit
  [ "$status" -eq 1 ]
  [[ "$output" == *"unreachable commit"* ]]
}

@test "a commit that does not descend from the head VOIDS" {
  git -C "$CLONE" checkout -q --orphan foreign
  echo other > "$CLONE/other.txt"
  git -C "$CLONE" add other.txt; git -C "$CLONE" commit -qm "unrelated history"
  git -C "$CLONE" checkout -q review
  audit
  [ "$status" -eq 1 ]
  [[ "$output" == *"NOT descended from it"* ]]
  # The count is now reported, not merely tallied — it was computed into a
  # variable nothing ever printed.
  [[ "$output" == *"1 commit(s) reachable outside"* ]]
}

@test "a nested repository VOIDS" {
  mkdir -p "$CLONE/vendor/answer-key"
  git -C "$CLONE/vendor/answer-key" init -q
  audit
  [ "$status" -eq 1 ]
  [[ "$output" == *"nested git repository"* ]]
}

# A check that cannot run must not read as a pass — the failure mode this whole
# area exists to avoid.
@test "a corrupt object store reports 'cannot certify' rather than passing" {
  # git writes pack files read-only; chmod first rather than skipping the case.
  obj=$(ls "$CLONE"/.git/objects/pack/*.pack 2>/dev/null | head -1)
  [ -n "$obj" ] || obj=$(ls -d "$CLONE"/.git/objects/??/* | head -1)
  chmod u+w "$obj"
  truncate -s 1 "$obj"
  audit
  [ "$status" -eq 1 ]
  [[ "$output" == *"CONTAINMENT VOID"* ]]
}

@test "usage errors exit 2, distinct from a void" {
  run bash "$AUDIT" "$CLONE"
  [ "$status" -eq 2 ]
  run bash "$AUDIT" "$CLONE" "not-a-sha"
  [ "$status" -eq 2 ]
  run bash "$AUDIT" "$BATS_TEST_TMPDIR/nope" "$HEAD_SHA"
  [ "$status" -eq 2 ]
}

# Non-vacuity: --no-reflogs is what makes the unreachable-commit check able to
# fire at all. Without it git fsck treats reflog entries as roots and the check
# is inert — the exact defect the iteration-2 fact-check found in the code this
# script inherited.
@test "the unreachable-commit check is non-vacuous only because of --no-reflogs" {
  echo x > "$CLONE/answer.txt"; git -C "$CLONE" add answer.txt
  git -C "$CLONE" commit -qm smuggled
  git -C "$CLONE" reset -q --hard "$HEAD_SHA"
  run git -C "$CLONE" fsck --unreachable --connectivity-only --no-progress
  # Reflogs still present and counted as roots: nothing reads as unreachable,
  # so a version of this check without --no-reflogs passes the smuggled commit.
  [[ "$output" != *"unreachable commit"* ]]
  run git -C "$CLONE" fsck --unreachable --no-reflogs --connectivity-only --no-progress
  [[ "$output" == *"unreachable commit"* ]]
  audit
  [ "$status" -eq 1 ]
}
