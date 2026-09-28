Commit: 182d143

# Code Review Rubric

**Scope:** iteration 3 (final confirming pass, no `--loop-pass`): full branch `main...182d143`, fact-check k=3 (decision log 63) + Stage 2.5; iteration 2: `27d483b..21d4eb8` (k=1); iteration 1: full branch at 27d483b (k=1) | **Reviewed:** 2026-09-28 | **Status: ✅ PASSES REVIEW** — single-sample review; absence of findings is not an attestation

Naming: this file is the item-prefixed equivalent of the canonical `docs/reviews/code-review-rubric-2026-09-28-review-q087.md` (per the batch brief, to avoid merge collisions); sibling artifacts are `q087-code-fact-check-report.md`, `q087-security-review-2026-09-28.md`, `q087-api-consistency-review-2026-09-28.md`. Delivery mode: self-read (diff + enclosing files ~211 KB over the 25k-token budget; skill texts delivered to agents by mandatory full Read of their absolute paths rather than transcription).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Row 63's revisit trigger credits the ≥90%/≥20-claim falsifier to decision 031; it is the state doc §1.1 falsifier (`docs/thoughts/code-review-evaluation-state.md:78-79`, log row 27, action "k can drop to 2"). 031's own trigger (`031:196`) points toward more k. `docs/decisions/log.md:85` — "Revisit if final-pass replicate agreement on untouched code stays ≥90% over ≥20 claims (031's k-reduction falsifier, applied to this pass)." Convergence: fact-check + api-consistency (A2). Not escalated: tier T scopes a doc-only Incorrect to 🟡, and the corroborating Incorrect is this same finding. | Docs | Incorrect (high), doc-only; api Minor | Fact-check claim 7 + api-consistency A2 | for-author | — | Fixed (21d4eb8) | — |
| A2 | Row 60 still says the final pass runs "at 031's k=1, unchanged; raising it to k=3 is open as Q-087" with no pointer to row 63. `docs/decisions/log.md:83`. Convention: row 43's "SUPERSEDED BY #44" marker. Convergence: fact-check + api-consistency (A1). | Docs | Stale; api Minor | Fact-check claim 1 + api-consistency A1 | for-author | — | Fixed (21d4eb8) | — |
| A3 | On this branch Q-087 still reads `**Status:** OPEN` / `**Interim:** [1]` (`docs/working/questions.md:222`, `:232`) while the branch implements [2]. | Docs | Stale | Fact-check claim 8 | for-author | — | 🟡 Deferred | Deferred: Q-087 is archived ANSWERED on `answers-2026-09-28` (48bca90). Revisit trigger: if this branch merges without that one (override-log row). |
| A4 | The "recognized by the branch's canonical rubric existing without a `Loop closed at` line" clause (`skills/code-review/SKILL.md:453-454`, and row 63 at `docs/decisions/log.md:85`, which also drops "canonical") no longer decides anything: every run without `--loop-pass` takes k=3. It still reads as a check the orchestrator must run. | Docs / contract | Mostly accurate; api Informational | Fact-check claims 3, 12b + api-consistency A3 | for-author | 2026-09-28 `feat/u4-code-review-skill` Defer (override-log row 127) — this change moots it | Fixed (21d4eb8) | — |
| B1 | Row 60's in-place edit has no bold amendment marker (log convention: `:66` row 43, `:71` row 48, `:76` row 53 `**Amended 2026-09-27 (…):**`), and "(at 031's k=1, unchanged)" still reads as current. `docs/decisions/log.md:83`. Convergence: fact-check + api-consistency. | Docs | Mostly accurate; api Minor | Fact-check (iter 2) claim 8 + api-consistency (iter 2) 1 | for-author | — | Fixed (182d143) | — |
| B2 | Override-log A3 row cites the Interim line as `docs/working/questions.md:232`; it is at `:235` (`:232` is the [2] options row). `docs/reviews/override-log.md:80` | Docs | Incorrect (high), doc-only | Fact-check (iter 2) claim 11b | for-author | — | Fixed (182d143) | — |
| B3 | The replication test comment credits "k=3 for any run without --loop-pass" to decision 031; that scope comes from log 63. `test/skills/code-review-factcheck-replication.bats:142-144` | Docs | Mostly accurate | Fact-check (iter 2) claim 13 | for-author | — | Fixed (182d143) | — |
| B4 | Commit 21d4eb8's body says "the 11 suites … 292/292 ok"; 11 were selected but 10 ran (`code-fact-check-format.bats` NOT RUN: no generated reports). `/home/node/.claude/jobs/9f431b13/tmp/q087-tests-iter1.log:3-5` | Docs | Mostly accurate | Fact-check (iter 2) claim 16 | for-author | — | Won't-Fix | Override-log row; correct count stated in 182d143 body. |
| D1 | "Code no fix touches is drawn/redrawn **only** on the loop's first and final passes" holds only by default: Step 1 sends a `--loop-pass` to full scope when the stamp is missing, not an ancestor, or equals HEAD (`skills/code-review/SKILL.md:117-118`), and pr-prep 3d falls back to a full re-review (`workflows/pr-prep.md:248`). Sites: `skills/code-review/SKILL.md:131`, `:454-455`, `docs/decisions/log.md:85`, commit 27d483b body. | Docs | Mostly accurate | Fact-check (final, k=3) claims 5, 14, 17, 23 (r2; r1+r3 Verified with the same caveat) | for-author | — | Fixed (post-pass) | SKILL.md :131 and :454-455 and log row 63 now say "by default"; the 27d483b commit-body site is Won't-Fix (override-log row). |
| D2 | Step 7 says "Total agent count (3 fact-check replicates + N critics …)" for every run; a `--loop-pass` runs 1. Pre-existing on main, but it is the one plan-summary line this rule governs. `skills/code-review/SKILL.md:259-260` | Docs | Mostly accurate | Fact-check (final) claim 20 (r2, single-replicate) | for-author | — | Fixed (post-pass) | — |
| D3 | Override-log rows A3 and C4 cite "fact-check claim 8" / "claim 15 note" without the iteration; `q087-code-fact-check-report.md` is overwritten per pass, so at HEAD those numbers point at other claims. `docs/reviews/override-log.md:82-83` | Docs | Mostly accurate | Fact-check (final) claims 10, 11 (r1) | for-author | — | Fixed (post-pass) | — |
| D4 | Commit 182d143's B1 bullet cites rows 43, 48, 53 as precedent for the `**Amended …:**` marker; only row 53 uses that form (43, 48 use bold Superseded markers; `docs/decisions/log.md:66`, `:71`, `:76`). | Docs | Mostly accurate | Fact-check (final) claim 26 (r1+r2+r3) | for-author | — | Won't-Fix | Override-log row; commit-message wording only. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | Dependencies bullet says the final pass "stays k=3" (`skills/code-review/SKILL.md:20`), which reads as unchanged; under 031 on main it ran k=1. | api-consistency A4 | Informational | for-author | — | Fixed (21d4eb8) |
| C2 | Decision 031's record carries no "amended in part" note pointing to log row 63 (precedent: 030:11, 021:24). api-consistency notes row 60 amended 032 without one either. | Fact-check escalation | — | for-author | — | Fixed (21d4eb8) |
| C3 | Override-log row 127 (u4 Defer, "Revisit if Q-087 raises the final pass to k=3") has had its trigger fire; the deferred issue is moot and the row can be struck per the log's convention. | Fact-check escalation; considered-override scan | — | for-author | row 127 | Fixed (21d4eb8) |
| C4 | The test pins presence of the new final-pass k=3 phrase but not absence of stale final-pass k=1 wording, and does not cover the Dependencies bullet. | Fact-check claim 15 note | — | for-author | — | Won't-Fix (override-log row) |
| C5 | Step 3.5 match rules (`skills/code-review/SKILL.md:177-179`) do not say whether a struck override-log row still matches, and `references/override-log.md` does not mention the strikethrough convention stated at SKILL.md:1260. Pre-existing gap. | api-consistency (iter 2) 2 | Informational | for-author | — | Deferred (override-log row) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/u4-code-review-skill` / 2026-09-28 | Second standalone review classed as loop final pass, runs k=1 (`skills/code-review/SKILL.md` Stage 1) | 🟢 Consider → Defer | Rare; k=1 accepted by 031. Revisit if Q-087 raises the final pass to k=3. | Trigger fired: the issue is moot (both take k=3). Surfaced as A4/C3; row struck in 21d4eb8. |

---

## ✅ Confirmed Good

| Item | Verdict | Evidence | Source | Legibility-target |
|---|---|---|---|---|
| The new test assertion fails on main's SKILL.md and passes on the branch | ✅ Confirmed | `test/skills/code-review-factcheck-replication.bats:155` — "standalone single-pass reviews and to a loop.s final confirming pass"; FC claim 15 (executed): branch 17/17 ok, main-text copy `not ok 13` on this assertion | code-fact-check | for-orchestrator-synthesis |
| `--loop-pass` is the only condition selecting k=1 in Stage 1; no rubric-file check remains, and every run without the flag (incl. each closed loop's final pass) takes k=3 | ✅ Confirmed | `skills/code-review/SKILL.md:451-454` — "applies to every run without `--loop-pass`" … "The flag alone sets k, so no rubric check is needed"; FC submitted claims 28–30 (static; scope covers the Stage 1 paragraph and every `Loop closed at` writer, `rg` repo-wide) | security-reviewer + api-consistency endorsements, verified by fact-check Stage 2.5 | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| performance-reviewer | no fact-check claims or diff content in domain | `git diff --stat`: two markdown files + one bats assertion; no loops, queries, data structures, dependencies |

---

## 🧩 Composition check

| Cluster | File / lines | Fragments | Disposition |
|---|---|---|---|
| 1 | `docs/decisions/log.md:83-85` | FC 1, 3, 7; api A1, A2 | distinct defects: each fragment states its own mechanism and fix |
| 2 | `skills/code-review/SKILL.md:443-456` | FC 12b; api A3 | distinct defects: same finding restated, no hidden root |

---

## Loop outcome

Hard cap reached at iteration 3 with exit condition 1 met: no Must Fix, and every Must Address fixed or acknowledged (override-log rows). The final confirming pass itself was not clean (D1–D4), so no `Loop closed at` line is written. The post-pass fixes (D1–D3) were checked only by the fix-drift lite check and the affected test suites, not by another full pass.

## Re-flagged settled decisions

- Final fact-check claim 25 (commit 21d4eb8 "the 11 suites … 292/292 ok"; r3 Incorrect, r1/r2 Mostly accurate) matches override-log row B4 (2026-09-28, `review/q087`, Won't-Fix: "correct count stated in the next fix commit's body"). No action — see override-log.

## Escalations (orchestrator → user)

- **Merge conflict with current `main` (6a370cb).** `git merge-tree` reports content conflicts in `docs/decisions/log.md` (main's new row 62 sits where this branch's row 63 goes) and `docs/reviews/override-log.md` (both sides add rows at the top of the table). Both are append-at-same-spot conflicts; the resolution is to keep both sides (row 62 then 63; both sets of override rows). Not merged here: the batch brief forbids merging, and pr-prep 4.3 requires the main-into-branch merge before the final gate.

- Iteration 2 fact-check escalated "strike convention undocumented": refuted, it is documented at `skills/code-review/SKILL.md:1260` (api-consistency iter 2 agrees); the remaining gap is C5.

- Log row numbering: this branch has row 63 but no row 62; row 62 (Q-085) lives on `answers-2026-09-28`. Merging this branch alone leaves a gap.
- Duplicate commit: 27d483b duplicates 65e51b7, already on `answers-2026-09-28`, whose 48bca90 archives Q-087 "Done in 65e51b7".

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see "Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
