# Research: Behemoth Arsenal's review-gap causes against this repo's

Date: 2026-11-20 · Brief: `docs/working/briefs/2026-11-20-review-gap-ba-compare.md` · Branch: `docs/review-gap-ba-compare` · Base: b7663bf2

Question: for each cause the Behemoth Arsenal audit gave for its 44 review gaps (Q-302's answer, `docs/human-author/answers-11-20-26.txt:124-236`), does this repo have the same cause, did a fix merged here cover it, and could it still happen here today? For each cause no fix covers, is one worth building here?

Inputs read: the Q-302 section of the answers file; this repo's audit, `docs/working/research-2026-11-13-review-gap-audit.md` (merged 84f8532e); the two units that fixed it, the review rules (21097afa, `workflows/review-fix-loop.md`, `workflows/pr-prep.md`, `skills/code-review/references/rubric.md`, `skills/code-review/references/override-log.md`) and the merge-time rubric check (1b50402c, `scripts/lib/rubric-check.sh`, called from `scripts/build-loop.sh`); `docs/constraints.md`. Commands run: `git` and `rg` only, plus reads.

Failure-pattern grep: FP-064

FP-064 (2026-07-29, rubrics overwritten each run) is the only `docs/failure-patterns.md` entry that names rubrics, fast-forwards or review timing. It explains why superseded rubrics accumulate (Behemoth Arsenal's agent-dispatch pass-1 rubric, this repo's landing 1) and does not bear on any uncovered cause below.

## Answer

Behemoth Arsenal's causes and this repo's are the same set, and the rules merged here (21097afa) name every one of them except lapsed revisit triggers. What the fixes here do not cover is **where the check runs, not what it checks**:

1. **Landings outside the build loop get no check at all** (Behemoth Arsenal's "hand merges and fast-forwards"). This is live here: since the rules merged on 2026-11-14, `main` took three hand merges with no `Build-loop-gate:` trailer that carried skill code, one direct `feat(skills)` commit, and four fast-forwards. Two of the skill landings left no committed code-review rubric. No finding is known to have been lost, but neither audit can see a landing that left no rubric, so "none known" is partly an artefact of the procedure. **Worth a brief: an advisory detector in the dev cycle** (brief 1 below).
2. **Fired revisit triggers do not reopen a row.** The rubric check counts the word "trigger" as an amber's closure whether or not it has fired. It happened here once (4dc84ce4) and the next review caught it. **No change**: testing a free-text trigger is a judgment (H4), and the frequency is one in 108 rubrics.
3. **The stale line is advisory.** Here as there it produced no gap, only false alarms. **No change.**
4. **Still-true rows never routed** (Behemoth Arsenal's "re-tally"). This repo's audit named six gap rows that still held (iter3 N5, N13, N17, N18; questions-closeout A10, A11), and none of them reached the roadmap, an override row or a fix. **Worth a brief: close the six rows** (brief 2 below).

Making the build-loop check blocking, the half of Behemoth Arsenal's first fix that does apply to the build loop, already has a path here: the merge-rubric-gate design's falsifier (10 build-loop landings whose quoted lines are all real gaps, `docs/working/research-2026-11-14-merge-rubric-gate.md:45`). It is not briefed again.

## Comparison

"BA" is Behemoth Arsenal. "Here" names this repo's 2026-11-13 audit by landing number or row. "Rules" is 21097afa; "check" is the advisory rubric check of 1b50402c, which runs only in `build-loop.sh --check` and `--merge` and changes no verdict (`scripts/build-loop.sh:520-522`, `scripts/lib/rubric-check.sh:1-8`).

| # | BA cause (GAP rows) | Matching cause here | Fix merged here | Could it occur here today? |
|---|---|---|---|---|
| 1 | Bypassed: a merge with an open red or blank-note amber, landed by hand merge or fast-forward (ui-polish 3cc65ef4, S5 A10/A14, multiplayer A36; 31 rows) | Landing 3 (3a98f9e5, fast-forward, 8 rows); U2a2 D1 | Rules: exit 2 needs a filled note on every open amber, no fast-forward to `main` (`pr-prep.md` local-merge bullet), Step 7 landing check. Check: open rows printed at build-loop merges | **Yes, outside the build loop.** The Step 7 check is prose the merging session runs itself. Since 2026-11-14: hand merges 44000c6d, 386ccfa3 (skills, no `Build-loop-gate:` trailer; 386ccfa3's message is its subject alone) and 22735b6e; fast-forwards of `main` at 21e925d3, a81ddd8f, 21369f28, f85c006b (`git reflog show refs/heads/main`, entries ending `: Fast-forward` without `build-loop`). At build-loop merges: partly, until the falsifier passes, since an open red does not stop `--merge` |
| 1a | Bypassed: a general "best judgment" owner authorisation closed reds (ui-polish) | None found; owner exits here cite a Q-ID (audit, "Other observations") | Rules: a red closes only by Fixed, Split, Carried or the owner's `Q-NNN` (`rubric.md` "Status words"). Check: a red closes only by a fix or an answered Q-ID (`rubric-check.sh:55-63`) | At build-loop merges the check flags it (advisory); at hand merges, yes |
| 1b | Bypassed: `escalate` at the cap with no question filed (defeat-terminal A6, A7, A12) | Landing 3 (iter3 recorded `escalate`; leftovers never filed) | Rules: "Recording `escalate` does not close the loop" (`review-fix-loop.md`, cap gate) | Yes: no script reads a cap decision (`rg -n -i escalat scripts/lib/rubric-check.sh` prints nothing). In a build loop the `handoff: blocked` marker carries it; elsewhere it is prose |
| 1c | Red deferred by an agent-written override row with no owner Q (action-log-refactor A7, A8; not a GAP there) | U2a2 D1 (bypassed red) | Rules: `pr-prep.md` "needs the owner's answer"; check: as 1a | As 1a |
| 1d | Accepted-immutable used on a red (two rows; not GAPs) | None | Rules: the Status words table lists `Accepted-immutable` for 🟡 only; check: as 1a | As 1a |
| 2 | No-gate: reviewed after landing (beadssolver R2, R3 and nine ambers, direct commits on main) | Landing 2 (435f46aa, review of a range on `main`) | Rules: pr-prep "the review runs before landing, never after"; `rubric.md` "Review of code already on main" routes every open row before the rubric lands | **Yes.** Prose only, and nothing compares a rubric's `Commit:` stamp with the landing (`rg -n -i 'commit:\|is-ancestor\|merge-base' scripts/lib/rubric-check.sh` prints nothing). ded17c89 (2026-11-18), a `feat(skills)` commit made directly on `main`, has no review record (`rg -l ded17c89 docs/reviews` prints nothing) |
| 3 | No-gate: a revisit trigger had fired before the merge (09-04 A13 fired three times, S4 A11) | Observation, not a gap: a Defer row's trigger fired at 4dc84ce4 and U1c A20 caught it | **Not covered** | Yes: the check closes an amber on the keyword "trigger" or "revisit … if/when/once/after" (`rubric-check.sh:115`), fired or not |
| 4 | Stale records: fixed by a commit, record never updated (no GAPs; most false alarms) | RESOLVED-COMMIT rows; stale-rubric 0 | Rules: the fixing commit sets `Fixed` (`pr-prep.md` 3b), the next pass marks rows by ID (3d.2). Check: a `stale` line per rubric (`rubric-check.sh:282`) | Yes, advisory; harmless by both audits' counts |
| 5 | Rule drift: six rows met the September rule but fail today's; six still-true rows missing from the roadmap | Rows judged by the rule in force (audit, "Rule in force"); six still-true gap rows: iter3 N5, N13, N17, N18, questions-closeout A10, A11 | **Not covered**: no roadmap item, override row or fix names them (`rg -n 'N13\|N17\|N18\|questions-closeout' docs/roadmap.md docs/working/idea-log.md docs/working/watching.md` prints nothing) | The rows' cited text is still in place: `scripts/questions.sh:51-54` (N5's symlinked-`docs/` claim), `hooks/guard-trusted-writes.py:359,373` (N13's `normpath`), `:391` (N18's "Case-folded on purpose"), `scripts/lite-review.py:185` (A10's `--mode full` default, no caller passes it: `rg -n -- '--mode' scripts skills workflows` finds `lite-review.py` called only with `--mode fix-drift`) |
| 6 | Superseded pass-1 rubric left reading "DOES NOT PASS" with no Carried-forward table (agent-dispatch; not a GAP) | Landing 1 (f6dc3f15, superseded loop never closed) | Rules: a superseding loop opens with a Carried forward table (`review-fix-loop.md`, `rubric.md`). Check: reads the table's rows; prints `superseded OLD by NEW (not read)` for older dated files | Partly: an older file's open rows are not read, so a missing Carried forward table shows only as the `superseded` line |
| 7 | Landings that left no record at all (defeat-terminal and multiplayer fast-forwards) | Not seen by this repo's audit, which reads only rubrics | **Not covered** | Yes: 386ccfa3 merged skill code whose fix commit c2422112 says "Ten defects from a fresh review, all fixed", but no rubric or report for it is in `docs/reviews/` (`rg -l audience-skills-v2 docs/reviews` prints nothing); 44000c6d carried only self-evals |
| 8 | "Partly fixed" counted as resolved in a header (beadssolver R2) | Scanner false negatives on "Unresolved" (audit, Review iteration 1) | Check: "partly", "partially", "unresolved" and more read as not fixed (`rubric-check.sh:41-48`) | Flagged at build-loop merges; prose elsewhere |

Since 2026-11-14, `main` took 161 first-parent merges and 19 first-parent non-merge commits (`git log --first-parent --since=2026-11-14 main`, with `--merges` and `--no-merges`). Of the merges, the three named in row 1 are the only ones that are neither build-loop merges nor dev-cycle records.

## Uncovered causes: worth a fix here?

### Landings outside the build loop (rows 1, 1b, 2, 7)

**Motive (S5).** It has happened here since the fixes: four code landings in two days went outside the build loop: skill code at 44000c6d, 386ccfa3 and ded17c89, and dev-cycle code at 22735b6e (which did carry a rubric and documented its split). Three left no code-review rubric. No lost finding is known, and the honest reading is that nothing could know: both audits read rubrics, so a landing without one is invisible to them. The value is outside this repo too: the same skills ship to the owner's other projects.

**Design choice** (3+ options, so divergent design, seeded with `docs/constraints.md` and the brief):

| Option | What it means | Constraints |
|---|---|---|
| [A] Blocking hook on `refs/heads/main` (BA's fix) | a `reference-transaction` or merge hook refuses a landing with open rows | H1 prunes a hook in the checkout's git dir (a session can edit it); a root-owned `core.hooksPath` needs `install.sh` growth (S8) and a release. S10: blocks the owner's own hand merges |
| [B] Advisory detector in the dev cycle | each cycle lists landings on `main` since the last cycle that change `skills/`, `workflows/`, `scripts/` or `hooks/` outside a build-loop merge, each with whether a rubric landed with it and that rubric's open rows | H4 (re-checkable from git), S3 (reuses `rubric_lines`' reading), S6 (observable: the count, which can be zero), S10 (a line in the record, no chore) |
| [C] Build loop the only path to `main` | a rule that code reaches `main` only by `build-loop.sh --merge` | S10 and S1: stops owner hand merges; prose, so the same slip class |
| [D] No change | rely on prose (pr-prep Step 7) and re-run the audit | S5 permits it, but the slip recurred four times in five days and the audit cannot see it |

**Path A: [B] dominates.** [A] fails H1 as a checkout hook and S8/S10 as an installed one; [C] costs the owner and is still prose; [D] leaves the one instrument that could see these landings missing. [B] keeps the hard constraints and its observable can come out negative.

**Fast-forwards.** The four since 2026-11-14 were docs-only branches (answers, roadmap cleanup, terminal entries, a Q answer) with no review to record, so they lost nothing. `pr-prep.md`'s "`main` is never fast-forwarded" sits inside the local-merge path, which is for reviewed branches; brief 1's detector counts only code paths, so docs fast-forwards stay out of it. A wording change scoping the rule is optional and not briefed.

### Fired revisit triggers (row 3)

**No change.** Once in 108 rubrics, caught by the next review. Deciding whether "with the next edit to X" has fired means reading a free-text trigger against a diff, which is a judgment: under H4 it would ship advisory, beside an advisory check that already prints the row's trigger text. The residual risk stands: an amber whose trigger has fired reads as closed.

### Stale line advisory (row 4)

**No change.** Zero gaps from stale records in either audit; the line exists and is quoted. Blocking it would stop self-merges on false alarms (S10).

### Still-true rows (row 5)

**Motive.** Six rows this repo's audit found still true were never routed; the audit's step 7 named them, and its fix briefs covered rules and the check, not these rows. Three are comments that misstate behaviour in gate or hook code (N5, N13, N18), which is the class that misleads the next reviewer. One pass closes them. Behemoth Arsenal's other drift item, re-judging rows that met the September rule against today's, is not worth repeating here: those rubrics review mostly archived code (landing 1's harness is gone), and the six rows are the ones still true.

## For the dev cycle

Behemoth Arsenal's own fixes are that repo's and are not briefed here.

**Brief 1: list landings outside the build loop.**
- Goal: each dev-cycle pass reports, for every first-parent commit on `main` since the previous cycle record that changes `skills/`, `workflows/`, `scripts/` or `hooks/` and is not a build-loop merge (no `Build-loop-gate:` trailer), the commit, whether a `docs/reviews/*code-review-rubric*` file landed in it, and that rubric's open rows read by `scripts/lib/rubric-check.sh`. Advisory: a line in the digest and the record, no verdict. Observable (S6): the count per cycle; if it stays zero for ten cycles, remove it.
- Motive: rows 1, 2 and 7 above; 44000c6d, 386ccfa3 and ded17c89 since 2026-11-14.
- Paths: `scripts/dev-cycle.sh` (digest), `scripts/lib/` if `rubric_lines` needs a caller outside `build-loop.sh`, `skills/dev-cycle/SKILL.md` (where the line is quoted), `test/` for its bats cases.
- Policy: review (all three code paths are gate code under GATE_CODE, `scripts/lib/dev-cycle-read.sh:1038`).

**Brief 2: close the six still-true rows of the 2026-11-13 audit.**
- Goal: for iter3 N5, N13, N17, N18 (`docs/reviews/code-review-rubric-2026-09-21-answers-2026-09-20-iter3.md`) and questions-closeout A10, A11 (`docs/reviews/code-review-rubric-2026-09-12-main-questions-closeout.md`), confirm each still holds, then fix it or close it with a revisit trigger or a Won't-Fix override row.
- Motive: row 5 above; the audit's step 7 named them and nothing routed them.
- Paths: `scripts/questions.sh` (N5), `hooks/guard-trusted-writes.py` (N13, N18; an enforcement file, so a `Live-verified:` trailer), `scripts/lite-review.py` and its docs (A10, A11), `docs/reviews/override-log.md` (N17 and any Won't-Fix rows).
- Policy: review (`scripts/questions.sh` is gate code, and `docs/reviews/override-log.md` is on the self-merge floor).

The roadmap Now item "Review-gap audit in Behemoth Arsenal" closes with this comparison: its open work is these two briefs.

## Review

(Filled by the review-fix loop.)
