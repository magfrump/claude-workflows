Commit: b88e418a

# Architecture Review — feat/build-loop-u4b2, final pass (iteration 3)

**Scope:** `git diff main...HEAD` at b88e418a (9777c1ff..b88e418a): `skills/dev-cycle/SKILL.md` (read whole, 707 lines), `test/scripts/build-loop-orchestrator.bats` (one test). Context read: `scripts/build-loop.sh` header :1-520, `steal`/`ended`/`dispatch` :1595-1660; `scripts/lib/dev-cycle-read.sh` ANSWER_AWK :2060-2100; plan D1-D14 and the U4b2 bullet (`docs/working/plan-build-loop-handoff.md:39-106, :343`); override rows 747, 749, 752, 757, 759 and the fifteen 2026-10-13 `feat/build-loop-u4b2` rows; the rubric's C1-C10.
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b2-final-r{1,2,3}.md` (at c39a9692; C1-C9 fixed in b88e418a per the rubric), the prior `architecture-review-2026-10-13-u4b2-i2.md`, and the shared brief `u4b2-i3c/shared.md`.

Scope check: in scope (data model: the brief's machine lines, the record's iteration block, questions-entry slug classes; cross-cutting: the orchestrator's control flow over the gate scripts). Deferred i2 findings 2, 4, 5, 6, 7, 11 are not re-reported; none of their deferrals is wrong on this reading.

Trust-boundary cross-reference: active. Map from `docs/reviews/security-review-2026-10-13-u4b2-i2.md` (Commit: `adc8a176`) — security review predates this diff; boundary may be stale. Its `B7` ([WT test tree incl. ungated main commits] → [step 1 skip on `other`] → [tests/commands steps 2 and 4 run]) is cited in finding 1.

## Dependency Map

Unchanged from i2: SKILL.md (executed by the model) → the D6 block → `build-loop.sh` / `dev-cycle.sh` → the lib; git only through `hg`. Direction is correct (the skill depends on script headers; scripts know the skill only through comments). The state stores, with what this pass changed:

| Fact | Store | Judged by | Change at b88e418a |
|---|---|---|---|
| Brief status/branch/policy/paths | brief on main | `--status`, `--check`, `--check-brief` | — |
| Asked-at-TIP (blocked/stopped/capped) | `Asked:` + entry | `--cycle-diff` | — |
| Merge-entry binding | heading in WT's questions files | `--approved` at merge time | deferred (i2 #6) |
| Answer acted on, and *what it asked for* | `Applied:` (IDs only) | nobody | new dependency: the re-dispatch rule (finding 2) |
| "Health check passed at …" | nowhere durable (record `1.` says done/skipped) | nobody | new dependency: the C4 skip rule (finding 1) |
| Dispatch count | `Dispatched:` via the second land | `--status`/`--start` | deferred (i2 #2) |
| Loop ownership, kept N, `--answered` | session memory | nobody | deferred (i2 #4) |
| Point of judgment for the chore commit | after the commit (was: before) | `--cycle-diff`, then `--land-cycle` | moved (finding 3) |

## Findings

#### 1. The health-check skip rule depends on a fact no store holds, over a window that covers one iteration

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:291-294` (step 1), `:579-580`, `:593` (record template); step 0.2 `:235-257`
**Move:** 2 (responsibility), 7 (coupling)
**Confidence:** Medium (static, traced across iterations)
**Legibility-target:** orchestrator

Evidence: step 1: "skipped when step 0.2 read an `other` line, whose unreviewed test code it would run (row 776; step 4 then runs no repo test either), or when an earlier iteration's health check passed and step 0.2 listed only `chore` lines since (cycle lands carry no code)". The record may be read only "for their `1.` and `7.` lines and the last `Main at:`", and its `1.` line is "1. health and cleanup: <done / skipped: reason>". Step 0.2 lists commits only after SINCE, "the newest `Main at:` line of the newest record", i.e. the previous iteration's start.

The C4 fix makes the skip depend on two facts the state model does not carry: *which MAIN a check passed on* (the template records "done", not pass/fail, nor the commit) and *what moved main between that check and now* (step 0.2's window spans only the last iteration, not back to "an earlier iteration"). Concretely: iteration k passes; k+1 reads an `other` line (a user's direct code commit) and skips by row 776; k+2's window starts at k+1's MAIN, which already contains the `other` commit, lists only `chore`, and "an earlier iteration's health check passed" (k) holds, so it skips again; so does every later iteration until a `gate` or `answers` line appears. The `other` commit's code is never health-checked by the cycle, and the record shows nothing missing. The rule is only sound if "earlier" means "the immediately previous iteration, whose check ran and passed", which the text does not say and the record cannot show.

**Recommendation:** Narrow the rule to "the previous iteration's health check ran and passed" and make the template's `1.` line say so (`1. health and cleanup: passed at MAIN` / `failed` / `skipped: reason`), so the skip reads a durable fact instead of memory. An iteration that skipped for any reason then never licenses the next skip.
**Security implication:** tightening this moves where `B7`'s ungated code runs: the `other` commit's tests would run in the iteration after the one that read the `other` line (as they already do whenever a later window holds a `gate` line). `B7` from `docs/reviews/security-review-2026-10-13-u4b2-i2.md` (Commit: `adc8a176`) — security review predates this diff; boundary may be stale. Whether the next iteration may run that code before the user answers the `other` entry is a combined architecture/security call; the alternative is "skip until the `other` entry is answered", which also needs that fact recorded.

#### 2. "The last one applied asked for a re-dispatch" cannot be derived from the stores the skill allows it to read

**Severity:** Coupling
**Location:** `skills/dev-cycle/SKILL.md:466-470`, `:519-521`, `:540-541`
**Move:** 7 (coupling), 2
**Confidence:** Medium-High (static; the read path is explicit in the text)
**Legibility-target:** orchestrator

Evidence: "once every such ID is on its `Applied:` line, the last one applied asked for a re-dispatch, the brief is still open and no subagent of this session runs it, step 10 re-dispatches it"; "Then answers, only through `--check-answer` … one call with the IDs … of every brief's `Asked:` items and merge entries, less those on its `Applied:` line"; "Add each ID acted on to the brief's `Applied:` line … so each answer is acted on once."

The C7 fix keys re-dispatch on a fact (the applied answer's *meaning*: blocked-answered, stopped `keep`, merge `done`) that is stored nowhere: `Applied:` holds bare IDs, the only sanctioned answer reader excludes exactly those IDs, and the entry class is a heading slug. Within one session the model remembers; after a restart or compaction, the orchestrator must either break the "answers only through `--check-answer`" rule or leave the brief unreached. The failure is fail-closed but silent: a brief whose re-dispatched loop ended with no new commit (LOOP still blocked/stopped at the same TIP, every ID applied) is never re-dispatched and never re-asked; the final message lists it only as an open brief. This is the same pattern as deferred i2 #4 (memory-only state), but it is new in this commit and the fix is local to skill text.

**Recommendation:** Record the action with the ID (e.g. `Applied: Q-NNN redispatch` or `Q-NNN=keep`; `--cycle-diff` does not judge `Applied:`, so no gate change), or pass the last `Applied:` ID of each brief to the same `--check-answer` call and re-derive.

#### 3. Step 9 now commits before `--cycle-diff`, reversing D13, the plan bullet, row 747 and the script header, with no record of the change

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:627-650`; `scripts/build-loop.sh:182-185`; `docs/working/plan-build-loop-handoff.md:103`, `:343`; `docs/reviews/override-log.md:747`
**Move:** 4 (layering of judgment), 7
**Confidence:** High (divergence); Medium (consequences)
**Legibility-target:** maintainer

Evidence: skill: "`--state` … Read T, `hg -C WT write-tree`, then commit the index as staged … Committing first leaves WT clean, so main can be merged in." then "3. Read M … then `--cycle-diff` (it reads the index, now HEAD's tree)". Header: "`--cycle-diff`  what the orchestrator's chore commit would land … run in its worktree before that commit, which takes the index as is". Plan D13: "**Before the chore commit**, `build-loop.sh --cycle-diff --answered Q-…` compares the staged files". Plan U4b2 bullet: "`--cycle-diff` then a plain commit of that index with hooks off: rows 747, 749". Row 747: "no edits between the check and the commit".

The reorder (C1) is sound in what it judges (the index equals HEAD's tree, and `--land-cycle` judges the merge copy anyway), but the gate's only caller now contradicts the gate's own header, the plan's approved design, and the row this step discharges; b88e418a's message is the only record. Two consequences a later reader cannot infer from the docs: the pre-commit judgment is now a pre-land one, so a refused change stays in the branch's history and reaches main as an ancestor of the chore merge (the remedy is "a new commit", not an amend); and the header's "before that commit" invites a future editor of `--cycle-diff` to rely on HEAD not yet holding the change.

**Recommendation:** Add an override/decision-log row naming the order change and its reason (C1: `git merge` refuses over staged edits), and queue the header and D13 wording for the next gate-code edit or U5's docs pass.

#### 4. The Rules' stop clause still describes one land per iteration (i2 #9, neither fixed nor deferred)

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:59-60`; `:687-688`; `:612-615`
**Move:** 2
**Confidence:** High
**Legibility-target:** orchestrator

Evidence: Rules: "Each stop ends the iteration there, with no record (its `Main at:` would move the next SINCE)". Step 10: "A stop here ends the iteration as the Rules say, its record already landed". Step 9: "`Main at:` line as the next SINCE (MAIN, the commit this iteration started from, so whatever moved main after it is read next time)".

Step 10 now says outright that a second-land stop leaves a landed record, which the Rules it defers to say cannot exist; and the Rules' rationale is false under the current `Main at:` (the iteration's start commit, so a landed record would not skip anything step 7 merged). The rubric's iteration-2 table lists i2 #9 in neither the fixed B-rows nor the deferred list.

**Recommendation:** Reword to "a stop ends the iteration with no further land" and state the rationale per land (land 1: the iteration's half-done state is not on main; land 2: the record is, without its `10.` line).

#### 5. The wait rule's "since this iteration's land" is ambiguous with two lands, and one reading never idles

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:703-707`; `:687-692`
**Move:** 7
**Confidence:** Medium
**Legibility-target:** orchestrator

Evidence: "with none, every 1200-1800 s, and only when the default branch moved since this iteration's land, a retry's wait ran out, or the user wrote, run a full iteration … otherwise the wakeup does nothing." Step 10: "Then land again as step 9 does (1 to 4)".

Every iteration now lands twice. Read against the first land's NEW, the second land is always a move, so every wakeup runs a full iteration, which lands twice again: D12's "cheap check … otherwise it is a no-op wakeup" never happens. Read against the second land, a second-land stop leaves no reference point. The orchestrator executing this has to pick.

**Recommendation:** Name the value: "main is not the NEW the iteration's last `landed` line printed (after a stop: the first land's NEW, else MAIN)".

#### 6. Step 8's queue counts by LOOP, so briefs that wait on the user still fill it

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:545-549`; `:473-476`; `:682-685`; plan D9 (`:90`)
**Move:** 2
**Confidence:** Medium
**Legibility-target:** orchestrator

Evidence: "open briefs whose loop step 7 read as absent or working, plus those it sends back to a loop, each counted once (a blocked, stopped or ready one waits on the user and is not counted)". Step 7: a stalled loop is stopped by task ID and filed as `stopped`, but its branch tip is unchanged, so `--status` still reads it `working` ("the session keeps it out of step 10 until that entry is answered"). Step 10: a capped brief answered **[1] keep** "stays open, for work by hand". D9: "Only a live dispatched loop holds a slot … A `blocked`, `ready`-awaiting-review or `stopped` item holds none".

The parenthetical's intent (count what does not wait on the user) is keyed on LOOP, which is a branch-tip reading, not the brief's actual state. A stall-stopped brief waits on the user but reads `working`; a capped brief kept for work by hand reads `working` (or `absent`) indefinitely. Each holds a queue place that no loop uses, so step 8 writes fewer briefs than D9 allows, with nothing in the record saying why.

**Recommendation:** Exclude briefs with an unapplied `Asked:` item (the stall entry) and briefs at the cap from the count, or key the count on "a loop of this session runs it, or step 10 will dispatch it".

#### 7. The answer grammar and the `--cycle-diff` refusal list are full prose copies of script rules, unpinned, and the first still drifts

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:522-524`, `:635-650`; `scripts/lib/dev-cycle-read.sh:2070-2083`; `scripts/build-loop.sh:186-236`
**Move:** 7
**Confidence:** High (executed: option() run on sample answers, probe `u4b2-i3c/arch/probe-option.sh`)
**Legibility-target:** maintainer

Evidence: skill: "An answer starting `[1]`, `1` or `keep` (any case) reads `keep`; `[2]`, `2` or `drop`, `drop`; `[3]`, `3` or `done`, `done`; anything else, `unrecognized`". The lib: `if (!match(s, /^(1|2|3|keep|drop|done)/)) return "unrecognized"`, then the word must be followed by the end, punctuation, or blank(s) then a dash. Executed: `1 because the fix is fine` → unrecognized; `10` → unrecognized; `keep going` → unrecognized; `keep, but later` → keep; `1 - yes` → keep.

The C6 fix restated the grammar a third time and it is still not the grammar ("starting" is wider than the word-boundary rule). The effect fails closed (an unrecognized answer is recorded and re-asked), but it is the pattern i2 #8 named: a rule that must exist in both prose and code, without the pin the GATE_CODE test provides. Step 9.3's refusal list is now a near-complete copy of the header's (A7, B14 completed it by hand), and is one header edit from stale.

**Recommendation:** Replace the grammar sentence with a pointer plus the one fact the step needs ("`--check-answer` prints keep, drop, done or unrecognized; a bare word after the option must be followed by punctuation or a dash"), and cut 9.3 to the remedies keyed by PATH (`HEAD`, `index`, a questions file, other), pointing at the header for the rule list.

#### 8. `### Paths landed` is written before the commit and is not refreshed when step 9.3 loops back

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:622-626`, `:647-650`, `:657-659`
**Move:** 7
**Confidence:** Medium
**Legibility-target:** user

Evidence: "Before the record's last write, list under `### Paths landed` what the land carries: `hg -C WT diff --cached --no-renames --name-status BASE`"; "The remedy is to fix the iteration's own change, stage the fix as in 1 and go back to 2 (a new commit); `refuse HEAD` or the questions-moved refusal means merge main in (below) and go back to 3".

With the commit-first order, the listing is taken before step 2; a fix commit (which may add a path) or a merge of main (which moves BASE) changes what lands without the record being rewritten, since going back to 2 or 3 does not re-enter 1. The record is the user's view of rows 722/772's "carried commits' paths".

**Recommendation:** Make "go back to 2" include re-listing (and re-staging the record), or list after the last `--cycle-diff` ok and fold the record into a final commit before `--land-cycle`.

#### 9. A stopped iteration's committed branch is never retried or listed (the remaining D13 drift)

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:64-66` (Rules), `:308-315` (step 1); plan D13 (`:104`)
**Move:** 2
**Confidence:** Medium
**Legibility-target:** user

Evidence: Rules: "A stop after step 0.3 removes WT as step 0.3 does (with `--force` …; its branch stays)". Step 1: "List merged branches; deleting them needs the user's approval". D13: "A failed land is retried before the next iteration's step 7, so `Asked:` state is never re-derived from a main that lacks it (F49)."

B11 replaced D13's retry for the stall case with session memory; the general retry is still absent and no override row records dropping it. With the commit-first order, a stop at 9.3 or 9.4 now leaves a fully committed iteration (record, entries, `Asked:` items) on a `chore/dev-cycle-*` branch that no step reads and step 1 never lists (it lists merged branches only), so these accumulate unseen.

**Recommendation:** Have step 1 also list unmerged `chore/dev-cycle-*` branches other than WT's in the same `you: terminal` entry, and record D13's retry as deferred (row) if it is not to be built.

## What Looks Good

- The commit-first order (C1) fixes a real dead end (merge over staged edits) without weakening the gate: `--cycle-diff` judges the same index, and `--land-cycle` still judges the merge copy against main. route: code-fact-check — `skills/dev-cycle/SKILL.md:627-632` (index equals HEAD's tree when `--cycle-diff` runs).
- The new bats test extends the GATE_CODE pin to `DISPATCH_CAP` and `STEAL_AGE`, computing the expected prose from the script's constants. route: code-fact-check — `test/scripts/build-loop-orchestrator.bats:374-384`.
- Stopped reasons now go on a `> Reason:` line with the `<!--` case withheld in wording that holds no `<!--`, keeping loop text out of the questions readers' column-0 grammar (D11's invariant). route: code-fact-check — `skills/dev-cycle/SKILL.md:510-514`.
- Self-merge refusals now split by owner: path refusals become the user's merge entry, environment refusals retry, conflicts stop the brief. The loop is not blamed for the orchestrator's environment.
- The second land satisfies `--land-cycle`'s record rule by construction (step 10 writes the `10.` line into a record holding `Branch:`). route: code-fact-check — `skills/dev-cycle/SKILL.md:687`, `scripts/build-loop.sh:250-251`.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Health-check skip needs "passed at which MAIN" and a multi-iteration window; neither is stored, so an `other` commit's code is never checked | Coupling | `SKILL.md:291-294, 593` | Medium |
| 2 | Re-dispatch keyed on the applied answer's meaning, which `Applied:` does not store and `--check-answer` is not asked for | Coupling | `SKILL.md:466-470, 519-521` | Medium-High |
| 3 | Commit before `--cycle-diff` reverses D13, the plan bullet, row 747 and the header; unrecorded | Minor | `SKILL.md:627-650`; `build-loop.sh:182-185` | High |
| 4 | Rules' stop clause ("with no record", SINCE rationale) contradicts step 10's landed-record stop; i2 #9 unaddressed | Minor | `SKILL.md:59-60, 687-688` | High |
| 5 | Wait rule's "this iteration's land" ambiguous with two lands; one reading never idles | Minor | `SKILL.md:703-707` | Medium |
| 6 | Step 8 queue counts stall-stopped and capped-kept briefs (LOOP `working`) that wait on the user | Minor | `SKILL.md:545-549` | Medium |
| 7 | Answer grammar and 9.3 refusal list copied in prose, unpinned; grammar still drifts (executed) | Minor | `SKILL.md:522-524, 635-650` | High |
| 8 | `### Paths landed` not refreshed after step 9.3's loop-back | Informational | `SKILL.md:622-626` | Medium |
| 9 | Stopped iterations' committed branches never retried or listed; D13 retry unrecorded | Informational | `SKILL.md:64-66, 308-315` | Medium |

## Overall Assessment

The branch preserves the main structural invariant (the skill decides, the scripts judge, nothing reaches main except through `--cycle-diff`/`--land-cycle`/`--merge`), and the iteration-3 fixes are structurally sound in what they gate. The pattern the final pass adds is the one i2 flagged: fixes C4 and C7 each key a decision on a fact the state model does not hold (a passing check's MAIN; an applied answer's meaning), so their correctness rests on session memory or on a window that is too short. Both are fixable in skill text by writing the fact where the next iteration reads it (the record's `1.` line, the `Applied:` item). The single most important concern is finding 1, because it silently removes the health check from code that arrived outside the design. Its fix interacts with `B7`'s skip and should be settled with the security reviewer. Findings 3, 4 and 9 are recording gaps between the skill and the plan it implements; none changes behaviour today.

## Goal-Alignment Note

Success criterion: "An architecture review saved at the given path, structured per the architecture-review skill." Met: saved at `docs/reviews/architecture-review-2026-10-13-u4b2-final.md` in the worktree, with the skill's header, Dependency Map, Findings (Severity, Location, Move, Confidence, plus the brief's verbatim Evidence and Legibility-target), What Looks Good, Summary Table and Overall Assessment; the trust-boundary cross-reference applied (finding 1, `B7`). Focus coverage: state model (Dependency Map table; findings 1, 2, 6, 9), script rules in prose (7), the two lands (4, 5), the per-call gate worktree (reviewed: GT's remaining issues are covered by the deferred i2 #5 row, nothing new), the commit-before-`--cycle-diff` order (3, 8), coherence with D1-D14 and U4b1's Rules (3 vs D13, 4 vs the Rules, 5 vs D12, 6 vs D9, 9 vs D13). Limits: one probe executed (finding 7's grammar); the rest are static readings traced across steps. Endorsements are routed to code-fact-check, not asserted.
