Commit: 0f0c7e1c
Loop closed at 0f0c7e1c
Loop-pass short-circuit: used at 414c9295

# Code Review Rubric: feat/build-loop-u3c

**Scope:** full branch, `git diff main...HEAD` (main dafc0e74; first pass of the loop). Delivery mode: self-read (shared brief on disk).
**Iteration 1** (`--loop-pass`, k=1 fact-check). Stopped at Stage 1 by the first-red short-circuit.
**Reports:** `docs/reviews/code-fact-check-report-2026-10-12-u3c-i1.md`.

## 🔴 Must Fix

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A1 | `--cycle-diff` sorts each side's key lines before comparing, so the order of lines inside an entry is lost; `--check-answer` reads an entry's first Needs line and first answer line. Swapping two answer lines (`drop` → `keep`) or two Needs lines (`open` → `keep`) passes with no `--answered`: the F33 laundering the mode exists to stop. Fix: compare key lines in file order within each entry, a move between the two files still free; add a reorder case to T38. | fact-check claims 4, 10, 32 (executed, probes P1, P2) | Incorrect (high), behavioral | `scripts/build-loop.sh:1848-1850` `LC_ALL=C sort -o "$t.qo" "$t.qo" && LC_ALL=C sort -o "$t.qn" "$t.qn"`; `scripts/lib/dev-cycle-read.sh:2084-2092` (`!header && /^\*\*Needs:\*\*/` ... `!done {`) | Fixed in d77dae74 |

## 🟡 Must Address

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| A2 | Commit f34fceb0's body says row 722 is "re-keyed to U4", but `docs/reviews/override-log.md` has no such row on the branch. | fact-check claim 32 | Incorrect (doc) | `docs/reviews/override-log.md:722` unchanged | Fixed in d77dae74 |
| A3 | T38's comment lists "a new archive file" but no new-file case runs; "a deleted entry" has no case of its own. | fact-check claims 27, 28 | Incorrect / Mostly accurate (test text) | `test/scripts/build-loop-orchestrator.bats:408,413` | Fixed in d77dae74 |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| A4 | Header "A new file ... is not judged" is false for a new questions file (it is judged, and refused when filed answered). | fact-check claim 13 | Fixed in d77dae74 |
| A5 | cyc_blob's comment names the all-zero id; it tests mode 000000, and returns gate_git's status (possibly 3), not 1. | fact-check claim 20 | Fixed in d77dae74 |
| A6 | QKEYS_AWK does not repeat ANSWER_AWK's whole-file refusals (a fenced `### Q-` heading, a duplicate heading); fails safe. | fact-check claims 3, 11, 17 | Won't Fix (fails safe) |

## ⏭️ Skipped Core Critics

| Critic | Reason |
|---|---|
| security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review | loop-pass short-circuit (behavioral red confirmed) |

## Considered overrides

- Row 724 (three `--raw -z` readers): discharged by raw_records; fact-check found it equivalent to the old readers (chore loop now classes an unparsed record other).
- Row 722 (a chore merge's other paths): kept deferred by this unit; the re-key row is owed (A2).
- Row 682 (health-check.sh not gate code): pre-existing, routed to U5/Q-103.

**Status (iteration 1):** 🔴 1 Must Fix, 🟡 2 Must Address, 🟢 3 Consider; all fixed in d77dae74 but A6 (fails safe). Iteration 2 runs the full panel over the full branch (the critics have not yet read it).

---

# Iteration 2 (`--loop-pass`, k=1 fact-check, full panel, full branch at 74deb04e)

**Scope:** full branch (`--full`): iteration 1 short-circuited at the fact-check, so no critic had read the code. Delivery mode: self-read (shared brief on disk). Dispatch mode: parallel. Stage 2.5 skipped (loop pass): routed endorsements (security 1-3) stay *pending execution verification*.
**Reports:** `code-fact-check-report-2026-10-12-u3c-i2.md` (33 claims: 29 Verified, 4 Mostly accurate, 0 Incorrect), `security-review-2026-10-12-u3c-i2.md`, `performance-review-2026-10-12-u3c-i2.md`, `api-consistency-review-2026-10-12-u3c-i2.md`, `architecture-review-2026-10-12-u3c-i2.md`.

## 🔴 Must Fix

None.

## 🟡 Must Address

| ID | Finding | Source | Severity | Evidence | Status |
|---|---|---|---|---|---|
| B1 | A chore branch --cycle-diff passes can still turn the user's drop into keep once merged: --cycle-diff judges the branch against the fork point, --check-answer reads the merge, and a fence pair (free body lines) added around the place a user answer lands on main meanwhile fences it off after a clean merge. Executed (probe-merge.sh: open → ok → drop on main → merge → keep). Fix: refuse a questions change while main has changed the questions files since the fork point; U4 lands only from the checked MAIN_SHA. | security F1 (Medium; mechanism High, executed) | Medium | `scripts/build-loop.sh:1808` `if ! base="$(git merge-base HEAD "$MAIN_SHA" 2>/dev/null)"` | Fixed (pending commit): the rule, a T38 case, U4 row |
| B2 | The answer grammar is hand-copied in three awk readers (ANSWER_AWK, ANSWERS_AWK, QKEYS_AWK/QDIFF_AWK) and the lib's pointer comment named only ANSWERS_AWK: widening one fails open on F42. | architecture 1 (Coupling) | Coupling | `scripts/lib/dev-cycle-read.sh:2055-2056` "build-loop.sh's ANSWERS_AWK ... copies these labels ... change both together." | Fixed (pending commit): pointer names all readers; a test pins the label regex in all three (shared lib prelude deferred: the cap) |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| B3 | raw_records' globals read by index across cycle_diff (cyc_blob took a record index). | architecture 2 | Fixed: cyc_blob MODE ID OUT |
| B4 | A failed read of an unchanged questions file on the base was skipped as absent (`cat-file -e`), not refused; second reader beside cyc_blob. | architecture 3, fact-check claim 15 (executed) | Fixed: one `ls-tree -z` reader; a failed listing refuses |
| B5 | ROADMAP_AWK's exact "## Done" is stricter than dev-cycle.sh's section match; the frozen preamble holds a dated line; SKILL.md step 6 does not point back. | architecture 4 | Done match fixed (test uses `## Done (last cycle)`); preamble and step-6 pointer: override row (U4) |
| B6 | raw_records' NUL count forks `tr|wc` per call: --main-log over 1,100 commits +4.3 s (+21%). | performance 1 (measured) | Fixed: fork-free half-record check |
| B7 | The header's Exit paragraph omits --cycle-diff. | api-consistency 1 | Fixed |
| B8 | Plan lines 104 and 209 still said "against MAIN_SHA". | api-consistency 2 | Fixed |
| B9 | HEALTH_CHECK_LOCK_HELD disabled the lock for any non-empty value; documented beside test-only seams. | api-consistency 3, architecture 5 | Fixed: `== 1`, documented "When 1", not only a test seam |
| B10 | Refusal subjects (HEAD, index, a path) and the ID's place in a questions refusal were undocumented; --answered's matching (exact, repeats, unused IDs) undocumented. | api-consistency 4, 5 | Fixed: header text |
| B11 | Unbounded lock wait; FIFO swap between test and open; flock missing exits with flock's status. | security F3, performance 2, api-consistency 6 | Deferred: override row (U4 / Q-103 class) |
| B12 | --answered is the orchestrator's own unrecorded claim. | security F2 | Deferred: override row (U4 records the IDs) |
| B13 | The orchestrator's commit runs the common dir's hooks after the check. | security F4 | Deferred: override row (U4 commits the checked tree) |
| B14 | Override row 746's "an unparsed record" omits the incomplete-record case. | fact-check claim 2 | Fixed |
| B15 | T38 comment omitted the deleted-archive case; the "appended open entry" was moved with Q-003. | fact-check claim 28 | Fixed |
| B16 | Commit 3021d0a4's body lists a deleted-entry case the commit lacked (added in d77dae74). | fact-check claim 30 | Accepted: branch history, not rewritten |

## Considered overrides

Rows 724 (discharged), 722 (re-keyed to U4 by this branch's row), 682 (pre-existing, U5/Q-103): as in iteration 1; no critic re-argued them.

**Status (iteration 2):** 🔴 0, 🟡 2 (B1, B2; fixed in the batch below), 🟢 14. Next: iteration 3, the final confirming pass (k=3, full panel, Stage 2.5) over the full branch.

---

# Iteration 3: final confirming pass (k=3 fact-check at ec9dace7; critic panel at 4aad0f9c)

**Scope:** full branch. Fact-Check Gate (behavioral Incorrect, high) taken as **Fix first** in /away mode: 4aad0f9c fixed it, then the critics reviewed 4aad0f9c. Dispatch mode: parallel. Stage 2.5 folded into the confirming pass below (the code changed again).
**Reports:** `code-fact-check-report-2026-10-12-u3c-final.md` (merged k=3: 59 clusters, 44 Verified, 12 Mostly accurate, 2 Incorrect, 1 Unverifiable; agreement 78.0%) and replicates `-final-r{1,2,3}.md`; `security-review-2026-10-12-u3c-final.md`, `performance-review-2026-10-12-u3c-final.md` (no findings; --main-log fix measured), `api-consistency-review-2026-10-12-u3c-final.md`, `architecture-review-2026-10-12-u3c-final.md`.

## 🔴 Must Fix

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| C1 | QKEYS_AWK lacked --check-answer's whole-file "quoted" skip: with a fenced `### Q-NNN ` heading on main, an index removing only that free line passed and made the file's answers readable (skip → keep). d77dae74's "fails safe" was wrong. | merged fact-check claim 53 (r1, r3 executed: Incorrect high) | `scripts/lib/dev-cycle-read.sh:2082` `infence && /^### Q-[0123456789]+ / { if (!qline) qline = NR; inside = 0 }` vs QKEYS_AWK `fence($0) { next }` | Fixed in 4aad0f9c (both sides refuse; T38 base-side bypass case) |

## 🟡 Must Address

| ID | Finding | Source | Evidence | Status |
|---|---|---|---|---|
| C2 | A criss-cross history (several merge bases) defeats the main-changed rule: `git merge-base` picks one, the land merges through a virtual base; reproduced to keep. | security F1 (Medium, reproduced) | `scripts/build-loop.sh` cycle_diff: `base="$(git merge-base HEAD "$MAIN_SHA" ...)"` | Fixed (pending commit): `merge-base --all`, several refuse; T38 case (red without it) |
| C3 | The answer grammar's newest rule (fenced-heading skip) was a fourth unguarded copy; pointer and parity test did not cover it. | architecture 1 (Coupling) | `scripts/build-loop.sh` QKEYS_AWK END `else if (q) print "quoted " q` | Fixed (pending commit): the whole-file verdict is ANSWER_AWK itself (id Q-); QKEYS_AWK's copy removed; pointer updated |

## 🟢 Consider

| ID | Finding | Source | Status |
|---|---|---|---|
| C4 | The main-changed refusal also covered a listing failure, and was the one refusal with a recovery U4 must act on. | api-consistency 1 | Fixed: listing failure is `refuse index`; text pinned in the plan's As-built note |
| C5 | The plan's U3c bullet had no As-built note. | api-consistency 2 | Fixed |
| C6 | A BASE-side whole-copy refusal is a stop for the user (only a fix on main clears it). | api-consistency 3 | Fixed: header |
| C7 | Row 722's re-key too broad: GATE_CODE changes and a retargeted `Asked:` line decide what counts as an answer. | security F2 (Low) | Fixed: the row names both as U4 duties |
| C8 | Every process a locked health check starts inherits HEALTH_CHECK_LOCK_HELD=1. | security 3 (Info) | Accepted: documented in the header |
| C9 | cycle_diff reads RAW_* globals by index across its body. | architecture 2 (Info) | Accepted: safe while nothing in cycle_diff calls raw_records again |
| C10 | No main-moved guard for the roadmap or idea log. | fact-check escalation E-3; architecture 3 | Accepted: only the questions files feed a reader that decides from merged content; clean merges cannot drop a brief line; idea-log appends conflict |
| C11 | Wording: Done before a space; deletion of a questions file judged by entries; health-check's own exits; flock missing exits 127; T38 comment; refusals naming questions.md when only the archive changed; parity test counts per file. | merged fact-check Mostly accurate | Fixed in 4aad0f9c, but the last two (accepted) |
| C12 | Commit-text claims in branch history: ec9dace7's diff-tree reason (the call lacked -r), its 4.3 s timing (not re-run), 3021d0a4's "fail" (the mutant hangs). | merged fact-check claims 55, 57, 49 | Accepted: branch history, not rewritten |

## Considered overrides

Rows 724 (discharged), 722 (re-keyed, now sharpened by C7), 682 (pre-existing): as before. This branch's iteration-2 deferral rows (lock wait, --answered record, hooks, land from checked MAIN_SHA, roadmap preamble) were judged correctly scoped by the final security critic.

**Status (iteration 3):** 🔴 1 (fixed 4aad0f9c), 🟡 2 (fixed in the batch after 4aad0f9c, unreviewed). The loop is at its 3-iteration cap: the iteration-4 gate's decision is **escalate to a narrow confirming pass** (k=1 fact-check with the routed endorsement claims, plus security, over the fix range), as U3a1 and U3a2 did under Q-137; merge on no new Must Fix.

---

# Confirming pass (iteration-4 gate: escalate; k=1 fact-check with Stage 2.5 + security over 4aad0f9c..0f0c7e1c)

**Reports:** `code-fact-check-report-2026-10-12-u3c-confirm.md` (27 claims: 23 Verified, 4 Mostly accurate; 6 submitted claims all Verified, claim 23 by a 3,042-pair differential fuzz), `security-review-2026-10-12-u3c-confirm.md`. Suites at 0f0c7e1c: 291/291 (orchestrator 24, read 20, merge 12, dispatch 4, lock 2, check 146, dev-cycle 79, fixtures 2+2).

| ID | Finding | Source | Status |
|---|---|---|---|
| D1 | C2 and C3 closed: the criss-cross fixture refuses at HEAD (ok at 4aad0f9c); ANSWER_AWK with id Q- adds no fail-open (13 inputs; any output or awk failure refuses). | security confirm 1-2, fact-check 22 (executed) | Verified |
| D2 | Rename pairing at the land: a questions file absent on the base, created by the index while a similar file main edited is deleted, lands main's edit in it (executed). Older than the fix range. | security confirm (Medium, Low confidence) | Deferred: override row (U4's land judges the merge-tree result) |
| D3 | "id Q- names no entry" is false for a bare `### Q-` heading (fails closed: refuses); "a questions refusal's WHY starts with its ID" holds for entry refusals only. | fact-check 5, 13, 26b; security Info | Fixed: comment and plan text |
| D4 | 0f0c7e1c's message repeats "names no entry" and omits the lock-test header compaction. | fact-check 19 | Accepted: branch history |

**Status:** 🔴 0, 🟡 0 open in this unit (D2 deferred by override row with a U4 trigger), 🟢 text fixed. Recommendation: merge. Single-sample review; absence of findings is not an attestation.
