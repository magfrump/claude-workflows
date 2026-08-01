# SWRBench adapter — wiring validated, first cost numbers (2026-07-31)

**What:** `external/SWRench` now has a `cw_review` generation baseline
(`swrbench/cw_review.py`, commits `305edc9` + `a85f416` in that repo) that runs
this repo's code-review process against SWRBench instances and emits
judge-ready `generation.jsonl`. Two backends:

- `--backend openrouter` — the headless cross-model harness
  (`scripts/cross-model-review.py`), `--context-mode {stage1,diff-only}`.
- `--backend agentic` — one headless `claude -p` run of the full
  `code-review` orchestrator skill (k=3 fact-check + critic panel, opus
  orchestrator) per instance, in a reconstructed PR worktree.

**PR reconstruction:** cached `--filter=blob:none` clone → worktree at
`base_commit` → per-commit dataset diffs applied (tolerant fallback chain;
already-applied/fuzz commits recorded per row). Astropy reconstruction rate:
18/20; failures are dataset base-drift, diverted to `generation.jsonl.errors`
so the judge never scores them.

## Measured (n=7 agentic runs, all astropy, opus orchestrator)

| Arm | Per-instance cost | Per-instance wall clock |
|---|---|---|
| agentic (full skill) | **$7.26–$30.83, mean ≈ $14.6** | 12–32 min, mean ≈ 19 min |
| openrouter stage1 (dry-run est.) | ~14k prompt tokens (max 53k) → cents | seconds |
| openrouter diff-only (dry-run est.) | ~800 prompt tokens → sub-cent | seconds |

Runs: `logs/swr_datasets_d5c5/cw-agentic-smoke/` (n=1 clean) and
`cw-agentic-test6/` (n=6 balanced, $90.00 total, 47 min at 3 threads).

**Early qualitative signal (unjudged):** on ground-truth-clean instances the
agentic review does not say "clean" — e.g. `astropy__astropy-1010` (clean)
got 🟡 CONDITIONAL PASS with 6 amber findings and "fix red items then
re-review". SWRBench's clean-PR metric will score those as FP review points
(weighted by judged severity). Whether ambers on decade-old astropy PRs are
"false" positives is exactly what the judge run will quantify.

## Blocked on

LLM-judge evaluation (`swrbench/evaluation_struct.py`) needs an
OpenAI-compatible endpoint: neither `OPENAI_API_KEY` nor `OPENROUTER_API_KEY`
is set in the session env. Once available:

```
cd external/SWRench
export OPENAI_API_BASE=https://openrouter.ai/api/v1 OPENAI_API_KEY=$OPENROUTER_API_KEY
bash scripts/run.sh eval <judge_model> cw-agentic-test6
```

Same key unblocks the openrouter arms for the cheap side of the tradeoff
matrix (same 6 instance ids for a paired comparison:
`--backend openrouter --context-mode stage1|diff-only --instance-ids <ids>`).

**Judge-model caveat:** SWRBench's published numbers use a Gemini-flash judge;
whatever judge we pin, keep it fixed across arms or point-level metrics are
not comparable.
