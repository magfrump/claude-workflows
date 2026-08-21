#!/usr/bin/env bash
# Prep truncated per-instance clones of meta-formalism-copilot for the
# Claude-Code-review eval arms (E5 cc-builtin local, E6 ultrareview).
#
# For each canon instance this creates external/cc-review-eval/<id>/ with:
#   - branch `review` checked out at the instance's reviewed head commit
#   - branch `main` pinned at the instance's context base (so "diff vs main"
#     reproduces the canon range)
#   - NO other refs, NO origin remote, and descendant objects (the later fix
#     commits — the answer key) pruned from the object store, so an agentic
#     reviewer cannot read the future via `git log --all` / `git show`.
#
# Contamination guards (review-canon §5.4 traps 1/3): after building, each
# clone is verified to contain (a) no commits outside the ancestry of the
# reviewed head, and (b) no docs/reviews/ files in the tree.
#
# Idempotent-ish: refuses to overwrite an existing clone unless --force.
set -euo pipefail
cd "$(dirname "$0")/.."
SRC="external/meta-formalism-copilot"
DST_ROOT="external/cc-review-eval"
FORCE="${1:-}"

[ -d "$SRC/.git" ] || { echo "source repo not found at $SRC" >&2; exit 1; }
mkdir -p "$DST_ROOT"

prep() { # id base head
  local id="$1" base="$2" head="$3" dst="$DST_ROOT/$1"
  if [ -e "$dst" ]; then
    if [ "$FORCE" = "--force" ]; then rm -rf "$dst"; else
      echo "$id: exists, skipping (use --force to rebuild)"; return; fi
  fi
  echo "=== $id ($base..$head)"
  # --no-hardlinks so the gc below actually drops descendant objects instead
  # of sharing the source repo's object files.
  git clone --quiet --no-hardlinks "$SRC" "$dst"
  git -C "$dst" checkout --quiet -B review "$head"
  git -C "$dst" branch -f main "$base"
  # drop every other ref, the remote, and all reflogs, then prune objects
  git -C "$dst" for-each-ref --format='%(refname)' refs/heads refs/tags refs/remotes \
    | grep -v -e '^refs/heads/review$' -e '^refs/heads/main$' \
    | xargs -r -n1 git -C "$dst" update-ref -d
  git -C "$dst" remote remove origin 2>/dev/null || true
  git -C "$dst" reflog expire --expire=now --all
  git -C "$dst" gc --quiet --prune=now
  # guard (a): nothing reachable outside the reviewed head's ancestry
  local stray; stray=$(git -C "$dst" rev-list --all --not "$head" | wc -l)
  [ "$stray" -eq 0 ] || { echo "$id: $stray stray commit(s) survived the scrub" >&2; exit 1; }
  # guard (b): the tree must not contain its OWN review (any docs/reviews file
  # mentioning the reviewed head SHA). Older rubrics from prior changes are the
  # realistic repo state every real review sees — allowed, but counted loudly.
  local rub own
  rub=$(git -C "$dst" ls-tree -r --name-only HEAD | grep -c '^docs/reviews/' || true)
  if [ "$rub" -gt 0 ]; then
    own=$(git -C "$dst" grep -l "$head" HEAD -- 'docs/reviews/' 2>/dev/null | wc -l)
    [ "$own" -eq 0 ] || { echo "$id: tree contains $own docs/reviews file(s) referencing its own head $head — answer-key leak" >&2; exit 1; }
    echo "$id: note — tree carries $rub older docs/reviews file(s) (prior changes' rubrics; no self-reference)"
  fi
  echo "$id: ok ($(git -C "$dst" rev-list --count main..review) commits under review)"
}

prep mfc-csp      d86d2dc d90d6bb
prep mfc-lean     d86d2dc c95c9cb
prep mfc-hygiene  d86d2dc f2f149b
prep mfc-secdeps  d86d2dc 8bde50c
prep mfc-deploy   d86d2dc 4329d6e
prep mfc-fscompat d86d2dc b64c1ca
prep mfc-corpus   dc6dfb0 2dc403e
prep mfc-postfix  9c9edf5 7f30210

echo "clones ready under $DST_ROOT/ (each: branch 'review' checked out, 'main' at base)"
