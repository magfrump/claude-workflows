# Plan: Stale branch triage protocol in branch-strategy.md

## Goal
Add a triage protocol to `workflows/branch-strategy.md` for feature branches that are >7 days old without merge or rebase. The protocol asks 3 questions before continuing work: still relevant? still owner? still highest priority? Automation is deferred — this addendum is a manual checklist with a one-line detection command.

## Why
The existing workflow assumes high throughput (10+ features/day) and merging promptly. It tells the user to "Don't keep stale branches" but only in the context of post-merge cleanup, not in-flight branches that have languished. Languished branches are a real failure mode: they accumulate against a moving `main`, the original motivation can fade, and they often turn out to belong to someone else's plate now. A short triage gate forces the question before more time is sunk.

## Placement
New section **"Stale branch triage"** inserted between "Handling many feature branches" (ends at line 144) and "Setting up or resetting dev" (begins at line 146). This keeps multi-branch hygiene topics adjacent.

Also:
- Cross-reference from the "Don't keep stale branches" bullet inside "Handling many feature branches" — that bullet now covers post-merge cleanup AND points readers to the new section for in-flight stale branches.
- New row in the Quick reference table for the detection command.

## Section content (draft)

Definition: a feature branch is **stale** if its tip commit is >7 days old AND it has not been merged into `dev` or rebased onto `main` in that window.

Detection (one-liner, listed in Quick reference):
```bash
# Branches with no commit in 7+ days
for b in $(git for-each-ref --format='%(refname:short)' refs/heads/feat/); do
  age=$(( ( $(date +%s) - $(git log -1 --format=%ct "$b") ) / 86400 ))
  [ "$age" -gt 7 ] && echo "$age days  $b"
done
```

Triage gate — answer all three before resuming work on a stale branch:

1. **Still relevant?** Has `main` moved in a way that obviates this work? Has the underlying problem been solved another way, scoped out, or invalidated by a newer decision (check `docs/decisions/`)? If the answer is no, archive or delete the branch.
2. **Still owner?** Are you still the right person to land this? On parallel/async teams, ownership can drift — the branch may now belong to whoever owns the affected subsystem, or to a teammate who picked up an adjacent task. If ownership has moved, hand off (push, share the branch name, close your local copy) rather than continuing.
3. **Still highest priority?** Compared to your current top item, is finishing this branch genuinely the best use of the next session? Stale branches often signal a quiet deprioritization that was never made explicit. If the honest answer is no, park it (note the state in the branch's PR description or a working doc) and don't pretend you'll come back tomorrow.

Outcomes:
- **Continue** — questions all yes. Rebase onto current `main`, then resume.
- **Hand off** — ownership has moved. Push, share, close locally.
- **Park** — still relevant but not priority. Document state, leave branch alone, revisit at next triage.
- **Archive/delete** — no longer relevant. Delete locally and remotely; if it represented a decision worth recording, capture it in `docs/decisions/`.

Automation deferred: a future hook could surface stale-branch listings on session start, but for now run the detection one-liner manually when starting a session in this repo.

## Files touched
- `workflows/branch-strategy.md` — add new "Stale branch triage" section, update one bullet in "Handling many feature branches", add one row to Quick reference.
- `docs/working/r1-branch-stale-protocol-plan.md` — this plan.

## Verification
- Re-read the inserted section in context: triage questions read as a self-contained checklist; outcomes line up with the questions.
- Confirm Quick reference table row is consistent with surrounding entries (action verb, command in code).
- No other files modified (file-scope constraint).
