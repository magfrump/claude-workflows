Commit: c8435580
Loop-pass short-circuit: used at c8435580
# Code Review Rubric

**Scope:** `main...feat/build-loop-u1a` (full branch: d6426e3e, c8435580; no prior rubric for this slug), iteration 1 `--loop-pass` (k=1) | **Reviewed:** 2026-10-05 | **Status: 🔴 DOES NOT PASS** — 1 red item(s) unresolved

Reports: `code-fact-check-report-build-loop-u1a.md` (k=1, executed probes; bats 64/64 passing). Delivery mode: self-read (diff 25 KB inline-sized, but diff plus enclosing files ~212 KB is over the 25k-token budget; agents read the saved diff and files themselves). Deviation from the skill: the fact-check agent read its skill file itself rather than having it pasted. The pass short-circuited at the fact-check gate (behavioral 🔴, first short-circuit of this loop; no enforcement file in the diff, so no security critic was forced). Stage 2.5 skipped (loop pass).

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | brief_fields captures awk's output with `out="$(git cat-file blob … \| awk …)"`; bash command substitution drops NUL bytes (with an "ignored null byte" warning), so BRIEF values are not the line "whole". check_brief then tests the NUL-stripped value, so a first Status line `Status: op<NUL>en` now reads as `open`, where main's in-awk exact match refused it (regression); `Branch: feat/a<NUL>;b` becomes `Branch: feat/a;b` for U1b's consumers. Executed probe P2 against main's and the branch's lib. Fix direction (fact-check): refuse a NUL byte inside brief_fields' awk before printing (fact-check claims 10a, 11a) | Correctness / input handling | Incorrect (high confidence), behavioral, executed | Fact-check | `scripts/lib/dev-cycle-read.sh:279` (capture), `:264-265` (comment "whole"), `:327-328` (Status check) | for-author | — | 🔴 Unresolved |

---

## 🟡 Must Address

Short-circuited pass: amber is not collected (decision 032 #4, mechanic 4) except escalations whose addressee never ran, which the dead-letter rule force-surfaces here.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | brief_fields drops NUL bytes from BRIEF values; judge whether every U1b consumer re-validates BRIEF[branch]/[paths]/[policy]/[asked] or brief_fields refuses NUL (`scripts/lib/dev-cycle-read.sh:279-292`, addressee security-reviewer) | Security | Unrouted-Escalation | fact-check escalation (unrouted) | for-author | — | 🟡 Open | Addressee did not run: loop-pass short-circuit. Largely subsumed by R1's fix. |
| A2 | main_entry prints `absent` and returns 0 when `git ls-tree` fails (empty/invalid MAIN_SHA; error only on stderr); check_brief maps absent to `ok … new`, failing open. Current callers gate main_by_name first; U1b's callers rely on the comment's precondition alone (`scripts/lib/dev-cycle-read.sh:255`, addressees security-reviewer, api-consistency-reviewer) | Security / API | Unrouted-Escalation | fact-check escalation (unrouted) | for-author | Related: override row 208 (main_by_name in another repo, Won't-Fix) — different failure (ls-tree error, not cross-repo) | 🟡 Open | Addressees did not run: loop-pass short-circuit. |
| A3 | Each directory pathspec makes ls-tree list that directory's children: a questions.md lookup reads all of `docs/` and `docs/working/`, twice per question ID; probably negligible, flagged for U1b's `--status` per-brief loop (`scripts/lib/dev-cycle-read.sh:255`, addressee performance-reviewer) | Performance | Unrouted-Escalation | fact-check escalation (unrouted) | for-author | Related: override row 201 (check_brief per-brief cost, measure in U1) | 🟡 Open | Addressee did not run: loop-pass short-circuit. |
| A4 | The test "check_answer reads git only: … SKIPPED untouched" uses a fixture on which the old check_answer would also leave SKIPPED at 0, so the assertion cannot fail; a symlinked questions file on main would make it bite (`test/scripts/dev-cycle.bats:1160`, addressee orchestrator / test-strategy) | Tests | Unrouted-Escalation | fact-check escalation (unrouted) | for-author | — | 🟡 Open | No test-strategy critic selected (diff has test changes); orchestrator did not action it on a short-circuited pass. |

Fact-check findings not tiered this pass (short-circuit; mechanism kept visible, they re-enter at the next pass): claim 4 Incorrect (comment) — lib header `:10-11` names `build-loop-read.bats`, which does not exist at c8435580 (U1b's), and without its `test/scripts/` path; claim 8 Stale — `:238-240` still says only check_brief and check_branch read main's commit; claims 1b/13/15 Mostly accurate — `scripts/dev-cycle.sh:58-59`, `skills/dev-cycle/SKILL.md:292-294` and c8435580's Notes say a working-tree-only answer reads `open`, but an entry absent from main reads `skip … no such entry` (both fail closed); claim 16 Mostly accurate — the tests cover T34 (no "both scripts" / E2 `--marker` part) and T31 (no SKILL-template brief) only in part.

---

## 🟢 Consider

None collected this pass (short-circuit).

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u0c` / 2026-10-05 (row 206) | check_answer reads questions.md from the working tree (F28) | 🟢 → Defer to U1 | U1 moves it to main's commit (D8, T34) | Discharged by this diff (fact-check claims 1a, 7, 12 Verified). |
| `feat/build-loop-u0c` / 2026-10-05 (row 216) | check_answer print-only; U1 should accept only a positive line and add main_by_name | 🟢 → Defer to U1 | Header names the safe capture pattern | Lib part discharged (main_by_name added, claim 6 Verified); the capture side is U1b's caller. |
| `feat/build-loop-u0c` / 2026-10-05 (row 217) | check_answer appends to SKIPPED; check_brief does not | 🟢 → Defer to U1 | U1 rewrites check_answer | Discharged (claim 12 Verified by probe); see A4 for the test that does not prove it. |
| `feat/build-loop-u0a` / 2026-10-05 (row 197) | Lib header lacks the both-suites note | 🟢 → Defer to U1 | U1 adds build-loop-read.bats and the note with it | Departs in fact: the note landed in U1a before the suite exists (U1b) — fact-check claim 4, not tiered this pass. |
| `feat/build-loop-u0a` / 2026-10-05 (row 196) | A test should source the lib from build-loop.sh's side | 🟢 → Defer to U1 | U1's test unit | Not applicable to U1a; still U1b's. |
| `feat/build-loop-u0b` / 2026-10-05 (row 201) | check_brief's `git log -G` walk grows per brief | 🟢 → Defer to U1 | Measure in U1's `--status` | Inherited; A3 adds main_entry's ls-tree cost to the same U1b measurement. |
| `feat/build-loop-u0b` / 2026-10-05 (row 208) | main_by_name passes for a MAIN_SHA from another repo | 🟢 → Won't-Fix | No two-repo caller | Inherited; A2 is a different failure (ls-tree error → absent). |
| `feat/build-loop-u0b` / 2026-10-05 (rows 213, 215) | check_brief's need_root fork; three guard channels / U3 must check main_by_name | 🟢 → Won't-Fix / Defer | Small cost; recorded for U3 | Inherited, not re-raised. |

---

## ✅ Confirmed Good

None this pass (✅ rows are terminal-pass output; Stage 2.5 skipped on a loop pass).

---

## ⚠️ Unverified Findings

All findings' evidence resolved.

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| security-reviewer | loop-pass short-circuit (behavioral red confirmed) | fact-check claim 11a Incorrect (high, executed) |
| performance-reviewer | loop-pass short-circuit (behavioral red confirmed) | same |
| api-consistency-reviewer | loop-pass short-circuit (behavioral red confirmed) | same |
| architecture-review (auto-selected: new lib functions main_entry, brief_fields and globals BRIEF/BRIEF_ODD) | loop-pass short-circuit (behavioral red confirmed) | same |

---

## 🧩 Composition check

No multi-source co-located clusters qualified (only the fact-check reported this pass).

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry a qualifying author note (a discoverable TODO or a concrete revisit trigger; see
"Qualifying author note" in `skills/code-review/references/rubric.md`). 🟢 items are optional.
