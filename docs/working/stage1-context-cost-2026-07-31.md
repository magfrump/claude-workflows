# Stage-1 context enrichment — build + offline cost measurement

**Date:** 2026-07-31 · **Decision:** `docs/decisions/021-reviewer-context-management.md` (Stage 1)
**Status:** built, NOT yet tested against any model — no API inference calls were made.
The only network use was one OpenRouter `/models` pricing fetch (metadata).
**Relevant paths:** `scripts/cross-model-review.py`

## What was built

`scripts/cross-model-review.py` gained an opt-in Stage-1 context mode plus a no-spend
measurement path:

- `--context-base <ref>` — switches the prompt from diff-only to the 021 Stage-1 shape:
  1. **UNDER REVIEW** — the range diff, unchanged.
  2. **ALREADY COMMITTED - CONTEXT ONLY, NOT UNDER REVIEW** — the sibling-branch diff
     `<base>...<range-left>` (the logical changeset's earlier commits). The label is 021's
     invert-the-thesis build requirement: unlabelled sibling context makes models flag
     already-merged code as new.
  3. **CURRENT FILE CONTENTS - CONTEXT ONLY** — the full post-range (`<range-right>`)
     contents of every file the reviewed diff touches. Files over `--max-inline-kb`
     (default 64) are explicitly listed as omitted rather than silently dropped
     (function-body/AST extraction remains the designated large-file fallback, unbuilt).
  The system instructions define all three section kinds and restrict findings to the
  UNDER REVIEW diff. The assembled prompt is static text — byte-identical across models,
  plain chat-completions, no tools — so H2 (portable) and H3 (confound-control) hold.
- `--dry-run` — builds the prompt, writes it to `<out>/prompt.txt`, prints per-section
  sizes and per-model projected cost, and exits without calling any model.
- Omitting `--context-base` reproduces the pre-021 prompt **byte-identical** (verified:
  prompt SHAs of diff-only dry-runs match the template unchanged), so historical sweep
  numbers stay comparable. `context_base` is stamped into every findings.jsonl record.

## Measured prompt sizes (offline dry-runs, ~4 chars/token heuristic)

| Cell | Range (repo) | diff-only tokens | Stage-1 tokens | growth | sibling diff | enclosing files |
|---|---|---|---|---|---|---|
| MD1 | `d86d2dc..d90d6bb` (meta-formalism-copilot) | 1,037 | 2,150 | 2.1× | (empty†) | 3.6 KB |
| ND2 | `2d0ee3c~1..2d0ee3c` (nature_photographer) | 11,758 | 40,587 | 3.5× | (empty†) | 114 KB |
| ND3 | `319f229~1..319f229` (nature_photographer) | 8,088 | 18,015 | 2.2× | (empty†) | 38 KB |
| D3-shape | `0cc706b~1..0cc706b` (threadwork, base `origin/master`) | 6,637 | 31,945 | 4.8× | 55 KB | 45 KB |
| D4-shape | `689e93c~1..689e93c` (threadwork, base `origin/master`) | 6,010 | 33,844 | 5.6× | 68 KB | 42 KB |

† The sibling sections are empty as a *historical-repo artifact*, not the review-time
state: ND2/ND3's commits are already merged into their repo's mainline, and MD1's range
*starts at* a mainline commit (`d86d2dc` is an ancestor of `integration/6.1`; the range
end `d90d6bb` is not merged) — either way `base...range-left` collapses to the merge-base. The two threadwork cells reconstruct
the honest Result-5 scenario (mid-branch commit, unmerged branch over `origin/master`) and
are the representative sibling-diff sizes: **55–68 KB (~14–17k tokens)**. For a live sweep
expect the D3/D4 row shape, not the † rows.

No cell hit the `--max-inline-kb` fallback (0 files skipped everywhere).

*Post-review note (2026-07-31):* the review-fix loop added nonce-tagged section
delimiters to the Stage-1 template (anti-spoofing, security finding A11), which grows
each Stage-1 prompt by ~0.3% (e.g. D4-shape 135,376 → 135,810 chars). The table above
records the pre-nonce measurements; the cost conclusions are unaffected.

## Projected cost (live OpenRouter pricing, 2026-07-31; 1,500 output tokens assumed/call)

Per-call, worst cell (D4-shape, ~34k input tokens):

| Model | diff-only | Stage-1 |
|---|---|---|
| google/gemini-3.1-pro-preview | $0.030 | $0.086 |
| openai/gpt-5.6-sol | $0.075 | $0.214 |
| moonshotai/kimi-k3 | $0.041 | $0.124 |
| anthropic/claude-sonnet-4.5 | $0.041 | $0.124 |

Full 5-cell sweep, 4 models × 2 replicates (40 calls):
**diff-only $1.95 → Stage-1 $4.37 (~2.2×)**.

**Both 021 guardrails hold:** the priciest single call is $0.248 (Sol on ND2), under the
~$0.33 median band trigger; the full-sweep projection $4.37 is under the $10 trigger.
Judge-model matching calls (Stage-2 Jaccard) are unchanged by this build and additive as
before.

## Notes for the next sweep (not yet done — awaiting go-ahead)

- Stage-1 deliberately does **not** inline files the diff doesn't touch, so MD1's
  cross-file R1 (`exportGraph.ts`) remains invisible to it — consistent with 021: cross-file
  recall belongs to the Stage-3 agentic gate (replication of that claim is running
  separately, `docs/working/experiment-md1-r1-replication-2026-07-30.md`).
- Validation target per 021's revisit trigger: re-run D3/D4 under Stage 1 and check that
  Results 3c (heredoc-merge Critical) and 5 (sibling-commit "missing work" consensus FP)
  stop reproducing.
- `--context-base` choice matters on historical repos: pick the ref that reproduces the
  review-time branch state (here `origin/master` for threadwork), otherwise the sibling
  section silently collapses to empty († above) and the cell measures less than the
  design intends.
