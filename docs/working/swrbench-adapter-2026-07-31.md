# SWRBench adapter — wiring validated, first cost numbers (2026-07-31)

> **Update (later same day):** first judged numbers + larger run below —
> see "First judged results". The "Blocked on" section is superseded:
> `OPENROUTER_API_KEY` turned out to be *defined but empty* everywhere
> (session env and `/etc/environment`), so the Gemini judge and the cheap
> openrouter arms remain key-blocked. Evaluation was unblocked instead via a
> pinned **Claude-CLI judge** (`external/SWRench/scripts/judge_claude_cli.py`,
> commit `02ee503`): stock `evaluation_struct.py` prompts/parsers/metrics,
> only `utils.run_chat` transport swapped, plus stdlib shims for the
> PyPI-blocked deps (and a fix for a real `os.getenv[...]` import-time bug
> in `swrbench/utils.py`).

## First judged results (n=7 agentic, judge=claude-sonnet-5, 2026-07-31)

`logs/swr_datasets_d5c5/cw-agentic-b30/evaluation__claude-sonnet-5.json`
(3 changed + 4 clean; the test6+smoke rows seeded into `cw-agentic-b30/`).

**Judge caveat: not comparable to SWRBench's published Gemini-judge tables,
and it's Claude judging Claude-authored reviews. Internally comparable across
our arms as long as this judge stays pinned.**

- **PR level:** the review *never* says clean — `identified_as_good` = NO on
  all 7/7 (recall 1.0 is vacuous; tn=0, all 4 clean PRs flagged). Accuracy 0.43.
- **Point level: precision 4.9%** (4 TP / 81 predicted points), recall 0.8
  (4/5 GT points), F1_point 9.3.
- **Verbosity is the mechanism:** ~11.6 findings/PR vs ~1.5/PR for SWR-Bench's
  best baseline. Clean PRs average 12 findings at mean severity 4.35, max
  severities 7–9 ("critical-sounding" FPs on ground-truth-clean PRs).
- All 5 GT change-points in this slice were E-type; F-band recall untested so
  far (n too small).

Reading: consistent with the tracker's priors — the full orchestrator is a
high-recall firehose and precision is the binding constraint. The
"CONDITIONAL PASS with 6 amber findings on a clean PR" smoke observation is
now quantified.

## Larger sample (in progress)

`cw-agentic-b30/` — balanced-30 (15 changed + 15 clean, all astropy,
deterministic superset of the 7 done). Launched 2026-07-31 ~20:21 in waves
(`--sample-balanced 16 → 22 → 30`, `--max-usd 140` per wave, 3 threads,
opus orchestrator) so a cost-cap stop still leaves a near-balanced sample.
23 new instances, expected ~$335 at the measured $14.6 mean, ~2.5–3 h.
Judge re-run over the full 30 reuses the 7 cached judgments
(`evaluation__*.tmp.jsonl` cache is id-keyed).

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
