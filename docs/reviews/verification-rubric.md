# Draft Verification Rubric

**Draft:** SWR-Bench Multi-Dimensional Judge & Audit System (v2.0) (`docs/gemini-SWRench.md`) | **Checked:** 2026-08-03 | **Status: ✅ PASSES VERIFICATION** (fixes applied 2026-08-03; re-run the pipeline on the revised draft to independently confirm)

Reviewed by: fact-check + cowen-critique + yglesias-critique + ai-personas-critique (draft-review orchestrator).

---

## 🔴 Must Fix

Factual errors identified by fact-check. Draft cannot pass verification with any red items
unresolved.

| # | Claim in draft | Issue | Confidence | Status |
|---|---|---|---|---|
| R1 | "The judge environment uses multi-version static analysis parsers (`libCST`, `Ruff`, `Mypy` in AST mode) to verify variable declarations, import paths, and syntax structures statically." | The named toolchain cannot do this for the draft's own target: libCST parses Python 3.0–3.14 only, Ruff is Python-3-only, "Mypy in AST mode" is not a real mypy mode, and mypy dropped Python 2 support in 2022 — but the dataset verifiably contains 64 PRs from 2011–2012 (Python 2.6/2.7 era). §4 needs a different toolchain or an explicit scope carve-out for legacy code. (Fact-check C8.) | Medium | ✅ Fixed — §4 rewritten: textual quote/line verification is the universal baseline; Python-3 `ast`/libCST parse enrichment is best-effort with a `parse_fallback` flag for legacy files; Ruff and "Mypy in AST mode" removed |

---

## 🟡 Must Address

Imprecise/unverified claims, plus structural issues flagged by multiple critics (high-signal).
Each must be fixed or acknowledged by author with a note explaining why it stands.

| # | Item | Type | Confidence | Status | Author note |
|---|---|---|---|---|---|
| A1 | "findings … not explicitly requested by historical human reviewers are labeled as False Positives" — the original judge matches *semantically* (LLM judge) and already severity-grades potential FPs 1–10; "explicitly" overstates the strictness (fact-check C2) | Imprecise claim | High | ✅ Fixed | §1 rewritten to describe semantic LLM-judge matching and the existing 1–10 FP severity grade |
| A2 | "Spot-checking … reveals … penalizes high-quality, valid findings" — spot-checks documented the FP-scoring *mechanism*, but the repo's own adapter doc treats whether those findings are valid as an open question the judge run was meant to answer; the spec asserts it as settled (fact-check C3) | Imprecise claim | Medium | ✅ Fixed | §1 now says spot-checking "suggests"; validity framed as the open question the update measures |
| A3 | "single-dimensional precision matching scheme" — the original has PR-level and point-level P/R/F1 plus FP severity grading; only the per-point matching decision is binary (fact-check C4) | Imprecise claim | Medium | ✅ Fixed | Rephrased to "binary per-point matching decision"; v2 "supplements" rather than "transitions from" |
| A4 | WUS has no recall term: it normalizes only by predictions made, so missed blocking bugs cost nothing — a tool emitting one confident TP scores a perfect 1.0. Gameable by abstention; silently discards the old F1's precision–recall coupling and inverts the benchmark's purpose | All 3 critics | — | ✅ Fixed | §1 + §2.2 + §7.2: WUS declared precision-side only, MUST be reported alongside legacy P/R/F1, never standalone |
| A5 | VU (+0.8) is awarded solely by the judge's own unvalidated Stage-1 fact-check, with no ground truth, no calibration set, no judge-agreement measurement, and no v1-vs-v2 comparison in §7 acceptance criteria — score improvements under v2 are indistinguishable from judge leniency | All 3 critics | — | ✅ Fixed | §2.2 marks weights provisional; §7.3 adds calibration criterion (≥100 human-adjudicated findings, Cohen's κ, weight refit, v1-vs-v2 comparison) |
| A6 | Severity-before-attestation ordering: a finding a human reviewer actually raised, if low-severity, routes to NB and scores −0.1 — penalizing agreement with the benchmark's own gold standard, against §1's stated motivation (fact-check C7 flag + all 3 critics) | All 3 critics + fact-check | — | ✅ Fixed | Stages 3/4 swapped throughout (§2.1 table, §3 diagram + rationale, §5.1 prompt, §5.2 JSON order); TP now covers attested findings at any severity |
| A7 | §3's "sequential multi-stage decision pipeline" is implemented in §5.2 as a single structured-output API call — the stated anti-drift mechanism contradicts the revealed architecture; decide whether stage isolation is a real requirement | 2 critics (cowen, ai-personas) | — | ✅ Fixed | §3 now states the reference implementation is a single ordered structured-output call; ordering + short-circuit routing are normative, call topology is not |
| A8 | Audit artifact paths (`audit_reports/{owner}_{repo}/pr_{n}.md`) carry no run ID or tool ID — multi-tool or repeat runs overwrite each other, and there is no run-level index | 2 critics (yglesias, ai-personas) | — | ✅ Fixed | §6.1 paths now `{run_id}/{acr_tool}/…` plus a run-level `index.md`; report header carries tool/run/judge-pin |
| A9 | Mechanical spec defects: §3 ASCII diagram garbled in the Stage 3/4 region; §5.2 user-prompt template's literal `{`/`}` JSON braces collide with its `{placeholder}` substitution syntax | Fact-check note + ai-personas | — | ✅ Fixed | Diagram redrawn cleanly (with new stage order); §5 template-syntax note distinguishes placeholders from literal JSON braces |

---

## 🟢 Consider

Ideas from one critic or tensions between critics. Not required to pass. For the author's
consideration only.

| # | Idea | Source |
|---|---|---|
| C1 | Adopt §6 audit artifacts and the §4 no-dynamic-execution constraint regardless of the scoring decision — both are severable and good | cowen-critique — *adopted (retained in revision)* |
| C2 | "Popular version": ship v2.0 as an analysis layer *over* the stock judge, always reporting both WUS and the original P/R/F1, preserving comparability with published tables | yglesias-critique — *adopted (§1 metric-coexistence clause, §7.2)* |
| C3 | Calibrate weights empirically instead of asserting them: the stock judge already severity-grades every potential FP 1–10; re-analyze existing output and hand-adjudicate the ~120 deduped findings from the 30-PR sample, then fit VU/NB weights to human labels | cowen-critique + yglesias-critique — *adopted (§7.3)* |
| C4 | Add a human-override field to audit reports so routine spot-checks accumulate into a calibration set; add a run-level index page | ai-personas-critique — *adopted (§6.2 Human Audit Override, §6.1 index)* |
| C5 | The spec contradicts two prior repo decisions — the tracker's "keep valid/invalid verdicts human; LLM does matching only" and the adapter doc's pinned-judge comparability discipline. Write a decision record (`docs/decisions/`) before implementing | yglesias-critique (escalated) — *partially adopted: §7 adoption note requires the decision record; the record itself is still to be written* |
| C6 | The 60-second spot-check acceptance criterion (§7.4) is untested on decade-old code; pilot it on a handful of 2011–2012 PRs | ai-personas-critique — *adopted (§7.6 pilot requirement)* |

---

## Verified ✅

Claims confirmed accurate by the fact-check. No action needed.

| Claim | Verdict | Confidence |
|---|---|---|
| "SWR-Bench evaluates Automated Code Review (ACR) tools against historical Pull Request (PR) data" | ✅ Accurate | High |
| "Instead of traditional F1/Precision scores" (original benchmark scores with P/R/F1) | ✅ Accurate | High |
| WUS weights in §2.2 match the §5.2 JSON `utility_weight` enum exactly; formula well-formed, bounded [−1, +1] | ✅ Accurate | High |
| §3 decision-flow routing is consistent with the §2.1 category definitions | ✅ Accurate | High |
| Historical codebases include "Python 2.6/2.7 dependencies from 2012" (64 dataset PRs from 2011–2012) | ✅ Accurate | Medium |
| §7's "5 discrete category buckets" match §2.1 and the §5.2 `final_category` enum | ✅ Accurate | High |

---

To pass verification: all 🔴 items must be resolved. All 🟡 items must be either fixed or
carry an author note. 🟢 items are optional.
