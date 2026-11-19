Commit: 3d8cabb3

# Code Review Rubric

**Scope:** `--files` runs/review-arms/a8-2026-11-19/{results.md,token-ledger.md,manifest.json}, docs/working/research-2026-11-19-a8-token-measurement.md on `measure/a8-token-measurement` | **Reviewed:** 2026-11-19 | **Status: 🟡 CONDITIONAL PASS** — 0 red; pass 1 (k=3, 123432af) ambers A1-A13 fixed in 3d8cabb3; pass 2 (k=1 loop pass over that delta, 3d8cabb3) ambers A14-A18 fixed in the next commit, awaiting re-review

Scope note: the rest of the branch (`runs/review-arms/a8-2026-11-19/csp/`) is the measured pass's own review output, written by its sub-agents: context, not under review. Delivery mode: self-read (deviation: the four files are ~26 KB, within budget, but I passed paths, not inlined text). Override log: no prior overrides matched this diff (`docs/reviews/override-log.md` read; no row touches these paths).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Domain | Severity | Source | Location | Legibility-target | Considered overrides | Status |
|---|---|---|---|---|---|---|---|---|
| A1 | "Two findings are new": prefetch = canon N1, worker-src = canon N7 (refuted) | Fact-check | Incorrect high, doc | fact-check Claim 2 | `results.md:98-100` | for-author | — | ✅ Fixed |
| A2 | "at most 3 points" and the verdict's net-cost clause | Fact-check | Incorrect high, doc | fact-check Claim 3 | `results.md:104-114` | for-author | — | ✅ Fixed |
| A3 | 23.4k → 21.2k block total | Fact-check | Incorrect, doc | fact-check Claim 7 | `results.md:46-47` | for-author | — | ✅ Fixed |
| A4 | SKILL.md last changed in 44724747, not 82accdd7 | Fact-check | Mostly accurate | Claim 4 | research `:24`, `manifest.json:4`, `results.md:16` | for-author | — | ✅ Fixed |
| A5 | field is `subagent_tokens` | Fact-check | Mostly accurate | Claim 5 | research `:40`, ledger `:3` | for-author | — | ✅ Fixed |
| A6 | skill texts 14.5-34 KB; ~250 KB over 9 prompts | Fact-check | Mostly accurate | Claim 6 | research `:55,74` | for-author | — | ✅ Fixed |
| A7 | ~97k is +27% of 359k; +26% is a different comparison | Fact-check | Mostly accurate | Claim 8 | `results.md:40-42` | for-author | — | ✅ Fixed |
| A8 | residual 7.4k-19.9k per critic | Fact-check | Mostly accurate | Claim 9 | `results.md:48-49` | for-author | — | ✅ Fixed |
| A9 | "never served from cache" → across agents; breakpoints recorded; timing does not explain | Fact-check | Mostly accurate | Claims 10, 16 | `results.md:62-70`, research `:95`, `manifest.json:46` | for-author | — | ✅ Fixed |
| A10 | brief's two lines point toward the R1/A1 routes | Fact-check | Mostly accurate | Claim 11 | `results.md:90-93` | for-author | — | ✅ Fixed |
| A11 | per-agent growth +15% to +40% | Fact-check | Mostly accurate | Claim 12 | `results.md:110` | for-author | — | ✅ Fixed |
| A12 | 2,189 is bytes/4 | Fact-check | Mostly accurate | Claim 13 | ledger `:5` | for-author | — | ✅ Fixed |
| A14 | "Timing does not explain it" leaned on r3's later return; the first requests left together, so only Stage 2.5 separates timing | Fact-check | Incorrect, doc | pass 2 Claim 13a | `results.md:74-75` | for-author | — | ✅ Fixed |
| A15 | 82accdd7 "touched only references/rubric.md" true only inside skills/code-review/ | Fact-check | Mostly accurate | pass 2 Claim 1 | research `:24`, `manifest.json:4`, `results.md:16-17` | for-author | — | ✅ Fixed |
| A16 | "cacheable first part of every prompt" — harness context precedes it and no breakpoint ends at it | Fact-check | Mostly accurate | pass 2 Claim 4 | research `:57-59` | for-author | — | ✅ Fixed |
| A17 | N7 is refuted but its demotion is pending; only A4's worker half is not creditable | Fact-check | Mostly accurate | pass 2 Claim 7 | `results.md:111-114`, csp rubric `:28` | for-author | — | ✅ Fixed |
| A18 | "from its second call on" has exceptions after long gaps | Fact-check | Mostly accurate | pass 2 Claim 12 | `results.md:67-69`, ledger `:26-27` | for-author | — | ✅ Fixed |
| A13 | tool_uses off by one vs transcripts; r2 header vs body; ~30k remainder; "no transcripts" | Fact-check | Mostly accurate / Unverifiable | Claims 14, 15 | ledger, `results.md:50-52` | for-author | — | ✅ Fixed (disclosed in results §5 and §1) |

---

## 🟢 Consider

| # | Finding | Source |
|---|---|---|
| C1 | Rubric A4 of the measured pass (worker half) repeats canon N7, a known false positive; annotated there | fact-check escalation |

---

## ✅ Confirmed Good

| # | Claim | Backing |
|---|---|---|
| G1 | Every token figure, sum and ratio, the instrument identity, the first-call cache figures, the prompt hashes and the label table recompute from primary records | fact-check Claim 1, 3/3 Verified (static recomputation over notifications, transcripts, git and the canon ledger) |

---

## ⏭️ Skipped Core Critics

| Critic | Reason | Signal |
|---|---|---|
| security-reviewer | copy-only diff: markdown and one JSON data file, no code, no string literal in an HTML/SQL/shell/regex/auth/URL context | `git diff --stat main...HEAD`: only `.md`, `.json`, `.log`, `.html`, `.txt` and one `.tsx` copy under `fc-r3-logs/` (captured probe output, not shipped code) |
| performance-reviewer | copy-only diff; the fact-check findings about caching describe a measurement of the review pipeline, not code on a hot path | as above |
| api-consistency-reviewer | no public surface: no exported symbol, schema, route, flag or published config key | as above |

Contextual critics: none selected (no source files, no manifests, no UI code).

---

## 🧩 Composition check

No multi-source co-located clusters qualified (fact-check was the only source).
