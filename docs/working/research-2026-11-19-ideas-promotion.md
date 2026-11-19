# Research: an Idea carrying owner-reported friction leaves Ideas

Brief: `docs/working/briefs/2026-11-19-ideas-promotion.md` (read from 610130f5).
Branch: `fix/dev-cycle-ideas-promotion`. Workflow: research-plan-implement, no plan gate.

- Failure-pattern grep: `rg -n -i 'ideas|roadmap|unranked|promot|grep -c|pipefail|ifs|empty field' docs/failure-patterns.md` -> FP-176 (brainstorm trigger denominator), FP-184 (section 5 read as nothing open when the questions files were not read), FP-129, FP-175 and FP-182 (`grep` exit 1 under `pipefail`/`set -e`), FP-144 (IFS splitting). FP-184 shaped the NOT-checked case below; FP-129/182 caught a first draft that counted records with `grep -c` (exit 1 on zero matches would have ended the digest under `set -euo pipefail`), replaced with a bash loop before any commit.
- Failure-pattern skip: the one fix(...) commit is review round 1's narrowing of a new match (a word read anywhere in an item, before it ever ran in a cycle), a one-line obvious fix with no reusable cause; the `grep -c` near-miss never landed and is FP-129/FP-182's shape.

## What the code does today (acceptance criterion 1)

- `docs/working/feedback/<project>.md` holds a project's harness-feedback entries (`### F-NNN · slug`, a Feature/Date/Verdict line). `scripts/harness-feedback.py ingest` (commits 0321ce95, 7b0479ee) appends one seed per new entry to `docs/working/idea-log.md`, shaped `- harness feedback, <feature> (<verdict>): <slug>: ... (signal: harness feedback <project> F-NNN ...)`.
- Step 5 (brainstorm) fires on 10+ seeds, reads the idea log and writes surviving ideas to the roadmap's Ideas, unranked, each with its signal (7b0479ee's brainstorm turned F-004..F-019 into eight Ideas naming `philosophy-research F-NNN`).
- Step 6 keeps Ideas as a pool: nothing moves an Idea anywhere. Its one check (22735b6e, the roadmap-staleness fix) covers Now and Next only: digest section 5 lists each Now and Next item with the open entries and watches it names, and step 6 acts on every unheld one.
- Step 8 briefs only Now items, then Next items, while slots are free.

So an Idea leaves Ideas only when a brainstorm or the owner moves it; F-019 and F-011 moved on 2026-11-19 only on the owner's request.

**Ideas carrying a feedback or owner-report signal today** (this branch's digest, run on the roadmap at 610130f5): 13 of the Ideas section's items.

| # | Idea | Carries | Verdict |
|---|---|---|---|
| 1 | Models answer their own questions from the repo's docs | owner request | parked (Q-274 [1]): stays |
| 2 | The live-verify hook reads a merge commit's staged diff against HEAD only | F-009 (its loop's pre-mortem) | unheld |
| 3 | Re-dispatch a conflict that touches only generated files | philosophy-research F-010, F-006 | unheld |
| 4 | Step 0 tests worktree creation first | philosophy-research F-018 | unheld |
| 5 | A per-repo health-checkout preparation line | philosophy-research F-016 | unheld |
| 6 | A judgment entry's "Why it's yours" quotes the constraint | philosophy-research F-007 | unheld |
| 7 | Loops wait on a file or job in the foreground | philosophy-research F-012, F-013 | unheld |
| 14 | cc-isolated's manual worktree fallback as the default | herald F-009 | unheld |
| 15 | Triage the herald friction list as one unit | herald F-001..F-012 | unheld |
| 37 | Cut merge and release friction | owner brainstorm 2026-10-29, area A | unheld |
| 38 | Keep the owner from habituating to asks | owner brainstorm 2026-10-29, area B | unheld |
| 39 | The cycle cannot create a project's harness-feedback file | philosophy-research F-002 | unheld |
| 40 | Release soon after Q-235 | philosophy-research F-001 | unheld (Q-235 answered) |

Not counted by the shapes chosen (they say "your answer N", "the user's feedback" or "the owner's note"): "Repeat the self-answer measurement", "Check that code review follows decision 031's k policy", "An audit-dimension menu", "Brainstorm confidence routing", "Build-loop future directions". These are owner answers from walk-throughs, not reported friction, and most already carry their answer; widening the match to them is a later call if one sits.

## Divergent design (acceptance criterion 2)

Constraints weighed: `docs/constraints.md` at 610130f5 (S10 attention, S4 scripts over prose, S3 one source of truth, S2 always-loaded cost, S5 motive, S8 small units, H2 fail closed, H3 hermetic tests) plus the brief's out-of-scope lines.

Motive (S5): real. F-019's friction went on for three days after ingest while it sat in Ideas, and the owner had to notice and ask by hand; the status quo spends the owner's attention on finding the gap.

| Option | What it is | S10 attention | S4 / S3 | Verdict |
|---|---|---|---|---|
| A. Digest list + step 6 rule | Section 5 lists Ideas carrying reported friction with their open holds; step 6 moves each unheld one to Now as agent work, or asks about all of them in one `you: judgment` entry per iteration | zero when moved as agent work; at most one ask per iteration | the shape lives in the script (one source); prose only says what to do with the list | picked |
| B. Ingest into Now | `harness-feedback.py ingest` writes Now items instead of idea-log seeds | zero asks, but floods Now with raw seeds (16 at once on 7b0479ee) | a second writer of the roadmap outside the cycle (S3); skips the brainstorm's verdict filter (F-017 is a "works" entry, F-008 was already fixed) | rejected: does not cover owner reports outside feedback files either |
| C. Status quo | the owner moves an Idea by request | the cost the motive measured | none | rejected: the gap the brief exists for |
| D. Step 6 prose only | step 6 tells the cycle to scan Ideas for feedback | zero | judgment over 80+ items each iteration, no checkable list (S4) | rejected |
| E. A with an age threshold | promote only after N days in Ideas | fewer moves | a tunable with no measurement (S7) | rejected: a sitting Idea is already the failure; nothing argues for a delay |

Path A: option A dominates on every axis the brief names. Choices inside it, each with one clear answer:

- **Shapes matched**: a harness-feedback ID `F-NNN` (not `FP-NNN`, the failure-pattern IDs) anywhere in the item, or the words owner request/report/reported/brainstorm, owner's request/report. The shape list is printed in the digest's own header line, and the skill points at it rather than restating it (S3).
- **Parked and dropped Ideas** are printed with the verdict "says parked or dropped" so step 6 skips them without rereading; the Ideas template already requires such an item to carry the owner answer behind it. Only the item's head (its text before the first `Signal:`) is read for the words, so a signal reporting dropped events is no parking (review round 1, A1).
- **When section 3 failed** (questions files not read), no Idea is listed as unheld (FP-184's lesson): the NOT-checked line says Ideas were not listed either.
- **The ask**: one `you: judgment` entry per iteration covering every Idea that needs an owner call, never one per Idea (S10). The default is Now as agent work, which costs no attention.
- **Record template**: the `6.` line's moved list now names "Done, Ideas or Now"; `mig record-6-ideas-to-now` records the change (every older record stays valid).
- **First run**: the next iteration sees 12 unheld Ideas and moves most to Now, a one-time batch; step 8 then briefs them by slot, so no burst of dispatches follows.

## Plan and verification

1. `scripts/dev-cycle.sh` section 5: read the first `## Ideas` section's items too, keep those carrying a shape, print them after Now and Next with what they carry and their open holds (one printer function for both lists).
2. `skills/dev-cycle/SKILL.md`: step 5 (name the source in a shape the digest reads), step 6 (Ideas definition, the new bullet, the record template's `6.` line).
3. `scripts/lib/migrations.sh`: the `record` registry line.
4. Tests: two bats cases in `test/scripts/dev-cycle.bats` (the list and its verdicts, FP-NNN and Done ignored, a sub-step signal, only the first Ideas heading; the empty case and the NOT-checked case). `bats test/scripts/dev-cycle.bats` and `scripts/health-check.sh`.
