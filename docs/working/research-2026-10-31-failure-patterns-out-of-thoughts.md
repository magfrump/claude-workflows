# Research: move the failure-pattern library out of docs/thoughts/

Date: 2026-10-31
Brief: docs/working/briefs/2026-10-31-failure-patterns-out-of-thoughts.md (at b7f2e26d)
Branch: refactor/failure-patterns-out-of-thoughts
Policy: review

Failure-pattern grep: FP-151 (path-keyed guard silently disarmed by a file move), FP-008 (dangling reference after removal), FP-138 (rename makes a name contradict contents); keywords floor|rename|moved|path|migrat|hardcod

FP-151 is the shape to avoid: the floor and `FP_LIB` are keyed on the path, so the move must re-key every guard in the same change (floor rule, gate constant, loop prompt, tests), and the old key must not silently keep "working" in a repo that has not migrated.

## Readers and writers of docs/thoughts/failure-patterns.md

`rg -n "thoughts/failure-patterns"` outside `docs/working/`, `docs/reviews/`, `archive/` (and `runs/`, recorded model output):

Live (updated by this change):

| File | Role |
|---|---|
| `scripts/build-loop.sh` | `FP_LIB` (gate reader, `fp_gaps`), its header's `--check` text (line ~379), the loop prompt (lines ~1849 floor list, ~1851 FP rule) |
| `scripts/lib/dev-cycle-read.sh` | `floor()` refuses `docs/thoughts/*` as `record`; `truthrule` comment says thoughts is the floor's only rule |
| `scripts/dev-cycle.sh` | `check_fix` comment ("docs/thoughts/ stays fixable") and skip message |
| `scripts/self-improvement.sh` | `FP_LIB` harvest (writer) and three prompt mentions |
| `scripts/questions.sh` | header comment (evidence citation) |
| `workflows/research-plan-implement.md` | read side (grep step, done-when) |
| `workflows/pr-prep.md` | write side (Step 0 advisory snippet and text) |
| `workflows/codebase-onboarding.md` | mention |
| `guides/harness-feedback.md` | mention |
| `docs/thoughts/failure-patterns.md` | its own grep examples |
| `test/scripts/build-loop-check.bats`, `test/scripts/build-loop-merge.bats` | `FPL`, gap text |
| `docs/working/plan-build-loop-handoff.md` | D5 item 4, F10, T10 text (the brief asks for D5 item 4) |

Historical (keep text; amendment or log row): `docs/decisions/013-...md`, `docs/decisions/020-...md`, `docs/superpowers/plans/2026-05-18-*.md` (dated plans, left as written).

## Floor, check_fix and --cycle-diff today

- `truthrule` (lib) is the one read-as-truth rule shared by `floor`, `check_fix`, `cycle_rules` (`--cycle-diff`/`--land-cycle`) and `nrules`. `nrules` denies only its `cycle`, `settings`, `user` words, so a `record` word does not stop a review-policy branch.
- `floor` adds `docs/thoughts/*` (`record`) on top of `truthrule`; `check_fix` and `cycle_rules` both let the cycle fix `docs/thoughts/` in-cycle. So today the library is fixable in-cycle but floored for self-merge.
- Remaining check_fix vs cycle_rules difference (pre-existing, documented in build-loop.sh's header): `check_fix` also refuses `docs/working/`, `docs/reviews/` and anything the tree import walk reaches; `cycle_rules` lets the cycle's own files through and does no walk.

## Migrations

`scripts/lib/migrations.sh` registry, `mig ID CONVENTION FP PATH ERE REMEDY`; CONVENTION is one of `questions roadmap brief record`, each fingerprinted by `conv_source`. The digest (section 7b) prints `pending` while PATH holds a line ERE matches; the cycle files a `you: terminal` entry per pending migration (step 1b). None of the four conventions covers the library's location.

## Design decisions (divergent design, seeded with docs/constraints.md)

### D1: how the floor refuses docs/failure-patterns.md

1. Add it to `truthrule` under the existing `record` word. All four consumers agree: floor refuses, `check_fix` and `cycle_rules` refuse in-cycle, `nrules` lets a review-policy branch add entries. One rule, one sentence (S3).
2. A floor-only rule, as `docs/thoughts/` was. Keeps in-cycle fixes possible, but leaves a deliberate check_fix/floor difference to document, and lets an unreviewed in-cycle commit edit a file the gate compares entry numbers against.
3. A new `truthrule` word (`library`). Same effect as 1 plus a new sentence in `floor_why`, `cycle_rules` wording and tests.

Option 1 dominates: the brief calls the file "a truth file, like docs/constraints.md", the cycle has no in-cycle use of the library (no mention in `skills/dev-cycle/SKILL.md`), and it removes a difference rather than adding one. Result: `docs/thoughts/` is fixable in-cycle and self-mergeable; `docs/failure-patterns.md` is neither, and a review-policy branch can still add an entry. check_fix and cycle_rules now match on both paths; the pre-existing difference above stays as written in the header.

Amended in review (iteration 1, M1): the old path `docs/thoughts/failure-patterns.md` is a `record` too, so in a repo not yet migrated no self-merge or in-cycle fix edits or deletes the library before the owner's `git mv` (FP-151: the old key stays guarded). The rest of `docs/thoughts/` is free.

### D2: the gate in a repo that has not migrated yet

Between the release and the owner running the migration, main still holds `docs/thoughts/failure-patterns.md`.

| Option | Loops keep working? | Fails loud with remedy? | Code paths | Risk |
|---|---|---|---|---|
| A. Fallback: read the old path when main lacks the new one | yes | no message | two library paths in gate, floor and prompt | silent two-path regime that must be retired later (S3); FP-151 inverse: the old floor key must stay too |
| B. Refuse every branch while the old file exists | no: all loops stop | yes | one | stops loops that never touch the library (S10: a fail-closed alternative exists) |
| C. Refuse only when the library is needed: a branch with fix(...) commits and no `Failure-pattern skip:` line gets a gap naming the remedy; entries at either path do not count while main holds the old file | yes, except fix branches without a skip line, which get the remedy | yes | one, plus one existence read | a fix loop is refused until migration (or a skip line) |
| D. Nothing special | fix branches get a gap naming only the new path; a loop following the prompt creates a second library at the new path, whose numbers can collide and which makes the remedy's `git mv` fail | partly | one | silent split library |

C dominates: H2 (fail closed, the refusal names the way forward: the remedy, or a skip line), S10 (only the branches that need the library wait; the cycle files the remedy at step 1b on its next iteration), S3 (one library path). Chosen: C.

### D3: which convention the migration line uses

1. A new convention `library` in `CONVENTIONS`, fingerprinted from the `FP_LIB=` line of `scripts/build-loop.sh`: a later move of the library changes the fingerprint and the merge check demands a new line.
2. Reuse an existing convention name (`record`) with its current FP: passes the check but mislabels the digest line and ties nothing to the library's source.

Option 1 dominates (the digest names it correctly, and the move is guarded the way the guide intends). The line: `mig failure-patterns-out-of-thoughts library FP docs/thoughts/failure-patterns.md '^' 'git mv docs/thoughts/failure-patterns.md docs/failure-patterns.md'`. ERE `^` matches any line, so the migration is pending while the old file exists and holds anything.

## Files read

Last verified: 2026-10-31

- scripts/lib/dev-cycle-read.sh (truthrule, truthwalk, ownfile, GATE_CODE, floor, floor_why)
- scripts/dev-cycle.sh (check_fix, digest section 7b)
- scripts/build-loop.sh (header --check/--cycle-diff text, nrules, fp_blob/fp_gaps, cycle_diff, cycle_rules, loop prompt)
- scripts/lib/migrations.sh, guides/convention-changes.md, test/scripts/convention-migrations.bats
- test/scripts/build-loop-check.bats (floor, truthrule, fp tests), test/scripts/build-loop-dispatch.bats, test/scripts/dev-cycle.bats (check_fix)
- docs/working/plan-build-loop-handoff.md (D5, F10, T10), docs/thoughts/failure-patterns.md, hooks/live-verify-gate.sh (no enforcement file touched)
