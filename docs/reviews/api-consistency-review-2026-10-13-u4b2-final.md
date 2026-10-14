# API Consistency Review — feat/build-loop-u4b2, iteration 3 final pass (b88e418a)

**Scope:** `git diff main...HEAD` (full branch, HEAD b88e418a): `skills/dev-cycle/SKILL.md`, `test/scripts/build-loop-orchestrator.bats`
**Date:** 2026-10-13
**Based on:** `docs/reviews/code-fact-check-report-2026-10-13-u4b2-final-r{1,2,3}.md` (merged as C1-C10 in the rubric, fixed in b88e418a), the prior `api-consistency-review-2026-10-13-u4b2-i2.md`, and the shared brief `u4b2-i3c/shared.md`

The "API" reviewed here is the contract between the dev-cycle skill's steps and the script modes they call: argument forms, printed lines, and the refusal texts the skill matches. It also covers the questions-entry grammar, the record template that other steps read, and naming within SKILL.md and against plan D1-D14. Deferred override rows 786-800 are context. This report lists a deferred item only where the deferral or the "Fixed" status is wrong (finding 2).

## Baseline Conventions

- **Script output is typed by its first word.** The words are `ok`, `skip`, `refuse`, `path`, `deny`, `merged`, `landed` and `dispatched`, each documented in its mode's header (`scripts/build-loop.sh:6-519`). Callers act on the first word and on fixed refusal substrings (`:494-497`).
- **One answer vocabulary.** `option()` in ANSWER_AWK (`scripts/lib/dev-cycle-read.sh:2070-2081`, documented at `:2052-2056`) reads a leading `[1]`/`[2]`/`[3]`, or the bare token `1|2|3|keep|drop|done`. The bare token counts only when the end, punctuation or a dash follows it. Anything else reads as `unrecognized`.
- **Entry slugs.** Items on an `Asked:` line name entries headed `WORDS-STEM-N` (`build-loop.sh:224-237`). Approvals use `merge-STEM-SHA12` or `merge-gate-STEM-SHA12` (`approval()`, `:1442-1457`).
- **Error routing by cause.** After C5, step 7 splits `--merge` refusals into three routes. A path refusal goes to review. A conflict goes to `stopped`. An environment refusal is retried (`SKILL.md:483-489`). This split is the baseline that the other `--merge` call sites should follow.
- **Record lines that scripts read.** `Branch: B` (read by `--main-log` chore and `--land-cycle`) and `Main at:` (read by step 0.2). Other record lines are read only by later steps of the skill: `1.` and `7.` lines, `Model:`, and the trigger verdicts.

## Name-Pattern Audit

| New name | Category | Closest existing | Precedent path | Verdict |
|---|---|---|---|---|
| `blocked-STEM-N`, `stopped-STEM-N`, `capped-STEM-N` | entry slug | `keep-or-drop-STEM-N` | `scripts/build-loop.sh:230-234` | Consistent (WORDS-STEM-N) |
| `merge-STEM-SHA12`, `merge-gate-STEM-SHA12` | entry heading | `approval()` | `scripts/build-loop.sh:1442-1457` | Consistent; GATE_CODE copy pinned by the new test |
| `> Reason: REASON` | entry body line | `--marker`'s `> ` prefix | `scripts/build-loop.sh:107-112` | Consistent (quoted like the marker body) |
| `Asked:` / `Applied:` / `Dispatched: N` | brief lines | `--status`, `--cycle-diff` readers | `scripts/build-loop.sh:87, 224-237, 902` | Consistent |
| `## Iteration DATE-HHMM` + `### Steps`, `### Skipped inputs`, ... | record headings | old `## Steps`, `## Skipped inputs` | `git show main:skills/dev-cycle/SKILL.md:513-525` | Demoted to `###`, but two references still say `## Skipped inputs` (finding 8) |
| `1.` ... `10.` record lines | record step lines | step headings, Flow | `skills/dev-cycle/SKILL.md:213-216, 592-601` | Consistent names. The `1.` line has no pass/fail field (finding 4), and the `9.` line has no writer (finding 6) |
| `.claude/wt-dev-cycle-gate-DATE-HHMM` (GT) | worktree path | `.claude/wt-dev-cycle-DATE-HHMM` | `skills/dev-cycle/SKILL.md:258-259` | Consistent |
| `DISPATCHED 4 (the cap)` | threshold | `DISPATCH_CAP=4`, `-ge` | `scripts/build-loop.sh:1637` | Equality where the script uses `>=` (finding 10) |

## Findings

#### 1. An approved merge's refusal is always filed `stopped`, including the environment refusals that the self-merge path now retries (C5 applied to one `--merge` call site only)

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:535-536` vs `:483-489`; `scripts/build-loop.sh:432-449`
**Move:** 4 (error consistency), 7 (asymmetry)
**Confidence:** High
**Legibility-target:** the author of step 7; a reader who compares the two `--merge` bullets

Evidence (self-merge, after C5): "Any other refusal (no identity, MAIN_WT's state, a moved main, a failed read) is the environment's, not the loop's: recorded, named in the final message, and tried again next iteration."
Evidence (approved merge): "A merge entry: `keep` runs `--merge BRIEF --expect TIP --approved Q-NNN`, TIP the full one the entry names, never the branch's live tip; a refusal is filed as `stopped`."
Evidence (header): `--merge` refuses when "no identity is known; the worktrees, the git directory ... cannot be read; ... With the branch checked out in W, also when W ... has a tracked change".

`--approved` runs the same move as self-merge, so it can hit the same environment refusals. The most likely one is MAIN_WT, the user's shared checkout, holding tracked edits (rubric "architecture 10" says this stops each land). On the approved path, that refusal turns the user's `[1]` into a `stopped` entry, and step 7 puts the merge ID on `Applied:`, so the approval is spent. The stopped entry's options are "[1] re-dispatch" and "[2] drop". Neither lands the work the user has already approved. A re-dispatch also uses one of the brief's 4 dispatches. The same refusal under self-merge would just be retried.

**Recommendation:** Route `--approved` refusals the way C5 routes self-merge ones. File `stopped` only for a refusal tied to the loop's work: an N-rule `deny`, a conflict, or a tip mismatch. For an environment refusal, record it, name it in the final message, and leave the ID off `Applied:` so that the next iteration retries the approved merge.

#### 2. D13's "a failed land is retried before the next iteration's step 7" is still absent; rubric B11 marks i2 api-consistency 6 Fixed, but the fix covers only stalled loops

**Severity:** Inconsistent
**Location:** `skills/dev-cycle/SKILL.md:59-66, 466-467, 620-659`; plan `docs/working/plan-build-loop-handoff.md:105`; rubric `code-review-rubric-2026-10-13-feat-build-loop-u4b2.md:65`
**Move:** 3 (consumer contract vs spec), 9 (idempotency)
**Confidence:** High
**Legibility-target:** the reviewer who closed B11; the plan's owner

Evidence (plan D13): "A failed land is retried before the next iteration's step 7, so `Asked:` state is never re-derived from a main that lacks it (F49)."
Evidence (rubric B11): "A failed land's entries are re-derived next iteration; a stalled loop could then be re-dispatched unasked | architecture 3, api-consistency 6 | Fixed: the session keeps a stalled brief out of step 10 until its entry is answered".
Evidence (SKILL.md): "Each stop ends the iteration there, with no record ... A stop after step 0.3 removes WT ... its branch stays" · step 7's dedupe: "an item on its `Asked:` line ends `@TIP`, or WT's questions files hold its merge entry's heading".

`grep -n 'retr\|failed land' skills/dev-cycle/SKILL.md` finds no retry of a stranded `chore/dev-cycle-*` branch. When a first land stops at 9.3 or 9.4, the next iteration's WT is built from a main that lacks those entries, so every blocked, stopped and merge entry is filed again under new IDs. The B11 fix also creates a new hazard. The session waits for the stalled brief's stopped entry to be answered, but that entry is on the stranded branch and can never be answered. Override rows 786-800 do not defer this, so it is neither fixed nor deferred.

**Recommendation:** Do one of two things. Add the retry: at step 0, if a `chore/dev-cycle-*` branch with a record is not an ancestor of main, land it before step 7. Or add an override row that defers D13's retry and states the duplicate-entry consequence, and correct B11's status to "fixed in part".

#### 3. The answer grammar sentence still overstates what reads as an option: `1 merge`, `keep it` and `3 changes needed` read `unrecognized`

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:522-524`; `scripts/lib/dev-cycle-read.sh:2054-2056, 2075-2077`
**Move:** 3 (documentation drift vs the reader)
**Confidence:** High
**Legibility-target:** the orchestrator, which explains unrecognized answers to the user in the final message

Evidence (SKILL.md, the C6 fix): "An answer starting `[1]`, `1` or `keep` (any case) reads `keep`; `[2]`, `2` or `drop`, `drop`; `[3]`, `3` or `done`, `done`; anything else, `unrecognized`".
Evidence (lib): "(a word must be followed by the end, punctuation or a dash)".

An executed probe (`scratchpad/u4b2-i3c/api/probe-option.sh`, which runs the lib's own `option()`) gave these results. Read as `unrecognized`: `1 merge`, `keep it`, `keeper`, `12`, `3 changes needed`. Read as options: `[1] merge` → keep, `1 - merge` → keep, `[3] changes needed: fix X` → done. A user who answers a merge entry with "3 changes needed: ..." gets `unrecognized`, and their note never goes back to the loop. The skill's sentence says this answer is accepted.

**Recommendation:** Add the lib's qualifier: "`1`, `2`, `3` or the word only when followed by the end, punctuation or a dash; `[N]` takes any text after it."

#### 4. Step 1 skips the health check on "an earlier iteration's health check passed", but the record's `1.` line has no pass/fail field to read

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:291-294, 580, 593`
**Move:** 7 (asymmetry: reader vs writer)
**Confidence:** High
**Legibility-target:** the next iteration's step 1

Evidence: "skipped ... when an earlier iteration's health check passed and step 0.2 listed only `chore` lines since" · "nor reading them, but for their `1.` and `7.` lines" · template: "1. health and cleanup: <done / skipped: reason>".

The `1.` line is the only place the skill allows step 1 to look, and its template records only done or skipped. A health check that ran and failed is still "done". A reader therefore cannot tell from the template whether the check passed, so the C4 skip relies on free text that nothing requires anyone to write.

**Recommendation:** Change the template to `1. health and cleanup: <passed / failed: N / skipped: reason>`, or name the exact word the skip reads.

#### 5. The per-day record's read restriction contradicts step 4b's `Model:` read and step 2's previous verdicts

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:579-581` vs `:381, 334-335, 345`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** the orchestrator, which runs steps 2 and 4b against today's record

Evidence: "each iteration appending its own block below the earlier ones and never editing them (nor reading them, but for their `1.` and `7.` lines and the last `Main at:`" · step 4b: "the model running this cycle differs from the last record's `Model:` line" · step 2: "The previous record's verdicts are context".

With one file per day, "the last record" is today's file, and its earlier blocks are off limits except for the three line kinds listed. Step 4b's `Model:` comparison and step 2's previous verdicts both need lines from those blocks. Taken literally, step 4b can never fire its model trigger within a day, and step 2 has no previous verdicts to consult.

**Recommendation:** Add the last block's `Model:` line and its `### Trigger verdicts` to the allowed reads, or reword steps 2 and 4b to read "the previous iteration's block".

#### 6. The record's `9. land: <landed NEW / stop: reason>` line has no writer

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:600, 687-688, 59-60`
**Move:** 7 (asymmetry)
**Confidence:** Medium
**Legibility-target:** the step 9/10 author

Evidence: template "9. land: <landed NEW / stop: reason>" · Rules: "Each stop ends the iteration there, with no record" · step 10: "Then land again as step 9 does (1 to 4): the briefs' `Dispatched:` lines and the record's `10.` line."

NEW exists only after `--land-cycle` prints it, which is after the first land's record is already committed. A step 9 stop lands no record at all, so "stop: reason" can never appear in a landed record. The only land that could write "landed NEW" is step 10's second land, and that sentence names only the `10.` line.

**Recommendation:** Say that the second land also writes the `9.` line with the first land's NEW. Drop "stop: reason", or move it to the final message.

#### 7. Step 9.4 routes only two of `--land-cycle`'s refusals

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:651-655`; `scripts/build-loop.sh:262-270`
**Move:** 4 (error consistency)
**Confidence:** Medium
**Legibility-target:** the orchestrator at 9.4

Evidence (SKILL.md): "`refuse HEAD` naming a moved default branch: merge main in, then 3 again. While MAIN_WT has main checked out, the land fast-forwards it, and refuses while it has tracked edits or is mid-merge: a stop".
Evidence (header): "or refuse lines and exit 2: --cycle-diff's rules' (PATH a file; a copy of the merge is "its merge copy"), or refuse HEAD: WHY ... staged changes; nothing the default branch lacks; a conflict; an object that does not hash ...; no such record".

The merge-copy refusals (`--land-cycle` re-judges the merge, "a fence pair that captures main's answer, shows here"), a conflict, and "no such record" all get no route. 9.3 spells out a remedy for each `--cycle-diff` refusal, and 9.4 is less specific than that baseline. Under the Rules, these refusals count as documented answers and not as stops, so they fall through the text.

**Recommendation:** Add "any other refusal: a stop" to 9.4, or point each merge-copy refusal to 9.3's remedies.

#### 8. Record headings were demoted to `###`, but two references still say `## Skipped inputs`

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:187, 269` vs `:602`
**Move:** 2 (naming)
**Confidence:** High
**Legibility-target:** whoever writes the record

Precedent: `### Skipped inputs` under `## Iteration DATE-HHMM` used in `skills/dev-cycle/SKILL.md:586-609` (this branch's template)

Evidence: "goes in the record under `## Skipped inputs`" (Rules) · "8 skipped inputs (the record's `## Skipped inputs`)" (step 0.4) · template "### Skipped inputs". In a per-day file, a `## Skipped inputs` heading would close the iteration's `## Iteration` block, so following the Rules text puts skips outside their iteration.

**Recommendation:** Change both references to `### Skipped inputs`.

#### 9. `--cycle-diff`'s header and the plan bullet still say it runs before the chore commit; step 9 now commits first (C1)

**Severity:** Minor
**Location:** `scripts/build-loop.sh:178-181`; plan `docs/working/plan-build-loop-handoff.md:343`; `skills/dev-cycle/SKILL.md:627-632`
**Move:** 3 (documentation drift)
**Confidence:** Medium
**Legibility-target:** a future editor of `--cycle-diff` who trusts its header

Evidence (header): "what the orchestrator's chore commit would land (... run in its worktree before that commit, which takes the index as is)" · plan: "`--cycle-diff` then a plain commit of that index with hooks off: rows 747, 749" · SKILL.md 9.2-9.3: "commit the index as staged ... Committing first leaves WT clean ... then `--cycle-diff` (it reads the index, now HEAD's tree)".

The new order still works, because the index is HEAD's tree and BASE is unchanged. The header is now the gate's own description of a caller that no longer exists, and the skill tells readers to trust headers. Like i2's finding 5 (row 792), this is gate-code comment text.

**Recommendation:** Add an override row (or extend row 792) that queues the header wording for U5, and note the order change against the plan bullet.

#### 10. The dispatch cap is matched as `DISPATCHED 4`; the script refuses at 4 or more

**Severity:** Minor
**Location:** `skills/dev-cycle/SKILL.md:682-685`; `scripts/build-loop.sh:87, 902, 1637`
**Move:** 8 (value range)
**Confidence:** Medium
**Legibility-target:** the orchestrator at step 10

Precedent: `-ge "$DISPATCH_CAP"` used in `scripts/build-loop.sh:1637`

Evidence: "A brief `--status` read with DISPATCHED 4 (the cap, D1) is never dispatched again" · `--status` prints DISPATCHED as "the brief's "Dispatched: N" (0-99)" · `elif [[ "${STATUS[dispatched]}" -ge "$DISPATCH_CAP" ]]`.

A brief whose count reads 5 or more (hand-edited, for example) misses the capped bullet. `--start`/`--prompt` then refuses "dispatched 5 times, and the cap is 4", which falls into "any other refusal: one `agent` entry". The result is a mechanical entry where the cap path files a `you: judgment` keep/drop entry.

**Recommendation:** "DISPATCHED 4 (the cap, D1) or more". The new test greps for `with DISPATCHED $cap (the cap`, so keep that substring.

#### 11. "newest" vs "last" `Main at:` remains (i2 finding 12's first half; B15 marks it fixed)

**Severity:** Informational
**Location:** `skills/dev-cycle/SKILL.md:235` vs `:613-614`
**Move:** 2 (naming)
**Confidence:** Low
**Legibility-target:** step 0.2's reader

Precedent: "the last record's `Main at:` SHA" used in `docs/working/plan-build-loop-handoff.md:101` (D13)

Evidence: "SINCE is the newest `Main at:` line of the newest record" · "step 0.2 takes the file's last `Main at:` line as the next SINCE". The two are equivalent while blocks are only appended.

**Recommendation:** Use "last" in step 0.2.

## What Looks Good

- The new slugs, `Q-NNN@TIP` items and the bare `Q-NNN` for a capped brief with TIP `-` all fit `--cycle-diff`'s Asked: grammar (Q-NNN or Q-NNN@SHA 7-64 hex, WORDS-STEM-N heading gained in the same land).
- The merge heading rule quotes GATE_CODE byte for byte, and a test pins it. Approved merges pass the full TIP to `--expect`, as `approval()`'s header asks.
- `> Reason: REASON` closes C3: the line starts with `>` and then a word, so it cannot start like a link reference definition, and the `<!--` replacement text (C2) no longer contains `<!--`.
- Option labels on stopped and merge entries now have explicit rules for `done` and word answers (i2 finding 2). Blocked entries treat any answered state as answered (i2 finding 1).
- The step 10 refusal substrings ("retry once it ends", "under 2 hours old") match `build-loop.sh:2145, 1612`, and the test pins the cap and steal age.

## Summary Table

| # | Finding | Severity | Location | Confidence |
|---|---------|----------|----------|------------|
| 1 | Approved-merge refusals all filed `stopped`; environment refusals spend the user's approval (C5 asymmetry) | Inconsistent | `SKILL.md:535-536` | High |
| 2 | D13 failed-land retry absent; B11 "Fixed" covers only stalled loops; entries re-filed | Inconsistent | `SKILL.md:59-66, 620-659`; plan `:105` | High |
| 3 | Answer grammar omits "followed by end, punctuation or dash" (`3 changes needed` → unrecognized) | Minor | `SKILL.md:522-524` | High |
| 4 | Health-check skip reads "passed" from a `1.` line that records only done/skipped | Minor | `SKILL.md:291-294, 593` | High |
| 5 | Per-day read restriction blocks 4b's `Model:` and 2's previous verdicts | Minor | `SKILL.md:579-581` | Medium |
| 6 | `9.` line has no writer; "stop: reason" unreachable | Minor | `SKILL.md:600, 687` | Medium |
| 7 | 9.4 routes only two `--land-cycle` refusals | Minor | `SKILL.md:651-655` | Medium |
| 8 | `## Skipped inputs` vs template `### Skipped inputs` | Minor | `SKILL.md:187, 269` | High |
| 9 | `--cycle-diff` header and plan still say "before that commit" | Minor | `build-loop.sh:178-181` | Medium |
| 10 | Cap matched as `== 4`; script uses `>= 4` | Minor | `SKILL.md:682` | Medium |
| 11 | "newest" vs "last" `Main at:` | Informational | `SKILL.md:235` | Low |

## Overall Assessment

The skill-to-script contract is in good shape. Slugs, Asked: items, merge headings, refusal substrings and machine line forms all agree with the script headers and code. The iteration-2 and C1-C10 fixes hold up from the interface side. Two issues need a decision before merge. Finding 1 is the C5 fix applied to only one of the two `--merge` call sites, so a routine dirty MAIN_WT spends the user's approval. It is a one-sentence fix in SKILL.md. Finding 2 is a D13 guarantee that the rubric marks Fixed when it is not: it needs either the retry or an honest override row. The rest is drift in the record template's contract with its own readers (findings 4-6, 8), incomplete refusal routing (7), and doc drift (3, 9-11). All of it can be fixed in SKILL.md, except finding 9, which is gate-code comment text.

## Goal-Alignment Note

Success criterion: "An API-consistency review saved at the given path, structured per the api-consistency-reviewer skill." Met. The report is at `docs/reviews/api-consistency-review-2026-10-13-u4b2-final.md` in the worktree. It has the header, Baseline Conventions, Name-Pattern Audit, Findings, What Looks Good, Summary Table and Overall Assessment. Each finding carries Severity, Location, verbatim Evidence, Confidence and a Legibility-target, and each naming finding (8, 10, 11) carries a Precedent line.

Evidence basis: finding 3 rests on an executed probe that runs the lib's own `option()` (`scratchpad/u4b2-i3c/api/probe-option.sh`, temp dir `/tmp/u4b2rv-api-*`). The other findings are static readings of the cited lines, with each enclosing unit read in full. This is a single-sample review, and an absence of findings is not an attestation.

Routed endorsement claims (route: code-fact-check):
- `SKILL.md:507-517, 683`: the slugs `blocked-/stopped-/capped-STEM-N` and the items `Q-NNN@TIP` / bare `Q-NNN` pass `--cycle-diff`'s Asked: rule when filed in the same land.
- `SKILL.md:490-494`: the merge heading rule (SHA12, lower-cased PATH against GATE_CODE) matches `approval()`.
- `SKILL.md:512`: a `> Reason: REASON` line cannot trip `--check-answer`'s link-reference or `<!--` whole-file skips.
- `SKILL.md:687`: step 10's second land passes `--land-cycle`'s chore-record rule, because the record changes and holds `Branch:`.
