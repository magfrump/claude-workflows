#!/usr/bin/env bash
# Post-run containment audit for one CRB review clone.
#
# RUNS INSIDE A THROWAWAY CONTAINER, never on the host. That is the whole point:
# the clone it inspects was mounted read-write into a
# `--dangerously-skip-permissions` agent container, so its `.git/config`,
# `.git/hooks`, `.gitattributes` and `core.worktree` are attacker-controlled
# input (R1/R2, 2026-08-19 rubric). Running the inspection where a hostile
# config can only reach a disposable container is what makes it safe to inspect
# at all. run-host.sh invokes it as:
#
#   docker run --rm --network none -u node -v "$clone":/repo \
#     -v .../crb-audit-clone.sh:/audit.sh:ro \
#     --entrypoint bash <image> /audit.sh /repo <head-sha>
#
# (--entrypoint bash is not optional: the review image sets ENTRYPOINT
# ["claude"], so `<image> bash /audit.sh` would pass "bash" as an argument to
# claude. The earlier version of this comment omitted it and would not have run.)
#
# It is EVIDENCE, not prevention. Prevention is the egress allowlist the same
# script sets up; this records whether anything reached past it. A quiet pass is
# never proof of cleanliness — see docs/working/crb-direction1-setup.md.
#
# The clone is destroyed after this runs (disposable-clone design), so unlike
# the reset it replaced this never has to distinguish "undo" from "void": strays
# are counted rather than adjudicated, and only contamination changes the exit
# code. (Foreign commits are counted in full but only the first is named, to keep
# the trace readable when a fetch brought in many.)
#
# Exit: 0 = nothing detected · 1 = VOID · 2 = could not check (usage/no repo).
#
# The caller MUST distinguish all three — run-host.sh aborts the sweep on 2 and
# on docker's own 125/126/127 rather than treating them as a void, because
# publishing "contamination was DETECTED" about a $10-40 cell that was never
# checked is worse than stopping. Note the one deliberate asymmetry: a `git fsck`
# that ERRORS exits 1, not 2 — it is a check that could not certify the clone, and
# failing closed is right, but it is reported inside the VOID trace text so the
# distinction survives for a human reading the log.
set -uo pipefail

usage() { echo "usage: crb-audit-clone.sh <clone-dir> <expected-head-sha>" >&2; exit 2; }
[ $# -eq 2 ] || usage
CLONE=$1; HEAD_SHA=$2
[ -d "$CLONE/.git" ] || { echo "no .git in $CLONE" >&2; exit 2; }
case "$HEAD_SHA" in
  *[!0-9a-fA-F]*|"") echo "expected-head-sha is not a hex sha: $HEAD_SHA" >&2; exit 2 ;;
esac

# Hardened git: the config in this repository is untrusted input. Belt and
# braces on top of the container boundary — none of the commands below trigger
# hooks or a fsmonitor today, and these overrides mean that stays true if one is
# added later. safe.directory is NOT optional: the clone is host-owned, and
# without it every command fails "dubious ownership" and the audit reports
# "could not check" for every cell.
git() { command git -c safe.directory="$CLONE" -c core.hooksPath=/dev/null \
                    -c core.fsmonitor= -c protocol.ext.allow=never \
                    -C "$CLONE" "$@"; }

traces=()
note() { traces+=("$1"); }

# 1. A remote is the configured route to the merged upstream PR (the answer key).
remotes=$(git remote 2>/dev/null)
[ -z "$remotes" ] || note "remote(s) present: $(echo "$remotes" | tr '\n' ' ')"

# 2. Every fetch writes FETCH_HEAD, INCLUDING a by-URL fetch that configures no
# remote. materialize() deletes it, so its presence here is new. This is the
# check the 2026-08-18 k=3 fact-check showed was missing: `git fetch <URL>
# <refspec>` needs no remote and its objects are not walked by `rev-list --all`.
[ ! -e "$CLONE/.git/FETCH_HEAD" ] || note "FETCH_HEAD present — something fetched into this clone"

# 3. What a fetch-then-delete-the-ref leaves behind. --no-reflogs is load-bearing:
# git fsck counts reflog entries as reachability roots, so without it a fetched
# commit whose ref was deleted still reads as reachable and this check is inert.
fsck_out=$(git fsck --unreachable --no-reflogs --connectivity-only --no-progress 2>&1)
unreachable=$(printf '%s\n' "$fsck_out" | grep -c '^unreachable commit' || true)
[ "${unreachable:-0}" -eq 0 ] || note "$unreachable unreachable commit(s) — a deleted fetched ref leaves exactly this"
# fsck's own errors must not be swallowed: a check that could not run is the
# failure mode this file exists to avoid.
if printf '%s\n' "$fsck_out" | grep -q '^error:'; then
  note "git fsck errored ($(printf '%s\n' "$fsck_out" | grep -m1 '^error:' | cut -c1-160)) — cannot certify containment"
fi

# 4. Commits reachable from some ref but not from the pinned head. Descent from
# the head is NOT evidence of agent authorship (the upstream merge commit of
# this PR descends from the PR head too) — but a commit that does not descend
# cannot be agent work on top of the review, so it is reported separately.
strays=$(git rev-list --all --not "$HEAD_SHA" 2>/dev/null)
n_strays=0; n_foreign=0; first_foreign=""
for c in $strays; do
  n_strays=$((n_strays+1))
  if ! git merge-base --is-ancestor "$HEAD_SHA" "$c" >/dev/null 2>&1; then
    n_foreign=$((n_foreign+1))
    [ "$n_foreign" -gt 1 ] || first_foreign=$c
  fi
done
# The count was tallied and then never printed, so "counted in full but only the
# first is named" was true of the code and invisible in its output.
[ "$n_foreign" -eq 0 ] || note "$n_foreign commit(s) reachable outside the reviewed head and NOT descended from it (first: ${first_foreign:0:12})"

# 5. A nested repository is a clone of anything, including the answer key, that
# no check above can see: different object store, so FETCH_HEAD, fsck and
# rev-list are all blind to it. The disposable-clone restore destroys it before
# the next cell regardless; this is what makes it visible in THIS cell's record.
nested=$(find "$CLONE" -mindepth 2 -name .git -prune -print 2>/dev/null | head -5)
[ -z "$nested" ] || note "nested git repository/-ies: $(echo "$nested" | tr '\n' ' ')"

if [ "${#traces[@]}" -gt 0 ]; then
  echo "CONTAINMENT VOID:"
  printf '  - %s\n' "${traces[@]}"
  exit 1
fi
echo "audit clean — no contamination detected (${n_strays} agent commit(s) on top of the head)"
echo "NOTE: absence of a detection is not proof of cleanliness; prevention is the egress allowlist."
exit 0
