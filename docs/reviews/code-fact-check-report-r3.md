# Code Fact-Check Report

**Commit:** 62594fb

**Repository:** /workspace/.claude/worktrees/cross-model-review-sweep
**Scope:** git diff main...HEAD (branch exp/cross-model-openrouter-sweep); replicate r3 of 3
**Checked:** 2026-07-31
**Total claims checked:** 21
**Summary:** 12 verified, 6 mostly accurate, 2 stale, 1 incorrect, 0 unverifiable

Hallucination pattern log (`docs/reviews/hallucination-patterns.md`) read before checking:
its `## Patterns` section is empty, so no claim below is compared against prior patterns.
No new fabrication-class entries qualify from this run (the one Incorrect verdict is a
mis-measurement of run artifacts, not a fabricated symbol/API), so the log is unchanged.

---

## Claim 1: 021 header — "Stage 1 built 2026-07-31 … offline cost measurement … (worst call $0.248, sweep $4.37: both guardrails hold)"

**Location:** `docs/decisions/021-reviewer-context-management.md:10-15`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High

The cited cost doc and the decision's own revisit triggers agree. The trigger text reads:

```
// docs/decisions/021-reviewer-context-management.md:145
`… if Stage-1 whole-file+branch-diff prompts push per-call cost above the ~$0.33 median band or a sweep above $10. …`
```

I recomputed the worst call and the sweep from the reproduced dry-run token counts (see Claim 15) with the implied per-Mtok prices (Gemini $2/$12, Sol $5/$30, Kimi and Sonnet $3/$15, 1,500 output tokens/call): Sol on ND2 = 40,587×$5/M + 1,500×$30/M = **$0.2477 ≈ $0.248**, full sweep (5 cells × 4 models × 2 replicates) = **$4.37**, diff-only = **$1.95** (paraphrased — no quote available because these are arithmetic re-executions, not source text; run recorded in this session's `arithmetic` step). $0.248 < $0.33 and $4.37 < $10, so "both guardrails hold" is correct.

**Evidence:** `docs/decisions/021-reviewer-context-management.md:139-145`, `docs/working/stage1-context-cost-2026-07-31.md:51-68`

---

## Claim 2: log row 27 — "J_self on 🔴 rows 0.14–0.25" and "all four families in the 2026-07-30 DD sweep independently ranked this action first"

**Location:** `docs/decisions/log.md:48`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

Both figures trace to their sources. The tiers experiment doc:

```
// docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:341-342
| opus | 1 (`WARY_MOOD_DURATION`) | 7 | **0.14** |
| fable | 1 (timer docblock) | 4 | **0.25** |
```

The sweep README:

```
// runs/dd-cross-model-2026-07-30/README.md:33-35
All four models independently converged on the **same top action: k≥3
`code-fact-check` replication with most-severe-wins (§1.1)** — unanimous
cross-family agreement on the #1 pick
```

**Evidence:** `docs/working/experiment-results-full-pipeline-tiers-2026-07-30.md:339-342`, `runs/dd-cross-model-2026-07-30/README.md:33-43`

---

## Claim 3: log row 28 — "(Path A, 85%)" and the falsifier "(lift pre-fix ND2; lift nothing on ND3's fixed `sim.ts:625-628` or md1 `proxy.ts:14`)"

**Location:** `docs/decisions/log.md:49`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

The DD working doc's decision banner:

```
// docs/working/dd-escalation-second-channel.md:310
▶ recommend [12] Contested-Soundness cross-check · confidence 85% · runner-up [2′], axis = cover both structural causes vs minimal edit
```

The falsifier's control locations match 028's validation addendum, which reports "falsifier **passes 3/3 as written** (ND2 C1 lifts 🟢→🟡 …; md1 `proxy.ts:14` 0 lifts across 7 probes …; ND3 `sim.ts:625-628` 0 lifts but **vacuous**)" (`docs/decisions/028-escalation-second-channel.md:176`).

**Evidence:** `docs/working/dd-escalation-second-channel.md:3,310`, `docs/decisions/028-escalation-second-channel.md:176`, `docs/working/validation-soundness-channel-2026-07-30.md:154-162`

---

## Claim 4: log row 29 — "original-config orchestrators wrote 4.5–5.1KB briefs with claims-needing-checking lists ('verify against actual client-side fetch/network code')"

**Location:** `docs/decisions/log.md:50` (same claim at `docs/working/experiment-md1-r1-replication-2026-07-30.md:98-102`)
**Type:** Reference / Behavioral
**Verdict:** Incorrect
**Confidence:** High

I re-measured the fact-check `Agent` dispatches directly from the three oc cells' transcript jsonl under `/home/node/.claude/projects/-home-node-cr-eval-runs-<cell>-repo/` (paraphrased — no quote available because the evidence is byte-lengths and substring tests executed over transcript JSON, recorded in this session):

- `md1-opus-r1`: 4,524 bytes; has a "Claims that particularly need checking" list; contains the quoted directive verbatim ("— verify against actual client-side fetch/network code in the app.").
- `md1-opus-oc-r2`: 5,067 bytes; has a claims list; does **not** contain the quoted directive — its analogous line reads "verify by searching the client-side code for any browser-originated fetch to a non-same-origin host".
- `md1-opus-oc-r3`: **3,653 bytes; no claims list and no such directive** — its only fact-check instruction is to invoke the skill by name.

So: the size range "4.5–5.1KB" excludes one of the three oc briefs (3.7KB); "with claims-needing-checking lists" holds for 2/3; and the replication doc's stronger phrasing "including, verbatim in both oc runs" (`docs/working/experiment-md1-r1-replication-2026-07-30.md:99-102`) is wrong under any reading of "both" — the exact directive appears in exactly one run (r1). This matters beyond wording: oc-r3 recovered GT-R1 with a lean, list-free brief, which weakens the brief-richness→detection mechanism the row and decision 29 rest on (the 0/9-vs-3/3 replicate-level contrast, Claim 12, still stands independently).

**Evidence:** `docs/decisions/log.md:50`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:96-114`; transcript dispatches under `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-{r1,oc-r2,oc-r3}-repo/`

---

## Claim 5: log row 29 — "Fisher one-sided p≈0.0045" (0/9 cc replicates vs 3/3 oc samples)

**Location:** `docs/decisions/log.md:50` (also `docs/working/experiment-md1-r1-replication-2026-07-30.md:92`, state doc line for open question #1)
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

Recomputed: hypergeometric one-sided exact for 0/9 vs 3/3 is C(3,3)·C(9,0)/C(12,3) = 1/220 ≈ **0.004545** (paraphrased — no quote available because this is an executed calculation, not source text). Matches "p≈0.0045".

**Evidence:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:91-92`

---

## Claim 6: state doc §1.1 status — "Not yet measured: the first k=3 run has not executed; the noise floor is still unquantified"

**Location:** `docs/thoughts/code-review-evaluation-state.md` (§1.1 status block added on this branch)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High

True when written (commit e9d05ea), false at HEAD: the first k=3 run has executed on this very branch and its merged report reports the noise floor:

```
// docs/reviews/code-fact-check-report.md:122-130
## Verdict stability
- **Clusters:** 28 merged (from 26 + 30 + 24 replicate claims).
…
- **Agreement rate:** 21/23 ≈ **0.91** (cluster level, first measured sample).
```

That report was committed in `7fdf28a` ("apply review-fix loop findings from first live k=3 review run"), which is on this branch before HEAD.

**Evidence:** `docs/reviews/code-fact-check-report.md:122-130`, git log `main..HEAD`

---

## Claim 7: state doc open question #2 — "Still zero data points — accumulate ≥20 clustered claims, then apply §1.1's falsifier"

**Location:** `docs/thoughts/code-review-evaluation-state.md` (open-questions table row 2, edited on this branch)
**Type:** Staleness
**Verdict:** Stale
**Confidence:** High

Same evidence as Claim 6: the branch's own merged report contains a first measured sample (28 clusters, agreement 21/23 ≈ 0.91 — already past the ≥20-cluster threshold on its own), and the external cc cells report rates too (e.g. cc-r4: "Verdict agreement was **8/17 clusters (47%)**", `/home/node/cr-eval/runs/md1-opus-cc-r4/stdout.txt:20`). "Still zero data points" was overtaken by commits earlier on this same branch.

**Evidence:** `docs/reviews/code-fact-check-report.md:122-130`, `/home/node/cr-eval/runs/md1-opus-cc-r4/stdout.txt:20`

---

## Claim 8: state doc §5.0 — Stage 1 "prompts grow 2–6× to ~18k–41k tokens; worst call $0.248, full 4-model×2 sweep $4.37"

**Location:** `docs/thoughts/code-review-evaluation-state.md` (§5.0 "Stage 1 built" bullet added on this branch)
**Type:** Configuration
**Verdict:** Mostly accurate
**Confidence:** High

The multipliers and dollar figures reproduce (growths 2.1×/3.5×/2.2×/4.8×/5.6×, so "2–6×" is fair; $0.248/$4.37 per Claim 1). But the token range "~18k–41k" excludes MD1, whose Stage-1 prompt is **2,150 tokens** (reproduced dry-run: "prompt size: 8,603 chars, ~2,150 tokens" — paraphrased from my re-executed dry-run output, no source quote because it is command output). Precise version: "~2k–41k tokens (18k–41k on the four non-trivial cells)".

**Evidence:** `docs/working/stage1-context-cost-2026-07-31.md:34-40`, reproduced dry-runs (Claim 15)

---

## Claim 9: replication doc per-cell table — rc, elapsed, and per-cell GT-R1 outcomes

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:49-71,185-187`
**Type:** Reference
**Verdict:** Verified
**Confidence:** High

All six status files match the table exactly, e.g.:

```
// /home/node/cr-eval/runs/md1-opus-fix-r1/status.txt
rc=0 elapsed=1720s
```

(cc-r2 1414s, cc-r3 1200s, cc-r4 1218s, oc-r2 1134s, oc-r3 983s — all rc=0; paraphrased — no quote available because six one-line files read more clearly as a list). Spot-checked outcome cells against run artifacts: cc-r2's ✅ row certifying "`connect-src 'self'` breaks no current client fetch" is verbatim in its rubric (`/home/node/cr-eval/runs/md1-opus-cc-r2/repo/docs/reviews/code-review-rubric.md:89`); cc-r4's recovery via architecture-review is present (`exportGraph` appears in its architecture-review.md and rubric but no fact-check report); fix-r1's rubric R2 row is 🔴 with "`Convergence: security + api-consistency + fact-check(Incorrect, high conf, 3/3)`" and `Contested-Soundness` annotation (`…/md1-opus-fix-r1/repo/docs/reviews/code-review-rubric.md:27`).

**Evidence:** `/home/node/cr-eval/runs/*/status.txt`, `/home/node/cr-eval/runs/md1-opus-cc-r2/repo/docs/reviews/code-review-rubric.md:89`, `/home/node/cr-eval/runs/md1-opus-fix-r1/repo/docs/reviews/code-review-rubric.md:27`

---

## Claim 10: replication doc — "0/9 fact-check replicates surfaced `exportGraph.ts`" (cc) and "3/3" (oc); fix-r1 "3/3 replicates"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:85-92,199`
**Type:** Reference / Architectural
**Verdict:** Verified
**Confidence:** High

Executed enumeration: `grep -l exportGraph` over every `code-fact-check-report*.md` in the cells — **zero hits** across all 9 cc replicate reports (r1–r3 in cc-r2/cc-r3/cc-r4); hits in **all 3** oc single reports (r1, oc-r2, oc-r3); hits in **all 3** fix-r1 replicate reports plus the merged one (paraphrased — no quote available because the claim covers absence/presence across 16 files; grep executed this session). fix-r1's merged Claim 7 summary confirms the substance:

```
// /home/node/cr-eval/runs/md1-opus-fix-r1/repo/docs/reviews/code-fact-check-report.md:594
- **Claim 7** (`proxy.ts:16-17`, high confidence, 3/3 replicates): `connect-src 'self'` is not sufficient — `app/lib/utils/exportGraph.ts:24` and `:37` `fetch()` a `data:` URL from the browser…
```

**Evidence:** `/home/node/cr-eval/runs/md1-opus-{cc-r2,cc-r3,cc-r4,oc-r2,oc-r3,r1,fix-r1}/repo/docs/reviews/code-fact-check-report*.md`

---

## Claim 11: replication doc validation — "all three replicate prompts are 7,834 bytes … byte-identical across replicates"

**Location:** `docs/working/experiment-md1-r1-replication-2026-07-30.md:191-193`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High

Measured from the fix-r1 transcript's `Agent` dispatches: all three fact-check replicate prompts are exactly 7,834 bytes and contain the claims list ("Enumerate every browser-side network origin…" present as quoted in the doc). But they are not literally byte-identical: the first differing byte is the output-path digit ("…-fact-check-report-r1.md" vs "-r2.md" — paraphrased from an executed byte-diff over transcript JSON; no source quote because the evidence is a computed diff). This is exactly the one difference the k=3 spec permits, so the claim is right in substance; precise version: "identical except the mandated per-replicate output path". The same nuance applies to the pre-fix cells' "byte-identical across replicates" at line 103 (2,328/2,691/3,010 bytes — matching the doc's "2.3–3.0KB" and line 191's "2,328–3,010").

**Evidence:** transcript dispatches under `/home/node/.claude/projects/-home-node-cr-eval-runs-md1-opus-fix-r1-repo/`; `docs/working/experiment-md1-r1-replication-2026-07-30.md:103,191-199`

---

## Claim 12: SKILL.md step 3b — "0/9 replicates reached the cross-file evidence a single richly-briefed run had found 3/3 times"

**Location:** `skills/code-review/SKILL.md:288-289`
**Type:** Reference
**Verdict:** Mostly accurate
**Confidence:** High

The 0/9 is verified (Claim 10). The "3/3" phrasing misstates the experiment's shape: it was **three separate original-config runs** (r1, oc-r2, oc-r3), each with a single fact-check agent that found the evidence — not "a single … run" finding it 3 times. The replication doc states it correctly: "the (single) fact-check agent found GT-R1 itself in **3/3 runs** (r1, oc-r2, oc-r3)" (`docs/working/experiment-md1-r1-replication-2026-07-30.md:82-83`). Additionally, "richly-briefed" overstates one of the three: oc-r3's brief was 3.7KB with no claims list (Claim 4) and still found it. Precise version: "0/9 replicates reached the cross-file evidence that single-fact-check runs under the original config had found in 3/3 runs".

**Evidence:** `skills/code-review/SKILL.md:279-290`, `docs/working/experiment-md1-r1-replication-2026-07-30.md:82-92`

---

## Claim 13: runs README — corrected M16/M17 values stand ("runner-up [2] measurement-first"; "~6× Sol's latency (and ~8.5× Gemini's)") and the meta-derived table

**Location:** `runs/dd-cross-model-2026-07-30/README.md:38-60`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High

Both prior-review fixes are in place and arithmetically correct against the meta.json files: Kimi 955.9s / Sol 154.5s = 6.2× ("~6×"), 955.9 / 112.2 = 8.5× ("~8.5×"); Kimi row ends "runner-up [2] measurement-first" (`README.md:43`). Table values match the meta files, e.g.:

```
// runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json
"completion_tokens": 32487, … "reasoning_tokens": 24306, … "latency_s": 955.9
```

Cost line "$1.21 total (Kimi $0.56 · Sol $0.42 · Gemini $0.23)" matches the meta `cost` fields 0.555516 + 0.41725625 + 0.234646 = 1.207 (paraphrased — no quote available because it is a three-term sum over the three meta files).

**Evidence:** `runs/dd-cross-model-2026-07-30/README.md:38-60`, `runs/dd-cross-model-2026-07-30/*.meta.json`, `docs/reviews/code-review-rubric-2026-07-30-exp-cross-model-openrouter-sweep.md:15-16`

---

## Claim 14: cross-model-review.py docstring — "Without --context-base the prompt is byte-identical to the pre-021 harness" and "--max-inline-kb" default 64

**Location:** `scripts/cross-model-review.py:24-25,301-302`
**Type:** Behavioral / Configuration
**Verdict:** Verified
**Confidence:** High

`diff <(git show main:scripts/cross-model-review.py) scripts/cross-model-review.py` shows `PROMPT_TEMPLATE` is untouched, and the diff-only branch builds the prompt identically to main (`prompt = PROMPT_TEMPLATE.format(label=label, diff=diff)` at `scripts/cross-model-review.py:329`, vs main's one-line equivalent — paraphrased for the main side, no quote available because it is the pre-image of an executed `git show` diff). The default:

```python
# scripts/cross-model-review.py:301-302
ap.add_argument("--max-inline-kb", type=int, default=64, help="Stage 1: files larger than "
                "this are listed but not inlined")
```

**Evidence:** `scripts/cross-model-review.py:65-73,301-302,322-329`; `git show main:scripts/cross-model-review.py`

---

## Claim 15: stage1-context-cost doc — all five measured table rows (diff-only tokens, Stage-1 tokens, growth, sibling/enclosing sizes) are reproducible; "0 files skipped"; dagger footnote (empty sibling sections)

**Location:** `docs/working/stage1-context-cost-2026-07-31.md:34-49`
**Type:** Configuration / Reference
**Verdict:** Verified
**Confidence:** High

Re-executed all ten dry-runs (5 cells × both modes) against `/workspace/external/{threadwork,meta-formalism-copilot,nature_photographer}`. Every number reproduces exactly, e.g. the D4 row:

```
// re-executed: scripts/cross-model-review.py --repo /workspace/external/threadwork --range '689e93c~1..689e93c' --context-base origin/master --dry-run
prompt size: 135,376 chars, ~33,844 tokens (diff 23,511 chars, sibling diff 68,350, enclosing files 41,845, 0 skipped)
```

MD1 1,037→2,150; ND2 11,758→40,587; ND3 8,088→18,015; D3 6,637→31,945 (sibling 55,002, enclosing 44,929); all with "0 skipped" (paraphrased — no quote available because five near-identical command outputs read more clearly as a list; all reproduced this session). The dagger footnote is confirmed: MD1/ND2/ND3 (run with `--context-base origin/HEAD`, the merged mainline) print `sibling diff 0` — the section collapses to empty exactly as the footnote says. KB conversions and "55–68 KB (~14–17k tokens)" check out (68,350/4 ≈ 17.1k; 55,002/4 ≈ 13.75k).

**Evidence:** `docs/working/stage1-context-cost-2026-07-31.md:34-49`, reproduced dry-run outputs against `/workspace/external/*`

---

## Claim 16: cost doc — "Projected cost … 1,500 output tokens assumed/call" table and "diff-only $1.95 → Stage-1 $4.37 (~2.2×)"

**Location:** `docs/working/stage1-context-cost-2026-07-31.md:51-68`
**Type:** Configuration
**Verdict:** Verified
**Confidence:** Medium

The per-call table is internally consistent with a single price vector (Gemini $2/$12, Sol $5/$30, Kimi = Sonnet $3/$15 per Mtok): recomputing every cell from the reproduced token counts and 1,500 output tokens gives $0.030/$0.086, $0.075/$0.214, $0.041/$0.124 (×2) — matching the table to the cent — and totals $1.95 / $4.37 (ratio 2.24 ≈ "~2.2×"), with Sol-on-ND2 the priciest single call at $0.248 (paraphrased — no quote available because the evidence is a re-executed cost computation). Confidence Medium only because the underlying live OpenRouter prices of 2026-07-31 were not independently re-fetched (no API key in this session); the internal arithmetic and the price vector's plausibility are what is verified.

**Evidence:** `docs/working/stage1-context-cost-2026-07-31.md:51-68`; arithmetic re-execution this session

---

## Claim 17: cross-model-review.py docstring — "--dry-run … prints per-section token estimates and projected per-model cost"; build_stage1_context docstring "stats maps section -> char count"

**Location:** `scripts/cross-model-review.py:26-28,124-125`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** High

Two small imprecisions. (a) The per-section figures the dry-run prints are **character counts**, not token estimates — only the whole-prompt figure is tokenized:

```python
# scripts/cross-model-review.py:341-346
print(f"prompt size: {len(prompt):,} chars, ~{int(est_in_tok):,} tokens "
      f"(diff {len(diff):,} chars"
      + (f", sibling diff {ctx_stats.get('sibling_diff', 0):,}, enclosing files "
         f"{ctx_stats.get('enclosing_files', 0):,}, "
```

(b) `build_stage1_context`'s "stats maps section -> char count" is true for `sibling_diff` and `enclosing_files` but `stats["skipped_files"] = len(skipped)` (`scripts/cross-model-review.py:174`) is a **file count**. The printed keys match what the function returns (`sibling_diff`, `enclosing_files`, `skipped_files`), so nothing is misprinted — the docstrings are just loose about units.

**Evidence:** `scripts/cross-model-review.py:122-175,339-346`

---

## Claim 18: docstring/help — "Files larger than --max-inline-kb are listed but not inlined"; the binary guard

**Location:** `scripts/cross-model-review.py:22-24,160-172`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

The size fallback works as described, but the skip list has a second, undocumented population and a limited guard:

```python
# scripts/cross-model-review.py:160-164
if "\x00" in content[:8192]:
    skipped.append((path, len(content), "binary"))
    continue
if len(content) > max_inline_kb * 1024:
    skipped.append((path, len(content), "over --max-inline-kb"))
```

Binary files (NUL in the first 8,192 chars) are also skipped — and listed under the header "=== FILES TOO LARGE TO INLINE (context unavailable…) ===" (`scripts/cross-model-review.py:171-172`) even when small, so the section title misdescribes them (the per-file "binary" reason line is accurate). Additionally, `sh()` runs `git show` with `text=True` (`scripts/cross-model-review.py:111`), so a file whose bytes do not decode in the locale encoding raises `UnicodeDecodeError` before the guard runs — the guard only catches NUL-bearing content that happened to decode. Medium confidence on that last point because it depends on the runtime locale (not exercised by any cell so far: all measured cells report 0 skipped).

**Evidence:** `scripts/cross-model-review.py:109-111,152-172`

---

## Claim 19: split_range docstring and its Stage-1 callers — "Return (left, right) of a git range like 'a..b' / 'a...b'"; `--context-base` help "sibling-branch diff from this ref to the range start"

**Location:** `scripts/cross-model-review.py:115,298-300`
**Type:** Behavioral
**Verdict:** Mostly accurate
**Confidence:** Medium

`split_range` itself does what it says:

```python
# scripts/cross-model-review.py:116-119
parts = re.split(r"\.{2,3}", rev_range, maxsplit=1)
left = parts[0].strip()
right = parts[1].strip() if len(parts) > 1 and parts[1].strip() else "HEAD"
```

The imprecision is in how `build_stage1_context` consumes `left` for a **three-dot** range: `git diff a...b` reviews `merge-base(a,b)..b`, so the "range start" is the merge-base, not `a` — yet the sibling section is built as `context_base...left` (`scripts/cross-model-review.py:138`), i.e. up to `a` itself. For `a...b` with `a` ahead of the merge-base, commits between the merge-base and `a` would appear in the sibling ("already committed") section while being absent from the reviewed diff's baseline — a gap/overlap the help text's "range start" wording papers over. All documented usages (`abc~1..abc` style, and every measured cell) are two-dot, where left *is* the range start, so this is an edge-case qualifier, not an active defect.

**Evidence:** `scripts/cross-model-review.py:114-150,298-300`

---

## Claim 20: dd-cross-model-sweep.py docstring — provenance ("Committed per tech-debt finding C20 … hand transcription is where both of that README's data errors came from"; Fable arm ran as a subagent, no script) and the Kimi max_tokens comment

**Location:** `scripts/dd-cross-model-sweep.py:2-17,34-36`
**Type:** Reference / Configuration
**Verdict:** Verified
**Confidence:** High

C20 exists and says exactly this:

```
// docs/reviews/code-review-rubric-2026-07-30-exp-cross-model-openrouter-sweep.md:62
| C20 | DD-sweep harness not committed (`run_dd_sweep.py` lived in job tmp); README table hand-transcribed — which is where R2/R3 arose | … | ✅ Fixed (`scripts/dd-cross-model-sweep.py`, …) |
```

R2/R3 are the README's two data errors (rows 15-16 of the same rubric), matching "both". The Fable-arm claim matches the README ("The local Fable arm ran inside Claude Code as a subagent", `runs/dd-cross-model-2026-07-30/README.md:23`) and the artifact layout: `local_claude-fable-5.md` exists with no `.meta.json`, while all three OpenRouter arms have one. The Kimi comment ("kimi-k3 spends budget inside the reasoning trace and returns content:null if max_tokens is too low … be generous") is backed by `"max_tokens": 48000` (`scripts/dd-cross-model-sweep.py:36`) and by Kimi's meta showing 24,306 of 32,487 completion tokens spent on reasoning — a budget a low cap would exhaust.

**Evidence:** `scripts/dd-cross-model-sweep.py:2-17,30-37`, `docs/reviews/code-review-rubric-2026-07-30-exp-cross-model-openrouter-sweep.md:15-16,62`, `runs/dd-cross-model-2026-07-30/moonshotai_kimi-k3.meta.json`

---

## Claim 21: self-improvement.sh Gate 1h advisory check — "Stage 1 … stamps the merged report with a `**Replication:**` header field plus a `Commit:` line"; parsing matches the SKILL.md format

**Location:** `scripts/self-improvement.sh` (advisory replication block added on this branch, diff hunk at ~:1481-1515)
**Type:** Behavioral / Architectural
**Verdict:** Mostly accurate
**Confidence:** High

The `**Replication:**` half is exactly right. The skill mandates the bolded field in the merged header:

```
// skills/code-review/SKILL.md:371-373
- The header adds a bolded `**Replication:** k=3` field (or `**Replication:** k=2 (one
  replicate failed)` on the degraded path) so consumers read k from a named field, not
  from prose.
```

and the gate's `sed -n 's/^\*\*Replication:\*\* *//p'` matches it; the `case` arms (`k=3*` pass; anything else "degraded") align with the skill's k=3 / `k=2 (one replicate failed)` vocabulary, and the prefix test `[ "${CR_COMMIT#"$CR_FC_COMMIT"}" = "$CR_COMMIT" ]` correctly detects "short SHA is not a prefix of reviewed commit". The `Commit:` half over-states the spec: SKILL.md requires a `Commit: <short SHA>` line only on the **per-replicate** reports (`skills/code-review/SKILL.md:291-292` — "save its report as `docs/reviews/code-fact-check-report-r<N>.md` … with a `Commit: <current HEAD short SHA>` line at the top"); the merged-report format (lines 357-373) mandates the five standard header fields plus `**Replication:**` but no `Commit:` line. Observed merged reports do carry an unbolted `Commit:` line (`docs/reviews/code-fact-check-report.md:3` — "Commit: e9d05ea"; same in the fix-r1 cell), so the sed works in practice — but the stale-report detection rests on convention, not on anything the skill instructs, and a run that omits it silently skips that check (the gate degrades gracefully to the field-absent path).

**Evidence:** `scripts/self-improvement.sh` (branch diff), `skills/code-review/SKILL.md:291-303,357-373`, `docs/reviews/code-fact-check-report.md:1-10`

---

## Claims Requiring Attention

### Incorrect
- **Claim 4** (`docs/decisions/log.md:50`; `docs/working/experiment-md1-r1-replication-2026-07-30.md:98-102`): "oc orchestrators wrote 4.5–5.1KB briefs with claims lists, including verbatim in both oc runs" — measured: 4,524 / 5,067 / **3,653** bytes; the claims list exists in 2/3; the quoted directive appears verbatim in exactly **one** run (r1). oc-r3 recovered GT-R1 with a lean, list-free brief, which weakens the stated brief-richness mechanism (the 0/9-vs-3/3 replicate-level result is unaffected).

### Stale
- **Claim 6** (`docs/thoughts/code-review-evaluation-state.md` §1.1): "the first k=3 run has not executed" — it has, on this branch; its merged report measures the noise floor (21/23 ≈ 0.91).
- **Claim 7** (`docs/thoughts/code-review-evaluation-state.md` open question #2): "Still zero data points" — the branch's own merged report contributes a 28-cluster sample, and four external k=3 cells report agreement rates (e.g. 47%).

### Mostly Accurate
- **Claim 8** (`docs/thoughts/code-review-evaluation-state.md` §5.0): "~18k–41k tokens" excludes MD1's 2,150-token Stage-1 prompt; say "~2k–41k".
- **Claim 11** (`docs/working/experiment-md1-r1-replication-2026-07-30.md:191`): "byte-identical" replicate prompts differ in the mandated output-path digit; say "identical except the per-replicate output path".
- **Claim 12** (`skills/code-review/SKILL.md:288-289`): "a single richly-briefed run had found 3/3 times" — it was three separate single-fact-check runs, one find each; and one of the three was not richly briefed.
- **Claim 17** (`scripts/cross-model-review.py:26-28,124-125`): dry-run "per-section token estimates" are char counts; `skipped_files` is a file count, not a char count.
- **Claim 18** (`scripts/cross-model-review.py:22-24,160-172`): binary files are also skipped and listed under the "TOO LARGE TO INLINE" header; undecodable binaries would raise before the NUL guard.
- **Claim 19** (`scripts/cross-model-review.py:115,298-300`): for three-dot ranges the sibling section's `left` boundary is not the reviewed diff's baseline (merge-base); all current usage is two-dot.
- **Claim 21** (`scripts/self-improvement.sh` Gate 1h): the merged-report `Commit:` line the comment relies on is observed practice, not something `skills/code-review/SKILL.md` specifies for the merged report.

### Unverifiable
- (none — the one candidate, the cost doc's live-pricing provenance, was resolved as internally consistent and downgraded to a confidence note on Claim 16.)

## Goal-Alignment Note
- Answered: yes — all ten briefed claim areas checked; dry-runs re-executed, transcripts re-measured, arithmetic recomputed.
- Out of scope: claims *inside* the immutable `runs/` and pre-existing `docs/reviews/` artifacts (checked only claims about them, per brief); the 2026-07-31 live OpenRouter price vector (not re-fetchable without a key — internal consistency verified instead).
- Escalate: Claim 4 — the oc-brief mis-measurement propagates through the replication doc, log row 29, and (softened) SKILL.md step 3b; the oc-r3 counterexample (lean brief, still recovered) deserves a note in the mechanism story before row 29 is cited again. Claims 6/7 — the state doc contradicts its own branch's artifacts and should be refreshed in the same PR.
- Questions I would have asked: none — scope was unambiguous.
