# Code Review Rubric

**Scope:** `git diff main...HEAD` (10 files, +207/−7; commits `8c23b7e` + `fbd8597`) | **Reviewed:** 2026-07-31 | **Status: 🟡 CONDITIONAL PASS** — 0 red open; all fixes applied in iteration 1, awaiting iteration-2 re-review

**Commit:** fbd8597 · Review-fix loop iteration 1 · `-r2` suffix distinguishes this loop from the earlier 2026-07-31 loop on this branch's pre-merge diff (that rubric is preserved unmodified).

---

## 🔴 Must Fix

Issues that must be resolved before merge. Draft cannot pass review with any red items
unresolved.

| # | Finding | Domain | Severity | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|
| R1 | Partial-scope rule's warrant: "all four model families **unanimously** flag work as missing … while *raising* agreement on real issues" — actual: 3/4 families, 6/11 replicates; agreement fell on D4; result misattributed to the 2026-07-31 experiment (it is the 2026-07-30 baseline). Convergence: fact-check (k=3, most-severe Incorrect) + api-consistency #9. | Fact-check | Incorrect (High) | `skills/code-review/SKILL.md:101` | for-author | — | ✅ Fixed (iter 1) |
| R2 | Experiment doc baseline overstatement: "all four families … flagged Tier A/B work as missing" and "was 8/8-family" — baseline is 11 replicates, 6 filed the FP, Sol 0/3. Unanimous 3/3 replicate agreement. | Fact-check | Incorrect (High) | `docs/working/experiment-stage1-fp-kill-2026-07-31.md:39-43` | for-author | — | ✅ Fixed (iter 1) |
| R3 | bwrap `--tmpfs /tmp`/`--chdir` finding called "**new** cross-family consensus" in both the experiment doc and the state doc — it was already a 4-family finding in the diff-only baseline (8/12 replicates); the "consensus under enriched context is now evidence" inference rests on novelty that isn't there. Also "all 4 families, Medium": Sonnet's instance is Low. | Fact-check | Incorrect (High) | `docs/working/experiment-stage1-fp-kill-2026-07-31.md:69-76`, `docs/thoughts/code-review-evaluation-state.md:289-290` | for-author | — | ✅ Fixed (iter 1) |
| R4 | "Recurrent cluster (3 families)" for branch-tip fix detection — 2 families (Kimi, Sol; 4/8 replicates); 3 is the baseline count, likely transposed. Unanimous 3/3. | Fact-check | Incorrect (High) | `docs/working/experiment-stage1-fp-kill-2026-07-31.md:56-58` | for-author | — | ✅ Fixed (iter 1) |

---

## 🟡 Must Address

Issues that must be fixed or acknowledged by the author with justification for why they
stand. Each must carry a resolution or author note.

| # | Finding | Domain | Severity | Source | Legibility-target | Considered overrides | Status | Author note |
|---|---|---|---|---|---|---|---|---|
| A1 | Raw-data line lists `prompt.txt` but both files are untracked (commit `8c23b7e` states the findings+overlap convention) | Fact-check | Stale (High) | Fact-check Claim 6 | for-author | — | ✅ Fixed (iter 1) | — |
| A2 | 021 status line keeps "worst call $0.248 … both guardrails hold" without noting the actual worst call ($0.388) overshot the projection by 56%; $4.37 vs $3.53 are different cell-sets | Fact-check | Mostly accurate (High) | Fact-check Claim 7 | for-author | — | ✅ Fixed (iter 1) | — |
| A3 | "on the same four families that produced them diff-only" — Result 3c came from one Gemini replicate (log row 30 + experiment Answer line) | Fact-check | Mostly accurate (High) | Fact-check Claim 8 | for-author | — | ✅ Fixed (iter 1) | — |
| A4 | Unqualified "agreement rose" framing in 4 places (log row 30, state doc, experiment Result C "most pairs ≈0", harness docstring) — the D3 change is a redistribution (Sonnet pairs up, Kimi pairs and baseline max down); D4 fell | Fact-check | Mostly accurate (High) | Fact-check Claims 9-11 | for-author | — | ✅ Fixed (iter 1) | — |
| A5 | Smaller precision defects: D3 sibling section is 7 commits not "rounds 1–5" alone; "72 KB" is chars÷1024 (file is 74,876 B); "all anchored to real constructs" holds only in its verifiable form | Fact-check | Mostly accurate (High/Med) | Fact-check Claims 12-14 | for-author | — | ✅ Fixed (iter 1) | — |
| A6 | Recommending `--context-base` retires the opt-in premise prior finding A12's deferral rested on, with no mitigation adjustment: `prompt.txt` snapshots (80/49 KB) sit untracked **and unignored** next to committed siblings — one `git add runs/` from a whole-repo (or foreign-repo, via `--repo`) snapshot in history. Fix: ignore `runs/**/prompt.txt` + an out-dir placement sentence in the WARNING block | Security | Medium | Security #1 | for-author | Prior A12 author-note (inherited context; this finding is the delta the recommendation shift creates, not a re-flag) | ✅ Fixed (iter 1) | — |
| A7 | No aggregate cap on inlined enclosing files: `--max-inline-kb` caps per-file, nothing caps the sum; prompt grows linearly in touched files (50 files ≈ 3.2 MB) with only the dollar-denominated `--max-usd` abort as backstop — a cliff the new "recommended" posture makes the default exposure | Performance | Medium (Macro × Cold) | Performance F1 | for-author | — | ✅ Fixed (iter 1) | — |
| A8 | Partial-scope labelling rule lives only in Step-1 prose; neither the Stage-1 replicate checklist nor the Stage-2 critic-dispatch checklist mentions it (decision-29 precedent: requirements consumed at dispatch go into the numbered dispatch steps); ambiguous whether fact-check replicates are covered | API consistency | Inconsistent | API #1 | for-author | — | ✅ Fixed (iter 1) | — |
| A9 | Decision-log row 30's Full Record cell links `[021]` — every other linked row self-links its own record number; row 30 has no full record of its own, so the cell should be `—` (021 is already cited in the row text) | API consistency | Inconsistent | API #2 | for-author | — | ✅ Fixed (iter 1) | — |

---

## 🟢 Consider

Advisory findings from contextual critics, single-critic suggestions, and improvement
opportunities. Not required to pass review.

| # | Finding | Source | Severity | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|
| C1 | SKILL.md's "context only, not under review" label is an unauthenticated trust boundary on the agentic path (no nonce equivalent); the "check siblings before flagging missing work" clause could suppress a deleted-control finding — one-clause scope fix available | security-reviewer | Low | for-author | — | ✅ Fixed (iter 1: provenance-not-trust clause added) |
| C2 | Judge-stage prompt splices untrusted model text undelimited and verdicts on a `"YES" in upper()` check (pre-existing; the cited Jaccard figures flow through it) | security-reviewer | Informational | for-orchestrator-synthesis | — | Deferred (experiment-doc follow-up 4) |
| C3 | Committed `findings.jsonl` scanned for credential shapes — none; disclosure delta nil | security-reviewer | Informational | for-orchestrator-synthesis | — | Won't-Fix (observation; no action) |
| C4 | Cost-guard's flat 1,500-output-token term under-projects reasoning models (worst $0.388 vs $0.248 projected); margin still wide vs $10 trigger | performance-reviewer | Low | for-author | — | ✅ Fixed (overshoot now flagged in 021 status line) |
| C5 | Sweep loop strictly sequential (~37 min worst case vs ~11 min parallel); deliberate — ordering, crash-resilience, rate-limit safety | performance-reviewer | Informational | for-orchestrator-synthesis | — | Won't-Fix (deliberate design) |
| C6 | Per-file `git show` subprocesses amortized once across all calls — correct placement | performance-reviewer | Informational | for-orchestrator-synthesis | — | Won't-Fix (positive observation) |
| C7 | New WARNING goes to stderr while the script's other WARNING (`:497`) and sibling `dd-cross-model-sweep.py` warn on stdout — stderr is the better choice; align `:497` | api-consistency-reviewer | Minor | for-author | — | ✅ Fixed (iter 1: :516 warning → stderr) |
| C8 | `--context-base` per-flag help still reads "Omit for the historical diff-only prompt" vs the docstring's RECOMMENDED (also test-strategy G8) | api-consistency-reviewer | Minor | for-author | — | ✅ Fixed (iter 1: --help updated) |
| C9 | Partial-scope rule enumerates `--range`/`--staged`/`--files` but drops `--pr` from the override list two lines above | api-consistency-reviewer | Minor | for-author | — | ✅ Fixed (iter 1: --pr added) |
| C10 | No test asserts the warning; bats test 8 exercises that path and passes only because bats merges stderr into `$output` — the stderr-only property is unverified (converges with test-strategy G1–G4) | api-consistency-reviewer + test-strategy | Minor | for-author | — | ✅ Fixed (iter 1: bats tests 8–10) |
| C11 | Warning fires before the unpriced/`--max-usd` guards, so a refused run still warns (freezing it in a test would pin a wart — G5) | api-consistency-reviewer + test-strategy | Informational | for-orchestrator-synthesis | — | Deferred (freezing would pin the wart) |
| C12 | Test-strategy plan: gaps G1–G8; top value = ~15-line bats addition covering warning fires-live/silent-dry-run/silent-context-base/stderr-only (G1–G4); G6 = labelling rule has zero enforcement; G7 = backticked doc path not covered by cross-reference-integrity checks | test-strategy | Advisory | for-author | — | ✅ Fixed (iter 1: G1–G4 tests, G6 via A8, G8 via C8; G7 deferred) |

---

## ↩️ Considered Overrides

Rows lifted from `docs/reviews/override-log.md` that matched the current diff per the
Step 3.5 scan.

No prior overrides matched this diff. (The log's single row — the 2026-06-23 UserPromptSubmit-hook Won't-Fix — matches neither location, category, nor substance.)

---

## ✅ Confirmed Good

Patterns, implementations, or claims confirmed correct by fact-check and/or critics.

| Item | Verdict | Source | Legibility-target |
|---|---|---|---|
| Diff-only prompt byte-identity: dry-run sha `968d268b1689` matches all historical rows; bats 8/8 incl. sha-stability test; warning post-`prompt_sha`, stderr-only, unreachable in `--dry-run` | ✅ Confirmed | Fact-check (3/3 replicates re-executed) + security + api | for-orchestrator-synthesis |
| 0/8 FP-kill core result: no Result-3c or Result-5 class finding in any of the 38 Stage-1 findings (read finding-by-finding by all 3 replicates) | ✅ Confirmed | Fact-check Claims 15, 17-21 | for-orchestrator-synthesis |
| All cost/latency/SHA/git-identity numbers recomputed from artifacts — exact | ✅ Confirmed | Fact-check Claims 16, 19, 20 | for-orchestrator-synthesis |
| A11 nonce delimiter hardening byte-for-byte untouched; API key never logged/serialized/inherited; argv-exec throughout; cost guard fails closed on unpriced models | ✅ Confirmed | Security | for-orchestrator-synthesis |
| Prompt built once and reused across model×replicate calls; additive `context_base`/`abstain` fields read via `.get()`; `s1-*` dirs reuse `gt-`/`fast-` SHAs so arms stay comparable | ✅ Confirmed | Performance + api | for-orchestrator-synthesis |

---

## ⚠️ Unverified Findings

All findings' evidence resolved. (Orchestrator spot-checks: row-30 `[021]` link and the `—` convention on unlinked rows; `?? runs/cross-model/s1-*/prompt.txt` with no ignore rule; `--context-base` help text at `scripts/cross-model-review.py:356` — all reproduce.)

---

## ⏭️ Skipped Core Critics

All core critics ran; no skips applied.

---

To pass review: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
