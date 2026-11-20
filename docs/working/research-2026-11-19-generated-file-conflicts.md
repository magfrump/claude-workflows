# Research: approved branches that go stale on a generated file

Brief: `docs/working/briefs/2026-11-19-generated-file-conflicts.md` (at 5e335ef87b77). Policy: self-merge. Branch: `docs/generated-file-conflicts`. Paths: none (this doc is the whole output, criterion 4).

Workflow: research-plan-implement with divergent design inline (one design choice, ten candidates). No code, test, skill or workflow changes, and no command beyond `git`, `rg` and reads (criterion 5).

## What the code does today

- **The conflict refusal.** `check_line` (`scripts/build-loop.sh:1548-1553`, used by both `--check` and `--merge`) computes `merge-tree --write-tree MAIN_SHA TIP` (`merge_result`, `:1229`). Exit 1 prints `refuse BRIEF: BRANCH conflicts with the default branch`. It does not say which paths conflict.
- **The failure-pattern refusal.** `fp_gaps` (`:1576`) runs under every authority, so `--check`, which writes a review brief's merge entry, already reports a gap before the owner is asked. The F-006 case (the owner approves, then `--merge --approved` finds a gap) can now only come from a rule that changes between `--check` and `--merge`, such as an image release in between.
- **The approval's tie.** `approval()` (`:1628`) accepts Q-NNN only when it is answered `[1]` on the default branch's commit and its heading is exactly `Q-NNN · merge[-gate]-STEM-TIP12`. `--expect` binds the full tip (header comment `:475-489`). Any new commit on the branch, a merge of main included, needs a new merge entry. D7 and D8 in `docs/working/plan-build-loop-handoff.md` say what this rests on: merges are computed from the two commits, and answers are read only from main's commit.
- **Dev-cycle step 7** (`skills/dev-cycle/SKILL.md:693-800`):
  - a self-merge `ready` branch: "A conflict is `stopped`, and so is a failure-pattern refusal";
  - a review `ready` branch: "A `refuse` verdict is filed as `stopped`";
  - an approved merge entry: "any other refusal is filed as `stopped`".

  A stopped entry offers **[1] re-dispatch** and **[2] drop**, and `[1]` sends the brief to step 10 (`Applied: Q-NNN=redispatch`). Dispatches are capped at 4 per brief (`:1010`, D1).
- **What F-009 changed** (brief `docs/working/briefs/closed/2026-11-16-loop-may-merge-default-in.md`, merged as Q-296). The dispatch prompt now lets a re-dispatched loop run `git merge --no-edit refs/heads/$MAIN` into its own branch, re-run its review and tests, and end `ready`. When the conflict cannot be resolved without discarding a side, it ends `stopped`. That removed the *permission* answer (Q-141 in philosophy-research). It did not remove the stopped entry that asks for the re-dispatch, or the second merge entry at the new tip.

## Motive (S5, criterion 2)

**How often an approved branch went stale on a generated file:**

- **This repo:** never. There are two stopped entries in total, Q-246 and Q-247 (questions archive, 2026-11-01). Both were conflicts on hand-written text, a decision-log row and a skill passage, after another unit merged first. Both were answered `[1] re-dispatch`. The repo has no committed generated file that loop branches touch (questions indexes are the cycle's own).
- **belegarth-herald:** no conflict or stale-branch report in `docs/working/feedback/belegarth-herald.md`.
- **philosophy-research:** F-010 (2026-11-02) reports Q-145, Q-146 and Q-147 in one day, all caused by the generated `docs/thoughts/theorem-catalog/README.md` count lines. In the same repo, F-006 (Q-129, Q-130: gap refusals after approval) and F-009 (Q-138 to Q-140: hand conflicts while waiting) are the same kind of round trip. No later report of the README case was filed through F-019 (2026-11-14). That repo's questions file cannot be read from here, so the counts are those its feedback names.

**Does F-009 already remove the owner's second answer?** No, for two reasons:

- A review brief that conflicts still costs a re-dispatch answer, and then a merge answer at the new tip, because the approval is pinned to TIP12.
- A self-merge brief that conflicts still costs the re-dispatch answer.

**What has changed underneath F-010.** Its branches were review-policy only because F-008 forced it: the self-merge floor refused `docs/thoughts/`. F-008 is now fixed. `truthrule` (`scripts/lib/dev-cycle-read.sh:991`) lists only `docs/failure-patterns.md` and `docs/thoughts/failure-patterns.md` under `docs/thoughts/`, as idea-log line 286 records. So philosophy-research's Lean briefs can be self-merge again. If they are, a README conflict costs one answer (re-dispatch), not two. It also arises more often, because every catalog-editing loop now carries the README on its branch.

**Conclusion.** The problem still arises. The answer that recurs in every repo and every case is the *re-dispatch* answer. It has been paid about 10 times in the cases on record (Q-246, Q-247; philosophy-research Q-129, Q-130, Q-138 to Q-140, Q-145 to Q-147), and every one whose answer can be read here was re-dispatch. The *second merge* answer is specific to review briefs, and F-010's review briefs were an F-008 artefact. Closing the item would leave the re-dispatch answer in place.

## Gotchas

Failure-pattern grep: FP-012
- FP-012 (stale-merge-head-poisons-next-merge): a half-finished merge left behind breaks the next one. Any option in which a loop merges main in and then re-runs must keep F-009's `git merge --abort` on a stop, so that no MERGE_HEAD survives into a later dispatch. The chosen option adds no new merge site: it reuses F-009's.
- The grep (`rg -n -i -e conflict -e stale -e generated -e merge-tree -e redispatch -e re-dispatch -e approv docs/failure-patterns.md`) also matched FP-013, FP-014, FP-068, FP-083, FP-091, FP-109, FP-125, FP-161, FP-164 and FP-166 on the word "stale". None of them concerns merges, approvals or generated files.
- "Generated" is not something the gate can verify. Whether a file's content really is its generator's output can be checked only by running the repo's generator. That is repo code, which H1 forbids the gate from running.

## Divergent design: how the handoff treats a branch whose only conflict is a generated file

**Prior pruning grep:** no matches found for conflict, generated, re-dispatch, redispatch, approv in the `Pruned candidates` sections of `docs/decisions/*.md`. 040's "[5] generated view" is about the questions doc, an unrelated decision.

### 1. Candidates

1. **No change.** Keep filing a conflict or gap as `stopped`; the owner answers re-dispatch, then the new merge entry.
2. **Repo setting plus gate-side regeneration.** A `Generated paths:` setting in `docs/dev-cycle.md`; `--merge` runs the repo's generator over the merge result.
3. **Repo setting plus gate-side ignore.** For the listed paths, `--merge` resolves the conflict by taking main's side (or the branch's side) and lands. The count lines are then wrong until somebody regenerates them.
4. **Loop regenerates, approval carried over.** After F-009's merge-in, the loop regenerates the listed files. `approval()` accepts the old Q-NNN for the new tip T2 when T2 descends from the approved T1, and every path that differs between T1 and T2 is either listed as generated or equals main's side.
5. **Auto re-dispatch, any conflict or gap.** Step 7 sends a conflict or failure-pattern refusal straight back to the loop, with no stopped entry: F-009 already tells the loop how to merge main in. It sends each tip back once, within the dispatch cap of 4. A review brief still gets its fresh merge entry.
6. **Auto re-dispatch, generated-only conflicts.** As 5, but only when every conflicting path is in a `Generated paths:` setting. The gate would have to print the conflicting paths.
7. **The orchestrator merges main into the loop branch itself** and regenerates, with no loop run.
8. **Keep generated files off loop branches.** Briefs leave generated paths out of `Paths:`, and the cycle regenerates once after each merge, as the F-008 workaround did for catalog text.
9. **Union merge driver** via `.gitattributes` for the generated file.
10. **A cheaper stopped entry.** The cycle runs `git merge-tree` itself, lists the conflicting paths in the stopped entry and marks generated-only ones. The owner still answers, but faster.
11. **Merge ordering.** Within an iteration, land approved review merges before self-merges that touch generated files.
12. **5 combined with 4.** Auto re-dispatch now, and approval carry-over later.

### 2. Diagnosis

- **Problem:** after a conflict or gap refusal, the owner spends an answer whose value is nearly always "re-dispatch" (every case on record). On a review brief, a second answer follows for content they already approved.
- **Hard constraints** (`docs/constraints.md`):
  - H1: no repo code runs in the gate.
  - H2: the gate fails closed, and nothing ships present-but-inert.
  - H3: hermetic tests.
  - H4: a blocking check keys on re-checkable facts.
- **Soft constraints:**
  - S1: proportionate, honest-slip model.
  - S2: no new mandatory dispatch per pass.
  - S3: reuse the existing mechanism.
  - S5: motive first; real use outranks loop metrics.
  - S8: small, with no growth of the large files.
  - S10: spend the owner's attention last.
- **From the brief:** an approval stays tied to what the owner reviewed (D8 and the TIP12 heading).

### 3. Match and prune

- **2 is pruned (H1).** The gate would run the repo's generator, which is code the change can edit.
- **3 is pruned (H2).** It lands a generated file whose content is known to be wrong: present but inert, and silently.
- **7 is pruned.** The orchestrator would write commits to a loop's branch. D13 keeps the orchestrator to its own chore commits, and an orchestrator commit at the tip voids the TIP12 tie just as a loop's would. It saves one loop run at the cost of a second commit path (S3).
- **9 is pruned.** A union of count lines is not the generator's output (H2). The gate's merge-tree also reads no repo config or attributes (`:1165-1168`, H1), so it would not apply anyway.
- **8 is pruned from the harness side.** It is a convention for the owning repo, which is out of this brief's scope, and it moves the same regeneration onto the cycle after every merge. It stays available as advice to that repo.
- **11 is pruned (S5).** It covers only the in-iteration race, and none of the cases on record came from merge order alone (Q-246 and Q-247 did, but they were hand conflicts that any order hits).
- **The survivors are 1, 4, 5, 6, 10 and 12.**

### 4. Tradeoff matrix

| # | Approach | Effort | Risk | Covers re-dispatch answer | Covers second merge answer | Gate code? | Key downside |
|---|---|---|---|---|---|---|---|
| 5 | Auto re-dispatch, any conflict or gap | ~15 skill lines | low | yes, every case | no | yes (`skills/dev-cycle/`), review merge | a loop run per refusal, up to the cap |
| 6 | Same, generated-only | setting + gate path list + skill | low | only generated cases (3 of ~10) | no | yes (`build-loop.sh`), review merge | more code, less coverage |
| 4 | Approval carry-over | ~40-60 lines in `approval()` + tests | med | no | yes, review briefs only | yes (`build-loop.sh`), review merge | weakens the TIP12 tie; grows a 2616-line file (S8) |
| 12 | 5 now, 4 later | as 5, then as 4 | low, then med | yes | yes | both | 4's cost, before its motive is shown |
| 10 | Cheaper stopped entry | ~10 skill lines | low | no (faster, not fewer) | no | yes (`skills/dev-cycle/`) | still an answer |
| 1 | No change | none | none | no | no | no | about 10 answers so far, all the same |

Falsifiable hypotheses:
- **5:** within 30 days of merging, no `stopped-` entry is filed whose reason is a conflict or gap refusal at a tip that has not yet been sent back once. Each such refusal shows as `auto@TIP12=redispatch` on the brief instead. Counter-evidence: a stopped entry with such a reason at a first refusal, or an owner answering `[2] drop` to a capped entry that auto re-dispatch produced.
- **6:** as 5, restricted to generated paths. Counter-evidence: hand conflicts keep producing stopped entries that the owner answers re-dispatch, which is what 5 would have absorbed.
- **4:** at least 2 review-brief merge entries in 30 days whose new tip differs from an approved tip only by main's content and listed generated paths. Counter-evidence: zero such entries, the expected result now that F-008 lets catalog loops self-merge.
- **1:** no conflict or gap stopped entry in 30 days. Counter-evidence: any, since the record has about 10.

Stress tests:
- **5, fast-moving main** (philosophy-research's README moves "within minutes"). The loop merges main in, and main moves again before it is collected, so it is refused again. Each new tip is sent back once, so the worst case is 4 loop runs and then the existing `capped-` entry, which is one owner answer: no worse than today's single stopped entry, plus compute. Mitigation: a re-dispatched loop's merge-in is the last step before its marker, so its window is short.
- **5, a hand conflict that means the brief is obsolete** (main already did the work). F-009's prompt sends a loop that cannot merge without discarding a side to `stopped`, and a stopped *marker* is filed for the owner as today. Residual: a loop that resolves the conflict into an empty change ends ready with no paths. On a self-merge brief that lands an empty merge, which is harmless. On a review brief the owner sees an empty merge entry.
- **5, the approval tie.** Nothing is read as the owner's answer: no entry is filed, no answer line is written, and `--cycle-diff`'s questions rule is untouched. The new tip comes back through `--check` and a new `merge-STEM-TIP12` entry, as today. D8 and the TIP12 heading are unchanged. S10 gains one answer per refusal, and S2 is unchanged: the re-dispatch replaces the one the owner's `[1]` would have caused, it only happens earlier.
- **4, what an approval means.** `approval()` would accept Q-NNN for a tip the owner never saw. Re-checkable: T1 is an ancestor of T2, and every path in `diff T1 T2` is either in the listed set or equals main's blob at T2's merge base with main. But a loop can write anything into a listed "generated" path, and the gate cannot check that it was regenerated (H1). Under S1 (honest slips) that may be acceptable for count lines. It is still a new trust rule in gate code, for a case the record no longer shows.
- **6 against 5.** Restricting to generated paths buys no safety. A hand conflict re-dispatched under 5 still meets the loop's own stop rule, the gate's full re-check and, on review, the owner's new merge entry. The restriction only adds a setting and a gate change.

### Decision presentation

```
┌─ DECISION: how the handoff treats a conflict (or gap) refusal of a ready branch ─┐
│ 6 candidates survived step-3 pruning · scored on the step-4 axes                   │
└────────────────────────────────────────────────────────────────────────────────────┘

  legend   ● strong / low   ◐ partial / medium   ○ weak / high   ✗ fails hard constraint
  drill-down: name a # to expand its card

   #    approach                  effort        risk     coverage     key downside
  ───  ───────────────────────  ────────────  ───────  ───────────  ──────────────────────────────
   5 ★ auto re-dispatch, any     ● ~15 lines   ● low    ● 4/4 hard   ◐ loop runs up to cap (mitig.)
   12  5 now, 4 later            ◐ 15+50 lines ◐ med    ● 4/4 hard   ○ 4 built before its motive
   6   auto re-dispatch, gen.    ◐ setting+gate ● low   ● 4/4 hard   ○ covers 3 of ~10 cases
   4   approval carry-over       ○ ~50 lines   ◐ med    ● 4/4 hard   ○ new trust rule, file growth
   10  cheaper stopped entry     ● ~10 lines   ● low    ● 4/4 hard   ○ still one answer each
   1   no change                 ● none        ● none   ● 4/4 hard   ○ ~10 answers so far, all [1]
```

```
╭─ [5] auto re-dispatch, any conflict or gap   ★ recommended ──────────────╮
│ effort    ~15 lines in skills/dev-cycle/SKILL.md step 7 (+ step 10 line) │
│ coverage  4/4 hard · 5/6 soft (S8 met; S3 reuses F-009 and step 10)      │
│ hypothesis  If chosen, no conflict/gap stopped entry at a first refusal  │
│             within 30 days; counter-evidence = such an entry, or a       │
│             capped entry from auto runs answered [2] drop.               │
│ stress-tests applied                                                     │
│   · fast-moving main → bounded by once-per-tip and the cap of 4          │
│   · approval tie → no answer is synthesised; new tip gets a new entry    │
│ key downside  compute: a loop run per refusal, up to the dispatch cap    │
╰──────────────────────────────────────────────────────────────────────────╯
```

```
▶ recommend [5] auto re-dispatch, any conflict or gap · confidence 85% · runner-up [12], axis = second-answer coverage vs unproven motive
```

### Decision (Path A)

**Choose 5.** It is the only candidate that removes the recurring answer in every case on record, generated or hand-written. It reuses F-009's merge-in and step 10's send-back, so it adds no new mechanism (S3), and it needs no setting, no gate-script change and no change to what an approval binds.

- **Against 6:** 6 is 5 narrowed, with more code and no added safety.
- **Against 4 and 12:** carry-over attacks the second merge answer, which the record shows only for review briefs, and F-010's review briefs existed only because of F-008, now fixed. So 4 is deferred, not chosen, under the revisit trigger below.
- **Against 1:** about 10 answers, all with the same value, are the S5 motive.

The roadmap item is named "generated files". Its root is broader: any refusal that a loop can fix by merging main in or adding a process line. The pick covers the generated case as a subset, so the owner's F-010 expectation holds: "once the owner has approved a branch's content, master moving under it only in generated files is resolved mechanically". Only the re-dispatch step happens without them; a review brief still comes back for its merge answer.

**Paths and gate status.** The paths are `skills/dev-cycle/SKILL.md`, which is gate code (GATE_CODE `^skills/dev-cycle/`, `scripts/lib/dev-cycle-read.sh:1037`), so the change needs a review merge with a `merge-gate-` entry, and its research doc. `scripts/build-loop.sh` is not touched: the `Applied:` line is prose that the orchestrator reads (no script parses `redispatch`), and `--cycle-diff` judges only `Asked:` lines (`:2387-2413`).

**How the approval stays tied to what the owner reviewed.** It is unchanged. No answer is written or inferred, and the new tip needs its own `merge[-gate]-STEM-TIP12` entry read from main's commit (D8, `approval()`).

**Revisit trigger for 4.** Brief approval carry-over (candidate 4) when, within 30 days of 5 merging, at least 2 review-brief merge entries come from an auto re-dispatch whose new tip differs from the approved one only by main's content plus files a repo calls generated.

## For the dev cycle

Suggested brief (one unit):

- **Goal:** in dev-cycle step 7, send a ready branch that the gate refuses for a conflict with the default branch, or for failure-pattern gaps, straight back to its loop with no stopped entry. This applies to a self-merge `--merge`, a review `--check` and an approved `--merge --approved`. Each tip is sent back once, within the dispatch cap.
- **What to write:**
  - Record the send-back on the brief as the `Applied:` item `auto@TIP12=redispatch` (for an approved merge, `Q-NNN=redispatch` in place of `noted`).
  - Have step 10 add one last prompt line: "Sent back for you: the gate refused TIP: REFUSAL-LINE; merge the default branch in (see the merge rule above) or add the missing failure-pattern line."
  - Keep filing a stopped entry when a branch is refused again at a tip that was already sent back, and for every other refusal.
- **Acceptance criteria to include:**
  - Step 7's three "filed as `stopped`" sentences name the exception.
  - Step 10's send-back line covers auto items.
  - The final message lists each auto send-back with its brief and refusal, so the owner can still see it (S10: nothing hidden).
  - A test pins that the skill text names the once-per-tip rule and the cap, if such a text test is the repo's practice for step 7; none exists today (`rg` finds no test on that text).
  - A short pre-mortem, since this is gate code: what the cycle could now do without the owner, bounded by the cap, the once-per-tip rule, the loop's own stop rule and the gate's full re-check at the new tip.
- **Paths:** `skills/dev-cycle/SKILL.md`, the brief's research doc and, optionally, a new test file under `test/` for the text pin.
- **Policy:** review (gate code: `skills/dev-cycle/` is in GATE_CODE).
- **Out of scope:**
  - approval carry-over (candidate 4, deferred under the revisit trigger above);
  - a `Generated paths:` setting;
  - any change to `scripts/build-loop.sh`.

The roadmap Now item "Re-dispatch a conflict that touches only generated files, with no owner entry" then becomes this brief, widened from generated-only conflicts to any conflict or gap refusal, as the decision above explains.
