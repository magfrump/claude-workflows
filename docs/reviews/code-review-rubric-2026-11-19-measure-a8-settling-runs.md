Commit: 1faef93b

# Code Review Rubric

**Scope:** `--files` runs/review-arms/a8-2026-11-20/{results.md,token-ledger.md,manifest.json,csp/code-review-rubric-2026-11-19-csp.md,corpus/code-review-rubric-2026-11-19-corpus.md,csp/code-fact-check-report.md,corpus/code-fact-check-report.md}, docs/working/research-2026-11-19-a8-settling-runs.md on `measure/a8-settling-runs` | **Reviewed:** 2026-11-19/20 | **Status: ✅ PASSES** — 0 red, 0 open amber; pass 1 (k=3, 1431b628) ambers A1-A14 fixed in 791ca9d7; pass 2 (k=1, 791ca9d7) 0 Incorrect, all pass-1 findings resolved, ambers A15-A17 fixed in 1faef93b; lite fix-drift on both fix commits: no findings. Single-sample review; absence of findings is not an attestation.

Scope note: the rest of the branch (the agent reports, logs and shared blocks under `runs/review-arms/a8-2026-11-20/csp/` and `corpus/`) is the measured passes' own output: context, not under review. Gated critics (security, performance, api-consistency) skipped at Stage 1.5: the diff is copy-only (docs and run records, no code). Delivery mode: self-read. Override log: no prior overrides matched this diff (`docs/reviews/override-log.md` read; no row touches these paths).

---

## 🔴 Must Fix

None.

---

## 🟡 Must Address

| # | Finding | Severity | Source | Location | Status |
|---|---|---|---|---|---|
| A1 | N23, D4, D5 listed as rows "the baseline did not have"; the baseline had all three | Incorrect | pass 1 r1, r2, r3 | `results.md:112-116` | ✅ Fixed |
| A2 | Stage 2.5 "6V (4 executed)": 3 of 6 V executed, 5 entries in all | Incorrect | r1, r2 | `token-ledger.md:24` | ✅ Fixed |
| A3 | "the inline block's ~2.2k-2.9k left the prompt": only the diff and files left | Incorrect | r3 | `results.md:42-43` | ✅ Fixed |
| A4 | Merged reports' attention sections listed only Stage 2.5 rows / "None" | Incorrect | r3 | both merged reports | ✅ Fixed (restored complete) |
| A5 | Corpus Claim 12 "r1=—, single-replicate": r1 Claim 6c Verified it; agreement 21/25 | Incorrect | r1, r2, r3 | `corpus/code-fact-check-report.md:188,710` | ✅ Fixed |
| A6 | Corpus merge "one row per distinct assertion": five single-replicate Verified have no row | Incorrect / MA | r1, r2 | corpus report `:13`, `results.md:143-145` | ✅ Fixed |
| A7 | "a third to three quarters" of critic growth: 35%-78% | MA | r1, r2, r3 | `results.md:89` | ✅ Fixed |
| A8 | cor-A1/cor-A2 baseline column | MA | r2, r3 | `results.md:102-103` | ✅ Fixed |
| A9 | "Stage 2.5's 7 and 8 entries" swapped | MA | r1, r2, r3 | `results.md:145` | ✅ Fixed |
| A10 | "Stage 2.5 ran 4 claims on next dev": 5 entries over 4 runs | MA | r1, r2 | `results.md:57-58` | ✅ Fixed |
| A11 | "Claims 3, 4 (executed 3/3)": only Claim 3 | MA | r2 | corpus rubric `:18`, `results.md:105` | ✅ Fixed |
| A12 | "one tool call, a few hundred tokens": two Reads per critic, line numbers ≈1.4k | MA | r1 | research doc, `results.md:93-95` | ✅ Fixed |
| A13 | 17.4k counts "diff + fact-check summary": it is the report; "budget did its job" overstates | MA | r1 | `results.md:71,128` | ✅ Fixed |
| A14 | Precondition wording: the brief asks for a literal check and a blocked stop | MA | r2 (r1, r3 escalate) | research doc `:16-22` | ✅ Fixed wording; owner asked in the ready marker |
| A15 | Prompt-size bytes are the block's shrink, not the files' size | MA | pass 2 | `results.md:42-45` | ✅ Fixed |
| A16 | csp "same bytes" vs corpus "same content" | MA | pass 2 | `results.md:46` | ✅ Fixed |
| A17 | Merge-coverage wording still unqualified next to its exceptions | MA | pass 2 | corpus report `:13`, `results.md:149-152` | ✅ Fixed |

Also fixed without a row: the csp r3 ledger row now gives both its header counts and its body counts (pass 1 r1, MA).

## 🟢 Consider

None.

## ⏭️ Skipped Core Critics

security-reviewer, performance-reviewer, api-consistency-reviewer: copy-only diff (docs and run records; `git diff --stat` shows no source files); no fact-check claim in their domains.

## 🧩 Composition check

No multi-source co-located clusters qualified.
