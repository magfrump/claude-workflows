# Code Fact-Check: Hallucination Patterns

This file records **confirmed-hallucination patterns** observed by the `code-fact-check` skill in this project. A hallucination pattern is a fabricated claim — a comment, docstring, or doc that asserts the existence of a symbol, method, API, or behavior that does not actually exist in the code, the language, or any imported library.

This log is **project-scoped**: each project keeps its own. It is **append-only** and grows over time as fact-check runs surface repeat fabrications.

## How this log is used

- **Before each fact-check run**, `code-fact-check` reads this file and treats every entry as a known suspect pattern. While checking claims in scope, the skill explicitly flags any claim that matches a logged pattern.
- **After each fact-check run**, when a claim earns an `Incorrect` verdict because a referenced symbol/API/behavior is fabricated (not merely renamed, miscounted, or stale), the skill appends a one-line entry below.

Not every `Incorrect` verdict belongs here. Stale renames, off-by-one complexity claims, and outdated configuration values are tracked in the per-run report only. Reserve this log for fabrications.

## Entry format

```
- **<short pattern>** — <one-line description of why the claim is false>. First seen: YYYY-MM-DD, report: <path/to/report.md>.
```

Keep `<short pattern>` short and normalized so future runs can grep for it (e.g., `Array.prototype.last claimed but does not exist`). Deduplicate by short pattern text — if the same fabrication appears in a new report, update the existing entry's report list rather than adding a duplicate.

## Patterns

<!-- Append entries below this line. -->

- **"shortest real review in the corpus is over 3 KB" claimed in crb-cell-status.py but the corpus minimum is 1,208 chars** — a docstring/constant comment cited a corpus statistic as the justification for `STUB_MAX_LEN = 1000` ("an order of magnitude clear of both"); recomputing over all 32 checked-in `runs/review-arms/**/result.json` gives a shortest real review of 1,208 characters, so the stated headroom (10×) is actually ~1.2×, and 15 real reviews sit under 2 KB. Same class as the entry below: a specific measured value quoted from a checked-in artifact set that does not contain it. First seen: 2026-08-19, report: docs/reviews/code-fact-check-report-r1.md.
- **`total_golden` 11 vs 13 claimed in CRB evaluations.json but no PR has more than 9 goldens** — a doc caveat cited two specific denominator values as read out of `external/code-review-benchmark/offline/results/anthropic_claude-opus-4-5-20251101/evaluations.json`; neither value occurs in that file or in `benchmark_data.json` (max goldens per PR is 9), and the real disagreement spans 24 of 50 PRs with values 1–9, not 2 PRs. First seen: 2026-08-18, report: docs/reviews/code-fact-check-report-r3.md, docs/reviews/code-fact-check-report-r2.md.
- **"All 85 tests across the code-review suites pass" claimed in commit 59ca38f and the prompt-audit F8 row, but the suites hold 97** — a commit message and the audit's application-status table both stated a specific passing-test denominator of 85; `bats --count` over the seven `test/skills/code-review-*.bats` files gives 15+10+9+17+18+17+11 = 97 (all passing), the four suites the commit modified total 53, and no subset of the seven sums to 85. The counts are identical at the pre-change commit `2d679ce`, so the figure was never true. Same class as the two entries above: a specific measured value quoted from a checked-in artifact set that does not contain it. First seen: 2026-09-12, report: docs/reviews/code-fact-check-report-r2.md.
- **`anthropic/claude-sonnet-5` claimed as a consumer of `scripts/dd-cross-model-sweep.py` but that file never references it** — `docs/working/questions.md` Q6 enumerated "the only consumers of the pin" as `cross-model-review.py` and `dd-cross-model-sweep.py`; the latter contains no `anthropic/` slug and no judge concept (its `MODELS` list is kimi/gpt/gemini), while the real second consumer, `archive/benchmark/scripts/review-arms.py:69,73`, went unnamed. A file-to-symbol association asserted without grepping the file. First seen: 2026-09-12, report: docs/reviews/code-fact-check-report-r2.md.
