# Research: the brainstorm triggers stop counting their own output

Brief: `docs/working/briefs/2026-10-30-brainstorm-trigger-count.md` (at 330c517b).
Branch: `fix/brainstorm-trigger-count`. Workflow: research-plan-implement, divergent
design inline, then pr-prep's review-fix loop.

## Reproduction

`bats -f "step 5" test/scripts/dev-cycle.bats` with the two new cases and the old
`scripts/dev-cycle.sh`: the seed case printed `Ideas seeded since: 5` (3 of them the
brainstorm's own lines; expected 2), and the Now case printed no Now line at all.

On this repo's history: at `b3e7aaa^` (before iteration 2026-10-30-0136) the old digest
counted 14 seeds; the fix counts 7, the number that iteration found by hand. At 330c517b
the old digest counts 17; the fix counts 0 (all 17 are the owner brainstorm's own lines).

## What the code does

- `scripts/dev-cycle.sh` section 7, "Step 5": an awk resets its count at every
  `## Brainstorm YYYY-MM-DD` heading and counts `- <idea> (signal: …)` lines after it.
  A brainstorm that writes its heading and then its own ideas in that shape counts itself.
- No Now check exists: the digest prints Now's item count, and the skill fires on 0–1 ready
  items whatever happened since the last brainstorm.
- Every `## Brainstorm` heading in this repo's log was added by a commit that also changed
  `docs/roadmap.md` (checked with `git blame` on each of the ten headings): the iteration
  lands the heading with its step 6 roadmap.

## Divergent design

Seeded with `docs/constraints.md` (H1–H4, S1–S11) and the brief.

Motive (S5): real, seen three times (two iterations overrode the trigger by hand; F-003 in
philosophy-research). Status quo keeps costing a brainstorm, the expensive step, per false fire.

### The seed count

| Option | For | Against |
|---|---|---|
| A. Heading written after the ideas | no code | prose-dependent (the skill already said ideas go to the roadmap, and the loop still wrote them under the heading); a convention change with a migration; today's log stays wrong |
| B. End-of-block marker line | small awk change | prose-dependent; a convention change other repos must learn (migration); a missed marker is today's bug |
| C. Seeds carry a date | precise | changes every seeding step's shape in every repo; prose-dependent |
| D. Brainstorm ideas in a non-seed shape | no code | prose-only, the same instruction class that already failed |
| E. Count seed lines absent from the log as committed by the commit that added the last heading (git blame, checked; a multiset difference by content) | mechanical (S4), no shape change, no migration (S3), fixes every repo's existing log at once, small | needs git history (the digest already walks it); seeds written later in the same iteration commit go uncounted |

E dominates (Path A): the only option that does not depend on the model following prose,
and the only one that corrects the log as it stands. Its residual (an under-count of seeds
written after the brainstorm in its own iteration) is backed by the one-week rule.

### The Now trigger

| Option | For | Against |
|---|---|---|
| N1. Compare Now's text at the heading's commit with the working tree | shares E's commit lookup; that commit carries the post-step-6 roadmap | needs history; a reworded Now counts as changed |
| N2. Record a Now hash in the heading | no history | written in step 5, before step 6 changes Now, so it fires once more; prose-dependent; a shape change |
| N3. Record Now in the cycle record | – | another file to parse; prose-dependent |

N1 dominates (Path A).

### Failing safe

No commit for the heading (uncommitted, untracked, renamed log, a shallow clone, or a blamed
commit that did not raise the heading's count over its parent, e.g. a heading first committed
without a final newline or a later CRLF normalisation): the count falls back to
the heading (the old rule) and says so; Now prints "cannot tell … read it as changed".
These are triggers, not gates: the fall-through runs the full step (H2's pre-step rule).

## Plan

1. Bats reproductions in `test/scripts/dev-cycle.bats` (seed count, Now unchanged/changed,
   the two fallbacks). Done; red before the fix.
2. `scripts/dev-cycle.sh`: blame the last heading, check that commit added it, count seed
   lines absent from the log at that commit, print the basis; compare Now (blank lines and
   CR ignored) and print one line.
3. `skills/dev-cycle/SKILL.md` step 5: the Now trigger needs Now not `unchanged`; the seed
   count's basis; land the heading with the roadmap.
4. No migration: the idea log's shape does not change, so `guides/convention-changes.md`
   does not apply.

## Gotchas

- Failure-pattern grep: FP-084
  - FP-084 (soundness trigger fired on convention contradictions; fix: rekey the guard).
    Same family: a trigger keyed on the wrong property. This fix rekeys the count on the
    commit, not the heading line.
- `git blame` of an uncommitted line prints an all-zero id: treated as no commit.
- Command substitutions under `set -e`: `git cat-file -e` is checked before reading a blob,
  and awk reads to the end rather than `exit` (no SIGPIPE under pipefail, FP-175).
- Review round 1 (independent reviewer) found the first version's line-offset base wrong
  under a merge that resolves main's seeds above the brainstorm block (own lines counted
  again), deletions above the heading (new seeds skipped), a heading committed without a
  final newline or rewritten later (blame names a later commit), and shallow clones (blame
  names the boundary). Fixed: count by content, check the blamed commit raises the heading's
  count over its parent's, and refuse shallow repositories. Residual: a seed whose exact
  text already sat in the log at that commit is not counted again.
- Readiness is judged, not textual: an unchanged Now can become ready when a blocker clears
  elsewhere; the skill text says to name that when it fires anyway.

## Test strategy

G1 seed count after a committed brainstorm with its own lines (committed and uncommitted
later seeds). G2 Now unchanged across a CRLF re-save and another section's change; G3 Now
reworded. G4 uncommitted heading falls back; G5 no heading at all; G6 merge with main's seeds above the
block, and a roadmap absent at that commit; G7 heading without a final newline, and a shallow
clone. The existing step 5 case
(uncommitted log) still passes through the fallback.
