# Code Fact-Check Report

**Commit:** 62594fb
**Repository:** /workspace/.claude/worktrees/cross-model-review-sweep
**Scope:** git diff main...HEAD (branch exp/cross-model-openrouter-sweep); replicate r2 of 3
**Checked:** 2026-07-31
**Total claims checked:** 28
**Summary:** 17 verified, 8 mostly accurate, 1 stale, 1 incorrect, 1 unverifiable

Hallucination pattern log read first (`docs/reviews/hallucination-patterns.md`): the `## Patterns` section is empty ("<!-- Append entries below this line. -->" is the last content line), so no prior suspect patterns applied. No claim in this run matched a fabricated-symbol shape; no log update required.

Artifacts under `runs/dd-cross-model-2026-07-30/` and pre-existing reports under `docs/reviews/` were treated as immutable evidence: claims *about* them were checked, claims *inside* them were not.

---

## Claim 1: "Stage 1 built 2026-07-31 … offline cost measurement in docs/working/stage1-context-cost-2026-07-31.md (worst call $0.248, sweep $4.37: both guardrails hold)"

**Location:** `docs/decisions/021-reviewer-context-management.md:10-15`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The guardrails are 021's own revisit triggers:

```
// docs/decisions/021-reviewer-context-management.md:145
if Stage-1 whole-file+branch-diff prompts push per-call cost above the ~$0.33 median band or a sweep above $10.
```

I reproduced the worst call and the sweep total from re-executed dry-runs plus prices back-derived from the cost doc's own D4 per-call table: Sol on ND2 computes to $0.248/call and the 5-cell × 4-model × 2-replicate Stage-1 sweep to $4.37 (executed in python; the per-token prices implied for the sonnet row come out to $2.98/$15.39 per Mtok, matching Anthropic's published $3/$15, which corroborates the derivation) (paraphrased — no quote available because the assertion is an executed arithmetic reconstruction, not a code snippet). $0.248 < $0.33 and $4.37 < $10, so both guardrails hold as claimed.

**Evidence:** `docs/decisions/021-reviewer-context-management.md:145`, `docs/working/stage1-context-cost-2026-07-31.md:53-68`, executed dry-runs of `scripts/cross-model-review.py`

---

## Claim 2: Row 27 — "the least stable judgment in the system (J_self on 🔴 rows 0.14–0.25)"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The cited figure exists in the source experiment doc:

```
// docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:420
| R17: severity is the least stable output *across tiers* | **Widened to within-tier.** J_self(🔴) ≈ 0.14 (opus) / 0.25 (fable) across replicates of the same tier on the same diff. Result 14a. |
```

**Evidence:** `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:399,420`

---

## Claim 3: Row 27 — "all four families in the 2026-07-30 DD sweep (runs/dd-cross-model-2026-07-30/) independently ranked this action first"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Checked against all four arm artifacts, not just the README. Each arm's recommendation banner names the k≥3 fact-check action:

```
// runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.md:135
`▶ recommend [1] k=3 incumbent fact-check · confidence 95%`
```

```
// runs/dd-cross-model-2026-07-30/openai_gpt-5.6-sol.md:283
▶ recommend [2] Fact-check replication · confidence 78% · runner-up [4], ...
```

Fable's banner reads `▶ recommend [2] k≥3 fact-check · confidence 78% · runner-up [5]` and Kimi's reads `▶ recommend [3] k≥3 fact-check, most-severe-wins · confidence 75% · runner-up [2]` (`runs/dd-cross-model-2026-07-30/local_claude-fable-5.md:207`, `moonshotai_kimi-k3.md:171`).

**Evidence:** `runs/dd-cross-model-2026-07-30/google_gemini-3.1-pro-preview.md:135`, `openai_gpt-5.6-sol.md:283`, `local_claude-fable-5.md:207`, `moonshotai_kimi-k3.md:171`

---

## Claim 4: Row 29 — "original-config orchestrators wrote 4.5–5.1KB briefs with claims-needing-checking lists"

**Location:** `docs/decisions/log.md:50`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

I extracted the fact-check dispatch prompts from the three original-config cells' transcript jsonl files (`Agent`/`Task` tool_use inputs whose description names fact-check): md1-opus-r1 = 4,524 bytes, md1-opus-oc-r2 = 5,067 bytes, md1-opus-oc-r3 = **3,653 bytes** (paraphrased — no quote available because the values are lengths of prompts extracted programmatically from transcript jsonl, not file text). The 4.5–5.1KB range covers r1 and oc-r2 but not oc-r3, which at 3.7KB falls below the stated lower bound. All three briefs do contain a targeted connect-src verify directive, so the mechanism claim stands; the precise statement would be "3.7–5.1KB". Same range appears in the replication doc (see Claim 14).

**Evidence:** `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-{r1,oc-r2,oc-r3}-repo/*.jsonl`, `docs/decisions/log.md:50`

---

## Claim 5: Row 29 — "all three k=3 orchestrators wrote 2.3–3.0KB generic prompts"; "0/9 current-config fact-check replicates examined exportGraph.ts vs 3/3 original-config runs (Fisher one-sided p≈0.0045)"

**Location:** `docs/decisions/log.md:50`
**Type:** Reference / Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Extracted cc fact-check replicate prompts measure 2,328 (cc-r3), 2,691 (cc-r2), and 3,010 (cc-r4) bytes — inside 2.3–3.0KB (paraphrased — no quote available because the values are programmatically extracted prompt lengths from transcript jsonl). Grepping `exportGraph` across all nine cc per-replicate reports (`md1-opus-cc-r{2,3,4}/repo/docs/reviews/code-fact-check-report-r{1,2,3}.md`) returns zero hits; the same grep hits the single fact-check report in all three oc cells (r1, oc-r2, oc-r3) (paraphrased — no quote available because the claim covers absence of grep matches across 9 files and presence across 3). Recomputing Fisher one-sided for 0/9 vs 3/3 gives C(3,3)·C(9,0)/C(12,3) = 0.004545 ≈ 0.0045 (executed).

**Evidence:** `/home/node/cr-eval/runs/md1-opus-cc-r{2,3,4}/repo/docs/reviews/`, `/home/node/cr-eval/runs/md1-opus-{r1,oc-r2,oc-r3}/repo/docs/reviews/code-fact-check-report.md`

---

## Claim 6: Row 29 — "the orchestrator wrote the 7.8KB brief byte-identically into all three replicate prompts"

**Location:** `docs/decisions/log.md:50`
**Type:** Reference / Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The three md1-opus-fix-r1 replicate prompts are each exactly 7,834 bytes, but they are not byte-identical: SHA-256 over the three prompts yields three distinct hashes, differing in exactly 2 characters each — the replicate digit (`1`/`2`/`3`) at offsets 241 and 6801, i.e. the per-replicate output path, which is the one difference SKILL.md step 4 permits (paraphrased — no quote available because the comparison was executed programmatically over transcript-extracted prompts). The *brief* portion is identical; "wrote the brief byte-identically" is defensible under that reading, but "all three replicate prompts … byte-identical" (the replication doc's phrasing, Claim 15) is literally false by 2 characters. Precise wording: "identical except the permitted replicate-numbered output path."

**Evidence:** `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-fix-r1-repo/b6bfe03a-1f4d-4fa2-90d6-61d69c283582.jsonl`, `skills/code-review/SKILL.md:291-295`

---

## Claim 7: Open question #1 closure row (5 fresh opus cells; oc 3/3; cc 1/3 with two affirmative clears; 0/9 vs 3/3, p≈0.0045; fix validated n=1 with 7.8KB ×3 and 3/3 replicate detection; hint-advantaged caveat)

**Location:** `docs/thoughts/code-review-evaluation-state.md:217`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Every number cross-checks against the replication doc and the run artifacts: 5 fresh cells exist (`md1-opus-cc-r{2,3,4}`, `md1-opus-oc-r{2,3}`) plus the separate `md1-opus-fix-r1` validation cell; all six carry `status.txt` with `rc=0` and the exact elapsed values the doc tables state; cc recovery is 1/3 (exportGraph appears in cc-r4's stdout, cc-r2's stdout carries the "Confirmed Good" clearance); 0/9 vs 3/3 and p≈0.0045 verified in Claim 5; fix-cell prompts are 7,834 B ×3 and all three fix-cell replicate fact-check reports mention `exportGraph` (paraphrased — no quote available because the evidence is an executed enumeration across run directories and transcripts). The hint-advantaged caveat matches the replication doc's "Caveat: hint leakage runs the wrong way" section, and the SKILL.md worked example it refers to does quote this defect class. The only blemish is the inherited "byte-identical" wording (Claim 6).

**Evidence:** `/home/node/cr-eval/runs/md1-opus-*/status.txt`, `/home/node/cr-eval/runs/md1-opus-fix-r1/repo/docs/reviews/code-fact-check-report-r{1,2,3}.md`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:49-56,135-141,185-209`

---

## Claim 8: Open question #2 — "Still zero data points — accumulate ≥20 clustered claims, then apply §1.1's falsifier"

**Location:** `docs/thoughts/code-review-evaluation-state.md:218`
**Type:** Reference
**Verdict:** Stale
**Confidence:** High
**Legibility-target:** for-author

Data points now exist. This branch's own merged report carries a populated stability section over 28 clusters:

```
// docs/reviews/code-fact-check-report.md:7,122,127
**Total claims checked:** 28 merged clusters (r1: 26 claims · r2: 30 · r3: 24)
## Verdict stability
- **Disagreements:** 2 —
```

and four cr-eval k=3 cells (cc-r2, cc-r3, cc-r4, fix-r1) each contain a merged report with a `## Verdict stability` section; the replication doc itself cites "cc-r4 reports 47%" agreement (`docs/working/experiment-md1-r1-replication-2026-07-30.md:174-175`). "Instrumented" is right; "still zero data points" was true when §1.1 was edited but is no longer true at branch HEAD — the ≥20-clustered-claims threshold is already met by the on-branch run alone.

**Evidence:** `docs/reviews/code-fact-check-report.md:7,122-129`, `/home/node/cr-eval/runs/md1-opus-{cc-r2,fix-r1}/repo/docs/reviews/code-fact-check-report.md`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:174-175`

---

## Claim 9: "§5.0 Stage 1 built bullet: prompts grow 2–6× to ~18k–41k tokens; worst call $0.248, full 4-model×2 sweep $4.37"

**Location:** `docs/thoughts/code-review-evaluation-state.md:282`
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Re-executed dry-runs give growth multipliers 2.1× / 3.5× / 2.2× / 4.8× / 5.6× — "2–6×" is a fair rounding — and $0.248 / $4.37 reproduce (Claim 1). But the Stage-1 token range is 2,151–40,589, not "~18k–41k": the MD1 cell's Stage-1 prompt is ~2.2k tokens, an order of magnitude below the stated lower bound (paraphrased — no quote available because the values come from re-executed `--dry-run` output). "~18k–41k" describes only the four larger cells (ND3/D3/D4/ND2). Precise version: "to ~2k–41k tokens (18k–41k excluding the small MD1 cell)".

**Evidence:** executed `scripts/cross-model-review.py --dry-run` for all 5 cells, `docs/working/stage1-context-cost-2026-07-31.md:34-40`

---

## Claim 10: Per-cell table rc/elapsed values (r1 1269s; cc-r2 1414s; cc-r3 1200s; cc-r4 1218s; oc-r2 1134s; oc-r3 983s; fix-r1 1720s; all rc=0)

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:49-56,185-187`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Each cell's `status.txt` matches exactly, e.g.:

```
// /home/node/cr-eval/runs/md1-opus-cc-r2/status.txt
rc=0 elapsed=1414s
```

The remaining five cells read `rc=0` with `elapsed=1200s`, `1218s`, `1134s`, `983s`, and `1720s` respectively (paraphrased — no quote available because quoting six one-line files individually adds nothing; all were read in one executed loop). r1's 1269s was not re-checked (its status file predates this run set and the row is labelled "prior art").

**Evidence:** `/home/node/cr-eval/runs/md1-opus-{cc-r2,cc-r3,cc-r4,oc-r2,oc-r3,fix-r1}/status.txt`

---

## Claim 11: "Under cc, 0/9 fact-check replicates (3 runs × k=3) surfaced exportGraph.ts at all" and "the (single) fact-check agent found GT-R1 itself in 3/3 runs"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:82-92`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Executed enumeration: `grep -l exportGraph` over the nine cc per-replicate reports returns nothing; the same grep hits `code-fact-check-report.md` in all three oc cells (r1, oc-r2, oc-r3) (paraphrased — no quote available because the claim covers absence/presence of grep matches across 12 files). The Fisher p≈0.0045 recomputes exactly (Claim 5).

**Evidence:** `/home/node/cr-eval/runs/md1-opus-cc-r{2,3,4}/repo/docs/reviews/code-fact-check-report-r{1,2,3}.md`, `/home/node/cr-eval/runs/md1-opus-{r1,oc-r2,oc-r3}/repo/docs/reviews/code-fact-check-report.md`

---

## Claim 12: "oc orchestrators wrote rich fact-check briefs (4.5–5.1KB) containing a 'Claims that particularly need checking' list, including, verbatim in both oc runs: '`connect-src 'self'` is sufficient because … — verify against actual client-side fetch/network code in the app.'"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:98-102`
**Type:** Behavioral / Reference
**Verdict:** Incorrect
**Confidence:** High
**Legibility-target:** for-author

Three separate inaccuracies, established by extracting the actual dispatch prompts from the transcripts:

- The quoted directive ending "— verify against actual client-side fetch/network code in the app." appears verbatim in **one** brief only (md1-opus-r1). oc-r2's brief instead ends "— verify by searching the client-side code for any browser-originated fetch to a non-same-origin host, and confirm which third-party services are actually called."; oc-r3's ends "— verify no browser-side fetch to a third-party origin exists." (paraphrased quotes above are exact extractions from the transcript prompt text; no file:line exists because the prompts live inside jsonl transcript records). So "verbatim in both oc runs" is false under either reading of "both" (r1+oc-r2 or oc-r2+oc-r3).
- The exact header "Claims that particularly need checking" appears only in oc-r2; r1's header is "Claims that especially warrant verification"; oc-r3 has no such header.
- Brief sizes are 4,524 / 5,067 / 3,653 bytes — oc-r3 is below the stated 4.5KB floor (see Claim 4).

The underlying mechanism claim — every oc brief contains a targeted connect-src entry with a client-side-verification directive, and the cc briefs contain none — is true and is what the argument rests on. But the verbatim-quotation attribution is contradicted by the transcripts.

**Evidence:** `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-{r1,oc-r2,oc-r3}-repo/*.jsonl`

---

## Claim 13: "cc orchestrators wrote lean, generic replicate prompts (2.3–3.0KB, byte-identical across replicates, no claims list) in all three cc runs"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:103-104`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Sizes verified: 2,691 / 2,328 / 3,010 bytes, three per cell, equal within each cell (paraphrased — no quote available because values are programmatically extracted prompt lengths). "Byte-identical" is 2 characters short of true in every cell: within each cc cell the three replicate prompts differ in exactly the replicate digit (r1/r2/r3 output path), the difference the spec permits. Same imprecision as Claims 6 and 15.

**Evidence:** `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-cc-r{2,3,4}-repo/*.jsonl`

---

## Claim 14: Validation — "all three replicate prompts are 7,834 bytes (vs 2,328–3,010 in the pre-fix cc cells), byte-identical across replicates"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:191-192`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

7,834 bytes ×3 and the 2,328–3,010 comparison both verified (Claims 6, 13). "Byte-identical" is false by the 2 replicate-digit characters per prompt (executed SHA comparison; see Claim 6 for the offsets). The precise phrasing — identical except the permitted per-replicate output path — would also make the doc consistent with SKILL.md step 4's own clause.

**Evidence:** `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-fix-r1-repo/b6bfe03a-1f4d-4fa2-90d6-61d69c283582.jsonl`

---

## Claim 15: Validation — "Fact-check replicates reached exportGraph.ts: 3/3 (vs 0/9 pre-fix)" and the fix-r1 token-usage line

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:199-206`
**Type:** Behavioral / Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`grep -l exportGraph` hits all three of fix-r1's per-replicate reports (r1, r2, r3) plus the merged report (paraphrased — no quote available because the claim is about grep-match presence across four files). Summing `message.usage` over the fix-r1 transcript jsonl reproduces the doc's numbers exactly: input 67,725 · output 251,666 · cache_creation 700,335 · cache_read 4,790,483 (executed).

**Evidence:** `/home/node/cr-eval/runs/md1-opus-fix-r1/repo/docs/reviews/code-fact-check-report-r{1,2,3}.md`, `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-fix-r1-repo/b6bfe03a-1f4d-4fa2-90d6-61d69c283582.jsonl`

---

## Claim 16: Stage-1 cost doc measured table — diff-only 1,037/11,758/8,088/6,637/6,010 tokens; Stage-1 2,150/40,587/18,015/31,945/33,844; sibling diffs 55/68KB; enclosing files 3.6/114/38/45/42KB

**Location:** `docs/working/stage1-context-cost-2026-07-31.md:34-40`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Re-executed all ten dry-runs (5 diff-only + 5 Stage-1) against the external repos. Sample:

```
// executed: scripts/cross-model-review.py --repo /workspace/external/threadwork --range '689e93c~1..689e93c' --context-base origin/master --dry-run
prompt size: 135,376 chars, ~33,844 tokens (diff 23,511 chars, sibling diff 68,350, enclosing files 41,845, 0 skipped)
```

All five diff-only token counts reproduce exactly; the two threadwork Stage-1 cells reproduce exactly (31,945 / 33,844, sibling 55,002/68,350 chars = 55/68KB, enclosing 44,929/41,845 = 45/42KB); the three merged-range cells reproduce within 1–2 tokens (2,151 vs 2,150; 40,589 vs 40,587; 18,017 vs 18,015), explained by the empty-sibling placeholder embedding the `--context-base` ref name, whose length depends on the branch name used (paraphrased — no quote available because the deltas come from comparing executed dry-run output against the doc's table). Enclosing-file KB figures all match.

**Evidence:** executed dry-runs under `$TMPDIR/probe-r2/`, `docs/working/stage1-context-cost-2026-07-31.md:34-40`, `scripts/cross-model-review.py:145-147`

---

## Claim 17: "No cell hit the --max-inline-kb fallback (0 files skipped everywhere)" and the † footnote (MD1/ND2/ND3 sibling sections empty because the ranges are already merged)

**Location:** `docs/working/stage1-context-cost-2026-07-31.md:42-49`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

All five re-executed Stage-1 dry-runs print `0 skipped`, and the three merged-range cells print `sibling diff 0` while the two threadwork cells (base `origin/master`) print 55,002 and 68,350 (paraphrased — no quote available because the evidence is five executed dry-run output lines; one is quoted in Claim 16). This matches the footnote's mechanism: `base...range-left` collapses when the range is already merged into the base branch.

**Evidence:** executed dry-runs under `$TMPDIR/probe-r2/`

---

## Claim 18: Cost projection table and totals — "diff-only $1.95 → Stage-1 $4.37 (~2.2×)", "the priciest single call is $0.248 (Sol on ND2)"

**Location:** `docs/working/stage1-context-cost-2026-07-31.md:51-68`
**Type:** Configuration / Performance
**Verdict:** Verified
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

Live pricing cannot be re-fetched here (no API key), so I checked internal consistency: back-deriving per-token prices from the doc's own D4 per-call rows and applying them to all five cells' measured token counts (executed) gives sweep totals $1.96 diff-only / $4.37 Stage-1 (ratio 2.23×) and Sol-on-ND2 = $0.248 exactly (paraphrased — no quote available because this is executed arithmetic over the doc's table and the re-measured token counts). The $1.96-vs-$1.95 delta is within rounding of the 3-decimal per-call inputs. The back-derived sonnet prices ($2.98/$15.39 per Mtok ≈ published $3/$15) corroborate that the table's prices are real. Confidence Medium only because the 2026-07-31 OpenRouter price snapshot itself is not reproducible offline.

**Evidence:** `docs/working/stage1-context-cost-2026-07-31.md:53-68`, executed arithmetic reconstruction

---

## Claim 19: README corrected values stand — "runner-up [2] measurement-first" (Kimi row) and "~6× Sol's latency (and ~8.5× Gemini's)"

**Location:** `runs/dd-cross-model-2026-07-30/README.md:43,50-53`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Only the M16/M17-corrected values were re-checked (the rest of the README was verdicted in the 2026-07-30 review). Kimi's artifact banner reads:

```
// runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:171
▶ recommend [3] k≥3 fact-check, most-severe-wins · confidence 75% · runner-up [2],
```

and its candidate table names `**[2]** Measurement-first` (`moonshotai_kimi-k3.md:114`). Latency ratios from the meta.json files: 955.9/154.5 = 6.19 ≈ "~6×"; 955.9/112.2 = 8.52 ≈ "~8.5×" (executed). The cost line "$1.21 total (Kimi $0.56 · Sol $0.42 · Gemini $0.23)" also matches the meta usage.cost fields (0.5555 + 0.4173 + 0.2346 = 1.207) (paraphrased — no quote available because the values are summed from three JSON files).

**Evidence:** `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.md:114,171`, `runs/dd-cross-model-2026-07-30/*.meta.json`

---

## Claim 20: "Without --context-base the prompt is byte-identical to the pre-021 harness, so historical numbers stay comparable"

**Location:** `scripts/cross-model-review.py:24-25`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

`diff` of `git show main:scripts/cross-model-review.py` against the branch file shows `PROMPT_TEMPLATE` untouched and the diff-only construction changed only by refactoring the label into a variable:

```
// diff main..branch, scripts/cross-model-review.py
< prompt = PROMPT_TEMPLATE.format(label=f"{os.path.basename(args.repo)} {args.rev_range}", diff=diff)
> label = f"{os.path.basename(args.repo)} {args.rev_range}"
> ...
> prompt = PROMPT_TEMPLATE.format(label=label, diff=diff)
```

Same template, same label expression, same diff input → byte-identical prompt when `--context-base` is omitted. (The findings.jsonl records gain a `context_base` field, but the claim is about the prompt, which is what the prompt_sha and historical comparability key on.)

**Evidence:** executed `diff` vs `git show main:scripts/cross-model-review.py`; `scripts/cross-model-review.py:65-73,322-329`

---

## Claim 21: "Files larger than --max-inline-kb are listed but not inlined (function-body extraction is the designated fallback, not yet built)"

**Location:** `scripts/cross-model-review.py:22-24` (also `docs/working/stage1-context-cost-2026-07-31.md:20-22`)
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The size path is as claimed:

```python
# scripts/cross-model-review.py:163-171
if len(content) > max_inline_kb * 1024:
    skipped.append((path, len(content), "over --max-inline-kb"))
    continue
...
parts.append("\n=== FILES TOO LARGE TO INLINE (context unavailable; judge these "
             "from the diff alone) ===\n" + lines + "\n")
```

Two unstated qualifiers: (a) binary files are also listed-not-inlined regardless of size — `if "\x00" in content[:8192]: skipped.append((path, len(content), "binary"))` (`scripts/cross-model-review.py:160-162`) routes them into the same skipped list, under a section header that mislabels them as "TOO LARGE"; (b) the NUL guard only sees content that survived text decoding — `sh()` runs subprocess with `text=True` (`scripts/cross-model-review.py:109-111`), so a file whose bytes fail strict decoding raises an uncaught UnicodeDecodeError before the guard runs (paraphrased — no quote available because the failure path is the absence of a try/except around the decode, established by reading `sh()` and its caller). No re-run cell hit either path (0 skipped everywhere), so this is a precision gap, not an observed error. Grepping "function-body" and "AST" confirms no extraction code exists — "not yet built" holds (paraphrased — no quote available because the claim covers absence of code).

**Evidence:** `scripts/cross-model-review.py:109-111,154-172`

---

## Claim 22: build_stage1_context docstring — "Returns (context_text, stats) where stats maps section -> char count for the dry-run report"

**Location:** `scripts/cross-model-review.py:122-133`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

Two of the three stats keys are char counts; the third is a file count:

```python
# scripts/cross-model-review.py:173-174
stats["enclosing_files"] = inlined
stats["skipped_files"] = len(skipped)
```

`sibling_diff` and `enclosing_files` are char counts as documented; `skipped_files` is `len(skipped)` — a count of files, which the dry-run print correctly renders as "`N` skipped" (`scripts/cross-model-review.py:343-345`). The keys the dry-run print consumes (`sibling_diff`, `enclosing_files`, `skipped_files`) exactly match what the function returns, so the docstring/print contract otherwise holds.

**Evidence:** `scripts/cross-model-review.py:143-147,173-174,343-345`

---

## Claim 23: split_range docstring — "Return (left, right) of a git range like 'a..b' / 'a...b'; right defaults to HEAD"

**Location:** `scripts/cross-model-review.py:115`
**Type:** Behavioral
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

```python
# scripts/cross-model-review.py:116-119
parts = re.split(r"\.{2,3}", rev_range, maxsplit=1)
left = parts[0].strip()
right = parts[1].strip() if len(parts) > 1 and parts[1].strip() else "HEAD"
```

`\.{2,3}` with `maxsplit=1` handles both `..` and `...`. The two callers use the halves consistently with the docstring's intent: the sibling diff uses `left` (`git diff {context_base}...{left}`, `scripts/cross-model-review.py:138`) and file contents use `right` (`git show f"{right}:{path}"`, `scripts/cross-model-review.py:154`) — for an `a...b` range, `right` is `b`, which is the correct "post-range" ref for both uses. Also confirmed: `--max-inline-kb` argparse default is 64 (`scripts/cross-model-review.py:301`), matching the module docstring and the cost doc.

**Evidence:** `scripts/cross-model-review.py:114-119,138,154,301`

---

## Claim 24: dd-cross-model-sweep.py docstring — "the sweep README's results table was hand-transcribed from the *.meta.json files this script writes, and hand transcription is where both of that README's data errors came from" (per tech-debt finding C20)

**Location:** `scripts/dd-cross-model-sweep.py:6-9`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The cited tech-debt finding says exactly this:

```
// docs/reviews/tech-debt-triage-review-2026-07-30.md:441-444
the README's `Results at a glance` table is hand-transcribed
from the `.meta.json` files rather than generated from them. Stage 1's fact-check found two
errors in exactly that table (the Kimi runner-up attribution and the "~9×" latency figure),
which is the predictable failure of hand-summarizing machine output.
```

Two errors (M16, M17), both attributed to hand transcription — matches "both of that README's data errors". (Pedantically, the rubric locates M17 in a prose bullet below the table, but both figures derive from hand-transcribing the meta values, which is the docstring's actual claim.)

**Evidence:** `docs/reviews/tech-debt-triage-review-2026-07-30.md:439-446`, `docs/reviews/code-review-rubric-2026-07-30-exp-cross-model-openrouter-sweep.md:15-16`

---

## Claim 25: "This is the runner that produced runs/dd-cross-model-2026-07-30/"

**Location:** `scripts/dd-cross-model-sweep.py:4`
**Type:** Reference / Architectural
**Verdict:** Unverifiable
**Confidence:** Medium
**Legibility-target:** for-orchestrator-synthesis

The evidence is consistent but provenance cannot be established statically. Supporting: the three meta.json files' key sets are exactly `{attempt, finish_reason, latency_s, model, usage}` — the precise dict the script writes:

```python
# scripts/dd-cross-model-sweep.py:60-61
meta = {"model": model, "finish_reason": finish, "usage": usage,
        "latency_s": round(time.time() - t0, 1), "attempt": attempt}
```

and the MODELS list matches the three OpenRouter arms. Against: the script was committed after the run (per its own line 6, "Committed per tech-debt finding C20"), and C20 itself says the sweep "cannot be re-run or extended without reconstructing the harness from memory" (`docs/reviews/tech-debt-triage-review-2026-07-30.md:440-441`) — implying this file may be a reconstruction rather than the byte-exact original. Verifying would need the original script file or a shell history from the run session. The adjacent Kimi claim is fine: `"max_tokens": 48000` with the content-null comment (`scripts/dd-cross-model-sweep.py:34-36`) cross-references the matching comment at `scripts/cross-model-review.py:384-386`, and Kimi's actual completion (32,487 tokens) fits under it.

**Evidence:** `scripts/dd-cross-model-sweep.py:25,34-36,60-61`, `runs/dd-cross-model-2026-07-30/*.meta.json`, `docs/reviews/tech-debt-triage-review-2026-07-30.md:440-441`

---

## Claim 26: Gate 1h replication check parses the merged-report format the skill specifies (`**Replication:**` field, `Commit:` line, k=3/k=2 vocabulary)

**Location:** `scripts/self-improvement.sh:1481-1516`
**Type:** Behavioral / Architectural
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

The gate's parsers match what the skill instructs and what real merged reports contain. Field extraction:

```bash
# scripts/self-improvement.sh:1492-1493
CR_REPLICATION=$(sed -n 's/^\*\*Replication:\*\* *//p' "$CR_FC_REPORT" | head -1)
CR_FC_COMMIT=$(sed -n 's/^Commit: *//p' "$CR_FC_REPORT" | head -1)
```

vs the skill's spec — "`The header adds a bolded `**Replication:** k=3` field (or `**Replication:** k=2 (one replicate failed)` ...)`" (`skills/code-review/SKILL.md:371-373`) and the artifact-wide "`include a `Commit: <hash>` metadata line at the top of each file`" (`skills/code-review/SKILL.md:1207`). Exercised against a real skill-written merged report: `md1-opus-fix-r1/repo/docs/reviews/code-fact-check-report.md` carries `Commit: d90d6bb` (line 3, unbolded — matching the sed) and `**Replication:** k=3` (line 9) (paraphrased — no quote available because the report lives outside the repo; line numbers from an executed grep). Case routing: `k=3*` → silent pass; the skill's exact k=2 vocabulary `k=2 (one replicate failed)` falls to the `*)` branch and is logged as degraded — correct. The staleness prefix test `[ "${CR_COMMIT#"$CR_FC_COMMIT"}" = "$CR_COMMIT" ]` (`scripts/self-improvement.sh:1494-1495`) fires only when the report's short SHA is not a prefix of the full reviewed SHA, and is guarded by `-n` checks so a missing Commit line degrades to no-stale-check rather than a false stale.

**Evidence:** `scripts/self-improvement.sh:1487-1516`, `skills/code-review/SKILL.md:291-292,371-373,1207`, `/home/node/cr-eval/runs/md1-opus-fix-r1/repo/docs/reviews/code-fact-check-report.md`

---

## Claim 27: Step 3b — "0/9 replicates reached the cross-file evidence a single richly-briefed run had found 3/3 times"

**Location:** `skills/code-review/SKILL.md:288-289`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High
**Legibility-target:** for-author

The numbers are right (Claims 5, 11) but the shape is misstated. The 3/3 is **three separate original-config runs** (md1-opus-r1, oc-r2, oc-r3), each of whose *single* fact-check agent found the evidence once — not one richly-briefed run finding it three times. "A single richly-briefed run had found 3/3 times" reads as the latter (a run cannot find something "3/3 times" unless it contains three replicates, which the oc config does not). The replication doc states the correct shape: "the (single) fact-check agent found GT-R1 itself in 3/3 runs (r1, oc-r2, oc-r3)" (`docs/working/experiment-md1-r1-replication-2026-07-30.md:82-83`). Precise wording: "…evidence that singly-dispatched, richly-briefed runs had found 3/3 (three runs, one fact-check each)". Note the confusion risk is compounded because the *fix validation* cell did produce a genuine within-run 3/3 (three replicates), which is a different measurement.

**Evidence:** `skills/code-review/SKILL.md:288-289`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:82-92`

---

## Claim 28: bats headers — factcheck-replication.bats (Result 14a, §1.0 two blocking channels, row 27) and soundness-crosscheck.bats (Results 15/14a ND2 narrative, negative controls ND3 `sim.ts:625-628` / md1 `proxy.ts:14`)

**Location:** `test/skills/code-review-factcheck-replication.bats:3-12`, `test/skills/code-review-soundness-crosscheck.bats:3-15,120`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High
**Legibility-target:** for-orchestrator-synthesis

Cross-checked each citation: Result 14a is the ND2 replication section whose amendment records the Incorrect/Mostly-Accurate verdict flip and the within-tier J_self (`docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:227,419-420`); Result 15 is "ND2's A1 is missed by all three tiers, and the mechanism is legible" with the 14a sharpening that opus reconstructed the mechanism at r2 (`…:173,185,376-377`) — matching the soundness header's "reached the ground-truth defect … still filed it 🟢 (Results 15/14a)". The negative controls named at `code-review-soundness-crosscheck.bats:120` match decision 028's falsifier: "replays over ND3's fixed `sim.ts:625-628` docstring and md1's `proxy.ts:14` carve-out" (`docs/decisions/028-escalation-second-channel.md:86`). The §1.0 "two verdict-driven blocking channels (fact-check Incorrect or api-consistency Breaking)" phrasing matches the state doc's §1.1 text as edited on this branch (paraphrased — no quote available because the wording spans the state-doc diff hunk quoted in this run's working notes rather than a single line).

**Evidence:** `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:173,185,227,376-377,419-420`, `docs/decisions/028-escalation-second-channel.md:86,172`, `docs/thoughts/code-review-evaluation-state.md:53-56`

---

## Claims Requiring Attention

### Incorrect
- **Claim 12** (`docs/working/experiment-md1-r1-replication-2026-07-30.md:98-102`): the "verbatim in both oc runs" connect-src directive appears verbatim in only one brief (md1-opus-r1); oc-r2/oc-r3 carry paraphrases, the exact "particularly need checking" header exists only in oc-r2, and oc-r3's brief is 3,653 B (below the stated 4.5KB floor). The mechanism claim survives; the quotation attribution does not.

### Stale
- **Claim 8** (`docs/thoughts/code-review-evaluation-state.md:218`): "Still zero data points" for the verdict-agreement rate — this branch's own merged report (28 clusters, 2 disagreements) and four cr-eval k=3 cells already report `## Verdict stability` data; the ≥20-claim threshold is met.

### Mostly Accurate
- **Claim 4** (`docs/decisions/log.md:50`): "4.5–5.1KB" oc brief range excludes oc-r3's 3,653 B; precise range is 3.7–5.1KB.
- **Claim 6** (`docs/decisions/log.md:50`): "byte-identically" — the three fix-r1 prompts differ in 2 chars each (the permitted replicate-numbered output path).
- **Claim 9** (`docs/thoughts/code-review-evaluation-state.md:282`): "~18k–41k tokens" — MD1's Stage-1 prompt is ~2.2k tokens; the true span is ~2k–41k.
- **Claim 13** (`docs/working/experiment-md1-r1-replication-2026-07-30.md:103-104`): cc prompts "byte-identical" — same 2-char output-path difference.
- **Claim 14** (`docs/working/experiment-md1-r1-replication-2026-07-30.md:191-192`): same "byte-identical" imprecision on the 7,834-byte prompts.
- **Claim 21** (`scripts/cross-model-review.py:22-24`): binary files are also listed-not-inlined (under a header that calls them "too large"), and undecodable bytes crash in `sh()` before the NUL guard.
- **Claim 22** (`scripts/cross-model-review.py:122-133`): `stats["skipped_files"]` is a file count, not a char count.
- **Claim 27** (`skills/code-review/SKILL.md:288-289`): "a single richly-briefed run had found 3/3 times" misstates the shape — three separate single-fact-check oc runs each found it once.

### Unverifiable
- **Claim 25** (`scripts/dd-cross-model-sweep.py:4`): "the runner that produced" the sweep dir — meta.json key sets match the script exactly, but the file was committed post-hoc and C20 describes the harness as reconstructed from memory; would need the original script file or run-session shell history.

## Goal-Alignment Note
- Answered: yes — all 10 briefed claim groups checked, including re-executed dry-runs, transcript extraction, artifact greps, and recomputed statistics.
- Out of scope: contents of immutable artifacts under `runs/` and pre-existing `docs/reviews/` reports (checked only claims about them); live OpenRouter pricing snapshot (offline — internal-consistency check substituted, Claim 18).
- Escalate: the "byte-identical" phrasing recurs in four places (Claims 6/13/14 plus SKILL.md's own step-4 clause resolves it correctly) — a single wording fix ("identical except the permitted replicate output path") clears three Mostly-accurate verdicts; and Claim 12's misquotation sits inside the evidence base for decision row 29, so the author should fix it before the doc is cited again.
- Questions I would have asked: whether "both oc runs" in Claim 12 was intended to mean r1+oc-r2 (it fails either way, but the fix wording differs).
