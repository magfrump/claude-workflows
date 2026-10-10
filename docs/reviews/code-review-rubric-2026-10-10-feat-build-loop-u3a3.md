Commit: a7a4f784

# Code Review Rubric

**Scope:** feat/build-loop-u3a3 vs main (full branch; iteration 1, --loop-pass, k=1 fact-check, delivery mode self-read) | **Reviewed:** 2026-10-10 | **Status: 🔴 DOES NOT PASS** at a7a4f784 — 1 red item (fixed in the iteration-1 fix commit; re-review pending)

Panel: code-fact-check (k=1, opus), security-reviewer, performance-reviewer, api-consistency-reviewer, architecture-review (auto-selected: lib contract change). Not triggered: test-strategy (tests changed with source), tech-debt-triage, dependency-upgrade, ui-visual-review. No short-circuit (no behavioral red at fact-check).

---

## 🔴 Must Fix

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| R1 | GATE_CODE omits `skills/dev-cycle/`, which plan D4 (line 61) and F52 name as gate files needing a `merge-gate-` slug; under `--approved` only the N rules run, so a change to the skill that carries the D6 snippet landed under a plain `merge-` slug | Security / API contract | Medium (security) + Inconsistent (api) | security-reviewer M2, api-consistency F1 (converging) | `scripts/lib/dev-cycle-read.sh:1915` | for-author | — | Fixed (iteration-1 fix commit: GATE_CODE gains `^skills/dev-cycle/`; T35 case added) |

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | The approval heading pins only TIP's first 12 hex digits (48 bits); only `--expect` binds the full tip, so a caller passing the branch's live tip could land a ground prefix-collision commit | Security | Medium (Low confidence) | security-reviewer M1 | for-author | — | Acknowledged | Header now states the caller passes the full TIP it filed the entry for. Override row; revisit trigger: U4's entry writer (record the full TIP in the entry and pass it as --expect, or have approval() compare it). |
| A2 | Lib header's capture rule (`out="$(check_answer ...)"`) contradicts the new ANSWER_HEAD side value | Architecture | Minor (High confidence) | architecture-review F2 | for-author | — | Fixed | Header sentence added; renamed ANSWER_HEADING (C3). |
| A3 | Authority travels two ways: land's message keyed on `$1 == approved`, its trailer on `$2` non-empty | Architecture | Minor | architecture-review F3 | for-author | row 653 | Fixed | Trailer keyed on `$1 == approved`. |

---

## 🟢 Consider

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | `--check` never prints the expected heading or the gate bit; the U4 filer must re-derive the slug rule | architecture F1, api F2 | Minor | for-author | — | Deferred (row; trigger U4) |
| C2 | Catch-all refusal "not option 1" hides drop/done/unrecognized; "Q-NNN: merge" refused misleadingly | api F3 | Minor | for-author | — | Fixed (option 2 / option 3 / not read as an option) |
| C3 | ANSWER_HEAD uses HEAD for a questions heading | api F6 | Minor | for-author | — | Fixed (ANSWER_HEADING) |
| C4 | Floor comment "gate ... which a caller can test" suggests FLOOR_WHY == gate can stand in for "touches gate code" | architecture F4 | Informational | for-author | row 472 | Fixed (comment reworded) |
| C5 | Four comment/commit wordings: --merge opening line; land's "Decide" list; walk_why's comment; a7a4f784's "both walks" | code-fact-check 1, 11, 15, 23 | Mostly accurate | for-author | — | Fixed (1, 11, 15); 23 is in an unmerged commit body, corrected in the merge message |
| C6 | srules forks $(floor_why) per floor-denied path; two forks per path after a cached walk failure (~+160 ms at 400 refused paths) | performance F1 | Low | for-author | — | Deferred (row) |
| C7 | `$(cat FILE)` in approval | performance F2 | Informational | for-author | — | Fixed (`$(< FILE)`) |
| C8 | Two refusal phrasings ("does not approve this merge" / "approves no merge of this tip") | api F4 | Informational | for-author | — | Won't-Fix (row) |
| C9 | `--approved` usage error combines count and format | api F5 | Informational | for-author | — | Won't-Fix (row) |
| C10 | TRUTH_WHERE's suffix and sentence value vs TRUTH_WHY's word | api F7, architecture F6 | Informational | for-orchestrator-synthesis | rows 630, 634 | Won't-Fix (row) |
| C11 | Plan D4 vs D5 gate lists disagree on skills/dev-cycle/ | architecture F5 | Informational | for-author | — | Fixed in code (R1); plan D5 note at merge |
| C12 | Contract items 3 and 5 say "policies", not "authorities" | architecture F7 | Informational | for-author | — | Won't-Fix (row: --approved calls neither floor nor the walks) |
| C13 | A plain merge- approval lands floor-protected paths with no warning on the entry | security 3 | Informational | for-author | — | Deferred (row; trigger U4's entry body lists them with floor_why reasons) |

---

## ↩️ Considered Overrides

| Override (PR ref / Date) | Prior finding | Original → Override | Reason | This run's treatment |
|---|---|---|---|---|
| `feat/build-loop-u1a` / 2026-10-05 (row 221) | T34's build-loop side missing | 🟢 → Defer | trigger U3's T35 | Discharged: T35 tests land here; the answer read is --approved's |
| `feat/build-loop-u2a4` / 2026-10-07 (row 472) | FLOOR_WHY a finished sentence | 🟢 → Defer | trigger U2c/U3 | Discharged: floor words + floor_why |
| `feat/build-loop-u2c2` / 2026-10-10 (rows 630, 634) | TRUTH_WHERE for both walks; reader sentence twice | 🟢 → Defer | trigger U3 | Discharged; tree walk words only readers (row) |
| `feat/build-loop-u3a2` / 2026-10-10 (rows 653, 661, 664) | one authority value; stale refusal; CHANGED placement | 🟢 → Defer / Won't-Fix | trigger U3a3 | Discharged (AUTH; refusal reworded) |
| rows 215, 216 | main_by_name; check_answer accepts only a positive line | Defer | trigger U3 | Inherited: gate_start's top-level guard; approval accepts only `keep Q-NNN` |
| row 524 | wrong cause when git warns | Won't-Fix | fails closed | Inherited — not re-flagged |
| Q-103 residuals (Q-138 [1]) | planted git state | routed | — | Inherited — no new shape found |

---

## ✅ Confirmed Good

Endorsements routed `route: code-fact-check` by security (same MAIN_SHA for answer and landing; questions files N-denied; no empty-DENY path in floor_why; `sm` unchanged for --check and self-merge) are pending execution verification (Stage 2.5 runs on the terminal pass).

---

## 🧩 Composition check

| Cluster | Fragments | Disposition |
|---|---|---|
| `scripts/lib/dev-cycle-read.sh:1915` / plan:61 | security M2, api F1, architecture F5 | distinct defects: each fragment states the same mechanism and fix completely (R1) |
| `scripts/build-loop.sh:1066-1090` | security M1, architecture F1, api F2/F3/F4 | distinct defects: prefix length, slug visibility and refusal wording are separate concerns |

---

## ⏭️ Skipped Core Critics

None.
